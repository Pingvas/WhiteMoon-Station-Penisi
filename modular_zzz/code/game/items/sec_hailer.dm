/obj/item/clothing/mask/gas/sechailer
	// Did the hailer get EMP'd?
	var/emped = FALSE
	var/obj/item/radio/hailer/radio
	COOLDOWN_DECLARE(backup_cooldown)
	actions_types = list(/datum/action/item_action/backup, /datum/action/item_action/halt, /datum/action/item_action/adjust)

// Swat Mask too
/obj/item/clothing/mask/gas/sechailer/swat
	actions_types = list(/datum/action/item_action/backup, /datum/action/item_action/halt)

/obj/item/radio/hailer
	should_be_listening = FALSE

/obj/item/radio/hailer/Initialize(mapload)
	. = ..()
	set_frequency(FREQ_SECURITY)
	set_listening(FALSE)

/datum/action/item_action/backup
	name = "BACKUP!"
	check_flags = AB_CHECK_INCAPACITATED|AB_CHECK_HANDS_BLOCKED|AB_CHECK_CONSCIOUS
	button_icon = 'modular_zubbers/icons/mob/actions/actions.dmi'
	button_icon_state = "dispatch"

/// Add the Radio
/obj/item/clothing/mask/gas/sechailer/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/empprotection, EMP_PROTECT_CONTENTS)
	radio = new(src)

/obj/item/clothing/mask/gas/sechailer/Destroy()
	QDEL_NULL(radio)
	. = ..()

/// If EMP'd, become EMP'd
/obj/item/clothing/mask/gas/sechailer/emp_act(severity)
	. = ..()
	if(!emped)
		balloon_alert_to_viewers("Backup Hailer Malfunctioning!", vision_distance = 1)
		emped = TRUE
		addtimer(CALLBACK(src, TYPE_PROC_REF(/obj/item/clothing/mask/gas/sechailer, emp_reset)), 2 MINUTES)

/// Reset EMP after 2 minutes
/obj/item/clothing/mask/gas/sechailer/proc/emp_reset()
	SIGNAL_HANDLER

	balloon_alert(src, "backup hailer recalibrated")
	emped = FALSE

/obj/item/clothing/mask/gas/sechailer/ui_action_click(mob/user, action)
	if (istype(action, /datum/action/item_action/backup))
		backup()
	else if (istype(action, /datum/action/item_action/halt))
		halt()
	else
		adjust_visor(user)

/obj/item/clothing/mask/gas/sechailer/proc/backup()
	var/turf/turf_location = get_turf(src)
	var/location = get_area_name(turf_location)

	if (!isliving(usr) || !can_use(usr))
		return
	if (!COOLDOWN_FINISHED(src, backup_cooldown))
		balloon_alert(usr, "on cooldown!")
		return
	if (emped)
		balloon_alert(usr, "backup malfunctioning!")
		return
	if (!is_station_level(turf_location.z))
		balloon_alert(usr, "out of range!")
		return

	COOLDOWN_START(src, backup_cooldown, 1 MINUTES)
	radio.talk_into(usr, "Backup Requested in [location]!", RADIO_CHANNEL_SECURITY, language = /datum/language/common)
	usr.audible_message("<font color='red' size='5'><b>BACKUP REQUESTED!</b></font>")
	balloon_alert_to_viewers("Backup Requested!", "Backup Requested!", 7)
	log_combat(usr, src, "has called for backup")
	playsound(usr, 'sound/items/whistle/whistle.ogg', 50, FALSE, 4)
