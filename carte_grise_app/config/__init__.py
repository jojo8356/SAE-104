import pymysql

# Utiliser PyMySQL comme remplacement de MySQLdb
pymysql.install_as_MySQLdb()

# Patch pour compatibilité avec Django 5.2+
pymysql.version_info = (2, 2, 4, 'final', 0)
