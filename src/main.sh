#!/bin/bash

# .
main () {
	#
	# Copyright (c) 2023 Sven Freiberg
	#
	# Permission is hereby granted, free of charge, to any person obtaining a
	# copy of this software and associated documentation files (the “Software”),
	# to deal in the Software without restriction, including without limitation
	# the rights to use, copy, modify, merge, publish, distribute, sublicense,
	# and/or sell copies of the Software, and to permit persons to whom the
	# Software is furnished to do so, subject to the following conditions:
	#
	# The above copyright notice and this permission notice shall be included
	# in all copies or substantial portions of the Software.
	#
	# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS
	# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
	# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
	# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
	# OTHER DEALINGS IN THE SOFTWARE.
	#
	#
	# Usage:
	#

	local version="1.6.18"
	local self="$(basename $0)"
	local cmd="${1}"

	# utility script to manage extra swap space.
	case ${cmd} in
		v|version)
			echo "${version}"
		;;

		ls|list)
			cat /proc/swaps
		;;

		s|status)
			cat /proc/meminfo | grep -i swap
		;;

		mk|make)
			shift

			local options=$(getopt \
				--options=L: --longoptions=label \
				--name=make -- $* \
			)
			eval set -- "$options"

			local swaplabel=""
			while [ 0 -lt $# ]; do
				case $1 in
					-L|--label)
						swaplabel="$2"
						shift
						;;
					
					--)
						shift
						break
						;;
				esac
				shift
			done

			local usage="USAGE: ${self} ${cmd} <options> [swap-file] [swap-size]"
			usage="${usage}\noptions:"
			usage="${usage}\n\t-L <label-name>"

			[ 2 -ne $# ] && {
				printf "%b" "${usage}"
				return 1
			}

			local swappath=$(realpath -s $1)
			# size (e.g. 7G)
			local swapsize=$2

			echo fallocate -l "$swapsize" "${swappath}"
			sudo fallocate -l "$swapsize" "${swappath}"
			[ 0 -ne $? ] && return -1

			sudo chmod 600 "${swappath}"
			[ 0 -ne $? ] && return -1

			[ 0 -lt ${#swaplabel} ] && {
				sudo mkswap -L"${swaplabel}" "${swappath}"
			} || {
				sudo mkswap "${swappath}"
			}
		;;

		rm|remove)
			local usage="USAGE: ${self} ${cmd} [swap-file]"

			[ 2 -ne $# ] && {
				printf "%b" "${usage}"
				return 1
			}

			local swappath=$(realpath -s $2)
			[ ! -e "$swappath" ] && {
				echo "No swap file found."
				return 1
			}

			echo "Deleting $swappath ..."
			sudo rm -rf "$swappath"
			[ 0 -ne $? ] && {
				return -1
			}
			echo "${swappath} deleted."
		;;

		on)
			shift

			local options=$(getopt \
				--options=L: --longoptions=label \
				--name=on -- $*)
			eval set -- "$options"

			local swaplabel=""
			while [ 0 -lt $# ]; do
				case $1 in
					-L|--label)
						swaplabel="$2"
						shift
						;;
					
					--)
						shift
						break
						;;
				esac
				shift
			done

			# print usage by https://stackoverflow.com/a/36240082
			local usage="USAGE: ${self} ${cmd} <options> [swap-file]"
			usage="${usage}\noptions:"
			usage="${usage}\n\t-L <label-name>"
			
			[ 0 -lt ${#swaplabel} ] && {
				echo "Activating ${swaplabel} ..."
				sudo swapon -L "${swaplabel}"
				[ 0 -ne $? ] && {
					return -1
				}
				echo "Swapping on '${swappath}'."
				return 0
			}

			[ 1 -ne $# ] && {
				# https://stackoverflow.com/a/36240082
				printf "%b" "$usage"
				return 1
			}

			local swappath=$(realpath -s $1)

			sudo swapon "${swappath}"
			[ 0 -ne $? ] && {
				return -1
			}
			echo "Swapping on '${swappath}'."
		;;

		off)
			local usage="USAGE: ${self} ${off} [swap-file]"			
			[ 2 -ne $# ] && {
				# https://stackoverflow.com/a/36240082
				printf "%b" "$usage"
				return 1
			}

			local swappath=$(realpath -s $2)
			echo "Moving swap memory out of ${swappath} ..."			
			sudo swapoff "${swappath}"
			[ 0 -ne $? ] && {
				return -1
			} || {
				echo "Emptied and closed '${swappath}'."
			}
		;;

		*)
			local usage="USAGE: ${self} [command]"
			usage="${usage}\ncommands (short-hand):"
			usage="${usage}\n\tversion (v)"
			usage="${usage}\n\tlist (ls)"
			usage="${usage}\n\tstatus (s)"
			usage="${usage}\n\tmake (mk)"
			usage="${usage}\n\tremove (rm)"
			usage="${usage}\n\ton"
			usage="${usage}\n\toff"

			printf "%b" "${usage}"

			return 1
		;;
	esac

	return $?
}

main $*
