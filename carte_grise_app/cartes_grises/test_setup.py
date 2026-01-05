"""
Configuration de la base de données de test
Crée les tables nécessaires pour les tests Django
"""
from django.db import connection
from django.test import TestCase


def setup_test_database():
    """
    Exécute le script SQL pour créer les tables dans la base de test
    """
    with connection.cursor() as cursor:
        # Lire et exécuter create_tables.sql
        with open('../../create_tables.sql', 'r') as f:
            sql_content = f.read()

        # Séparer les commandes SQL (split par point-virgule)
        sql_commands = [cmd.strip() for cmd in sql_content.split(';') if cmd.strip()]

        for command in sql_commands:
            if command and not command.startswith('--'):
                try:
                    cursor.execute(command)
                except Exception as e:
                    # Ignorer les erreurs DROP TABLE si la table n'existe pas
                    if 'DROP' not in command:
                        print(f"Erreur lors de l'exécution: {command[:50]}...")
                        print(f"Erreur: {e}")


class BaseTestCase(TestCase):
    """
    Classe de base pour tous les tests
    Crée les tables au début de chaque classe de test
    """
    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        setup_test_database()
