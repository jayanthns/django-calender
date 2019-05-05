PROD_FORMATTER_SETTINGS = {
    'standard': {
        'format': "[%(asctime)s] %(levelname)s [%(name)s:%(lineno)s] %(message)s",
        'datefmt': "%d/%b/%Y %H:%M:%S"
    },
}

PROD_LOGGER_SETTINGS = {
    'django': {
        'handlers': ['console', 'info_file', 'debug_file'],
        'propagate': True,
        'level': 'INFO',
    },
    'debug': {
        'handlers': ['console', 'error_file', 'debug_file'],
        'level': 'ERROR',
        'propagate': True,
    },
    'django.db.backends': {
        'level': 'ERROR',
        'handlers': ['console', 'debug_file'],
        'propagate': False,
    },
    '': {
        'handlers': ['console', 'debug_file'],
        'level': 'DEBUG',
    },
    'gunicorn.error': {
        'level': 'ERROR',
        'handlers': ['error_file', 'debug_file'],
        'propagate': True,
    },
    'gunicorn.access': {
        'level': 'ERROR',
        'handlers': ['info_file', 'debug_file'],
        'propagate': False,
    },
}


def handler_settings(project_root, size, backup_count):
    settings = {
        'debug_file': {
            'level': 'DEBUG',
            'class': 'logging.handlers.RotatingFileHandler',
            'filename': project_root + "/log/debug.log",
            'maxBytes': int(1024 * 1024 * float(size)),  # File size in MB
            'backupCount': int(backup_count),
            'formatter': 'standard',
        },
        'info_file': {
            'level': 'INFO',
            'class': 'logging.handlers.RotatingFileHandler',
            'filename': project_root + "/log/info.log",
            'maxBytes': int(1024 * 1024 * float(size)),  # File size in MB
            'backupCount': int(backup_count),
            'formatter': 'standard',
        },
        'error_file': {
            'level': 'ERROR',
            'class': 'logging.handlers.RotatingFileHandler',
            'filename': project_root + "/log/error.log",
            'maxBytes': int(1024 * 1024 * float(size)),  # File size in MB
            'backupCount': int(backup_count),
            'formatter': 'standard',
        },
        'critical_file': {
            'level': 'CRITICAL',
            'class': 'logging.handlers.RotatingFileHandler',
            'filename': project_root + "/log/critical.log",
            'maxBytes': int(1024 * 1024 * float(size)),  # File size in MB
            'backupCount': int(backup_count),
            'formatter': 'standard',
        },
        'console': {
            'level': 'INFO',
            'class': 'logging.StreamHandler',
            'formatter': 'standard'
        },
    }
    return settings


def get_log_settings(project_root, setting='production', size=5, backup_count=2):
    log_settings = {
        'version': 1,
        'disable_existing_loggers': False,

        # How to format the output
        'formatters': PROD_FORMATTER_SETTINGS,

        # Log handlers (where to go)
        'handlers': handler_settings(project_root, size, backup_count),

        # Loggers (where does the log come from)
        'loggers':
            PROD_LOGGER_SETTINGS if setting == 'production' else PROD_LOGGER_SETTINGS
    }
    return log_settings
