#!/bin/sh

mullvad lockdown-mode set off && mullvad lockdown-mode get
mullvad disconnect && mullvad status -v

sleep 3 # delay to allow for canceling command and disconnecting from vpn

mullvad lockdown-mode set on && mullvad lockdown-mode get
mullvad connect -w
