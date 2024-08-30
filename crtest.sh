#!/bin/bash

USER=$(whoami)
USER_LOWER="${USER,,}"
USER_HOME="/home/${USER_LOWER}"
WORKDIR="${USER_HOME}"
CRON_DASHBOARD="nohup ${WORKDIR}/start1.sh >/dev/null 2>&1 &"
CRON_NEZHA="nohup ${WORKDIR}/start2.sh >/dev/null 2>&1 &"
PM2_PATH="${USER_HOME}/.npm-global/lib/node_modules/pm2/bin/pm2"
CRON_JOB="*/12 * * * * $PM2_PATH resurrect >> ${USER_HOME}/pm2_resurrect.log 2>&1"
REBOOT_COMMAND="@reboot pkill -kill -u $USER && $PM2_PATH resurrect >> ${USER_HOME}/pm2_resurrect.log 2>&1"

echo "检查并添加 crontab 任务"

# 添加 pm2 保活任务
if command -v pm2 > /dev/null 2>&1 && [[ $(which pm2) == "${USER_HOME}/.npm-global/bin/pm2" ]]; then
  echo "已安装 pm2 ，启用 pm2 保活任务"
  (crontab -l | grep -F "$REBOOT_COMMAND") || (crontab -l; echo "$REBOOT_COMMAND") | crontab -
  (crontab -l | grep -F "$CRON_JOB") || (crontab -l; echo "$CRON_JOB") | crontab -
else
  # 检查所需文件是否存在，并添加 crontab 任务
  if [ -f "${WORKDIR}/start1.sh" ] && [ -f "${WORKDIR}/start2.sh" ]; then
    echo "添加 nezha-dashbord, nezha-agent 重启任务"
    (crontab -l | grep -F "@reboot pkill -kill -u $USER && ${CRON_DASHBOARD} && ${CRON_NEZHA}") || (crontab -l; echo "@reboot pkill -kill -u $USER && ${CRON_DASHBOARD} && ${CRON_NEZHA}") | crontab -
    (crontab -l | grep -F "pgrep -x \"nezha-dashboard\" > /dev/null || ${CRON_DASHBOARD}") || (crontab -l; echo "*/12 * * * * pgrep -x \"nezha-dashboard\" > /dev/null || ${CRON_DASHBOARD}") | crontab -
	(crontab -l | grep -F "pgrep -x \"nezha-agent\" > /dev/null || ${CRON_NEZHA}") || (crontab -l; echo "*/12 * * * * pgrep -x \"nezha-agent\" > /dev/null || ${CRON_NEZHA}") | crontab -
  fi
fi

echo "crontab 任务添加完成"
