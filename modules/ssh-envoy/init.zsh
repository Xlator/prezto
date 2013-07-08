#
# Provides for an easier use of SSH by setting up ssh-agent via envoy (https://github.com/vodik/envoy)
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#   Viktor Jackson <viktor.jackson@gmail.com>
#

# Return if requirements are not found.
if [[ "$OSTYPE" == darwin* ]] || (( ! $+commands[envoy] )); then
  return 1
fi

# Load identities from config
zstyle -a ':prezto:module:ssh-envoy:load' identities '_ssh_identities'

# Check if envoyd is running
if [[ `systemctl show envoy --property=ActiveState` != "ActiveState=active" ]]; then
	
	# Start envoy, add identities
	if (( ${#_ssh_identities} > 0 )); then
		/usr/bin/envoy -t ssh-agent ${^_ssh_identities[@]}
	else
		/usr/bin/envoy -t ssh-agent 
	fi
	
	# Check envoyd status again
	if [[ `systemctl show envoy --property=ActiveState` == "ActiveState=active" ]]; then
		source <(/usr/bin/envoy -p) # get ssh env vars
		return 0
	else
		# envoyd isn't running, print an error message and return
		echo "We had trouble starting envoy. Check 'systemctl status envoy' as root."
		return 1 
	fi

else
	for _ssh_id in $_ssh_identities
	do
		# Check identities and add ones that aren't already added
		/usr/bin/envoy -l | grep "$HOME/.ssh/$_ssh_id" > /dev/null
		if [[ $? != 0 ]]; then
			echo "New identity: $_ssh_id"
			/usr/bin/envoy -a $_ssh_id
		fi
	done
	source <(/usr/bin/envoy -p) # get ssh env vars
	return 0
fi

