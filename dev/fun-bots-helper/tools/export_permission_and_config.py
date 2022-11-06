from addons.gets import get_all_tables, get_to_root
from addons.sets import set_permission_config_files


def export_permission_and_config() -> None:
    get_to_root()
    connection, cursor = get_all_tables()
    set_permission_config_files(cursor)
    connection.close()


if __name__ == "__main__":
    export_permission_and_config()
