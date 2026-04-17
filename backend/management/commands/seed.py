from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model

User = get_user_model()

class Command(BaseCommand):
    help = 'Create superuser and sample faculty/warden/security users'

    def handle(self, *args, **options):
        from accounts.models import Department
        
        # Create standard departments
        eng_dept, _ = Department.objects.get_or_create(name='Engineering')
        mgt_dept, _ = Department.objects.get_or_create(name='Management')
        Department.objects.get_or_create(name='Arts & Humanities')
        Department.objects.get_or_create(name='Science')

        # Superuser/Admin
        if not User.objects.filter(email='admin@outing.local').exists():
            User.objects.create_superuser(
                email='admin@outing.local',
                password='AdminPass123!',
                name='System Admin',
                role='admin',
                gender='male',
            )

        # Faculty (generic — no department)
        if not User.objects.filter(email='faculty@outing.local').exists():
            User.objects.create_user(
                email='faculty@outing.local',
                password='FacultyPass123!',
                name='Alice Faculty',
                role='faculty',
                gender='female',
            )

        # Engineering Faculty
        if not User.objects.filter(email='eg1faculty@outing.local').exists():
            User.objects.create_user(
                email='eg1faculty@outing.local',
                password='FacultyPass123!',
                name='Dr. Rajesh Kumar',
                role='faculty',
                department=eng_dept,
                gender='male',
            )

        # Management Faculty
        if not User.objects.filter(email='mg1faculty@outing.local').exists():
            User.objects.create_user(
                email='mg1faculty@outing.local',
                password='FacultyPass123!',
                name='Dr. Priya Sharma',
                role='faculty',
                department=mgt_dept,
                gender='female',
            )

        # Warden
        if not User.objects.filter(email='warden@outing.local').exists():
            User.objects.create_user(
                email='warden@outing.local',
                password='WardenPass123!',
                name='Bob Warden',
                role='warden',
                gender='male',
            )

        # Security
        if not User.objects.filter(email='security@outing.local').exists():
            User.objects.create_user(
                email='security@outing.local',
                password='SecurityPass123!',
                name='Carol Security',
                role='security',
                gender='female',
            )

        # Sample Student
        if not User.objects.filter(email='student@outing.local').exists():
            User.objects.create_user(
                email='student@outing.local',
                password='StudentPass123!',
                name='Dave Student',
                role='student',
                college_id='STU001',
                room_number='A101',
                department=eng_dept,
                parent_email='parent@outing.local',
                gender='male',
            )

        self.stdout.write(self.style.SUCCESS('Seed complete.'))
