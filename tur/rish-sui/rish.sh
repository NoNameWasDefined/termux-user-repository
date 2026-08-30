#!/system/bin/sh

# This script takes code from https://github.com/RikkaApps/Shizuku/blob/v13.6.0/manager/src/main/assets/rish
# most part of this script was removed as it is no longer needed

export RISH_APPLICATION_ID="@TERMUX_APP_PACKAGE_NAME@"
exec /system/bin/app_process -Djava.class.path="@TERMUX_PREFIX_SHARE_DIR@/%TERMUX_PKG_NAME%.dex" /system/bin --nice-name=rish rikka.shizuku.shell.ShizukuShellLoader "${@}"
