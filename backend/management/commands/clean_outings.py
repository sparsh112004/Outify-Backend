from django.core.management.base import BaseCommand
from django.db import transaction
from outings.models import OutingRequest
from django.core.cache import cache
import logging

logger = logging.getLogger(__name__)


class Command(BaseCommand):
    help = 'Clean all outing requests from database and cache'

    def add_arguments(self, parser):
        parser.add_argument(
            '--confirm',
            action='store_true',
            help='Confirm deletion without prompting',
        )
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Show what would be deleted without actually deleting',
        )

    def handle(self, *args, **options):
        dry_run = options['dry_run']
        confirm = options['confirm']
        
        # Count total outing requests
        total_requests = OutingRequest.objects.count()
        
        if total_requests == 0:
            self.stdout.write(self.style.SUCCESS('No outing requests found in database.'))
            return
        
        self.stdout.write(f'Found {total_requests} outing requests in database.')
        
        # Show breakdown by status
        status_breakdown = {}
        for status_choice in OutingRequest.OverallStatus.choices:
            status_value = status_choice[0]
            count = OutingRequest.objects.filter(overall_status=status_value).count()
            if count > 0:
                status_breakdown[status_value] = count
        
        if status_breakdown:
            self.stdout.write('\nBreakdown by status:')
            for status, count in status_breakdown.items():
                self.stdout.write(f'  {status}: {count}')
        
        if dry_run:
            self.stdout.write(self.style.WARNING('DRY RUN: No records will be deleted.'))
            return
        
        # Confirm deletion
        if not confirm:
            response = input(f'\nAre you sure you want to delete all {total_requests} outing requests? (yes/no): ')
            if response.lower() != 'yes':
                self.stdout.write(self.style.ERROR('Operation cancelled.'))
                return
        
        try:
            with transaction.atomic():
                # Clear cache entries related to outings
                cache_keys_to_clear = [
                    'outing_stats',
                    'pending_outings_count',
                    'recent_outings',
                ]
                
                cleared_cache_keys = []
                for key in cache_keys_to_clear:
                    if cache.has_key(key):
                        cache.delete(key)
                        cleared_cache_keys.append(key)
                
                # Delete all outing requests
                deleted_count, _ = OutingRequest.objects.all().delete()
                
                self.stdout.write(self.style.SUCCESS(
                    f'Successfully deleted {deleted_count} outing requests.'
                ))
                
                if cleared_cache_keys:
                    self.stdout.write(self.style.SUCCESS(
                        f'Cleared {len(cleared_cache_keys)} cache entries: {", ".join(cleared_cache_keys)}'
                    ))
                
                # Clear any additional cache patterns
                cache_pattern_keys = [
                    'outing_request_*',
                    'student_outings_*',
                    'pending_approvals_*',
                ]
                
                cache_cleared_count = 0
                for pattern in cache_pattern_keys:
                    try:
                        # This is a simple approach - in production you might use redis keys command
                        # For now, we'll clear common patterns
                        if '*' in pattern:
                            # Skip wildcard patterns as Django cache doesn't support pattern matching directly
                            continue
                        if cache.has_key(pattern):
                            cache.delete(pattern)
                            cache_cleared_count += 1
                    except Exception as e:
                        logger.warning(f'Could not clear cache pattern {pattern}: {e}')
                
                if cache_cleared_count > 0:
                    self.stdout.write(self.style.SUCCESS(
                        f'Cleared {cache_cleared_count} additional cache entries.'
                    ))
                
        except Exception as e:
            self.stdout.write(self.style.ERROR(f'Error during cleanup: {str(e)}'))
            logger.error(f'Error during outing cleanup: {str(e)}')
            raise
        
        self.stdout.write(self.style.SUCCESS('Outing requests cleanup completed successfully!'))
