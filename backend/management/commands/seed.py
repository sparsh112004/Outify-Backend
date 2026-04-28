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
        user_eg, created = User.objects.get_or_create(
            email='eg1faculty@outing.local',
            defaults={
                'name': 'Dr. Rajesh Kumar',
                'role': 'faculty',
                'department': eng_dept,
                'gender': 'male',
            }
        )
        user_eg.set_password('eg1FacultyPass123!')
        user_eg.save()

        # Management Faculty
        user_mg, created = User.objects.get_or_create(
            email='mg1faculty@outing.local',
            defaults={
                'name': 'Dr. Priya Sharma',
                'role': 'faculty',
                'department': mgt_dept,
                'gender': 'female',
            }
        )
        user_mg.set_password('mg1FacultyPass123!')
        user_mg.save()

        # Warden
        user_w, created = User.objects.get_or_create(
            email='warden@outing.local',
            defaults={
                'name': 'Bob Warden',
                'role': 'warden',
                'gender': 'male',
            }
        )
        user_w.set_password('WardenPass123!')
        user_w.save()

        # Security
        user_s, created = User.objects.get_or_create(
            email='security@outing.local',
            defaults={
                'name': 'Carol Security',
                'role': 'security',
                'gender': 'female',
            }
        )
        user_s.set_password('SecurityPass123!')
        user_s.save()

        # Sample Student
        user_stu, created = User.objects.get_or_create(
            email='student@outing.local',
            defaults={
                'name': 'Dave Student',
                'role': 'student',
                'college_id': 'STU001',
                'room_number': 'A101',
                'department': eng_dept,
                'parent_email': 'parent@outing.local',
                'gender': 'male',
            }
        )
        user_stu.set_password('StudentPass123!')
        user_stu.save()

        self.stdout.write(self.style.SUCCESS('Seed complete.'))
