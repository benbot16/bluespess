/obj/item/airlock_electronics
	name = "airlock electronics"
	icon = 'icons/obj/module.dmi'
	icon_state = "door_electronics"
	w_class = WEIGHT_CLASS_TINY

	matter = list(DEFAULT_WALL_MATERIAL = 50, MATERIAL_GLASS = 50)

	req_access = list(ACCESS_ENGINE)

	/// If set, then wires will be randomized and bolts will drop if the door is broken
	var/secure = FALSE
	/// A list of accesses for the airlock
	var/list/conf_access
	// If set to TRUE, door would receive req_one_access instead of req_access
	var/one_access = FALSE
	/// Who last configured us?
	var/last_configurator
	/// Controls whether the circuit's access can be modified
	var/locked = TRUE
	/// no double-spending
	var/is_installed = FALSE
	/// If set, an airlock can be accessed without ID from a given direction
	var/unres_dir = null
	/// Determines an airlock's control tag
	var/airlock_tag = null
	/// Determines an airlock's control frequency
	var/airlock_frequency = null

/obj/item/airlock_electronics/mechanics_hints(mob/user, distance, is_adjacent)
	. += ..()
	. += "Access control can be configured by using your ID on the circuitboard to unlock it, then using the circuitboard on yourself."
	. += "Airlock tags can be configured by using a multitool on the circuitboard and inputting an appropriate tag."
	. += "You can copy the settings from one circuitboard to another by clicking the source board with the target board. Be mindful of directional access settings!"

/obj/item/airlock_electronics/attack_self(mob/user)
	if(!ishuman(user) && !istype(user,/mob/living/silicon/robot))
		return ..(user)

	var/t1 = "<B>Access Control</B><br>\n"

	if(last_configurator)
		t1 += "Operator: [last_configurator]<br>"

	if(locked)
		t1 += "<a href='byond://?src=[REF(src)];login=1'>Swipe ID</a><hr>"
	else
		t1 += "<a href='byond://?src=[REF(src)];logout=1'>Block</a><hr>"

		t1 += "<B>Unrestricted Access Settings</B><br>"


		for(var/direction in GLOB.cardinals)
			if(direction & unres_dir)
				t1 += "<a style='color:#00dd12' href='byond://?src=[REF(src)];unres_dir=[direction]'>[capitalize(dir2text(direction))]</a><br>"
			else
				t1 += "<a href='byond://?src=[REF(src)];unres_dir=[direction]'>[capitalize(dir2text(direction))]</a><br>"

		t1 += "<hr>"

		t1 += "<a href='byond://?src=[REF(src)];frequency=1'>Set Frequency</a><hr>"
		t1 += "<a href='byond://?src=[REF(src)];id_tag=1'>Set Identification Tag</a><hr>"

		t1 += "<hr>"

		t1 += "Access requirement is set to "
		t1 += one_access ? "<a style='color:#00dd12' href='byond://?src=[REF(src)];one_access=1'>ONE</a><hr>" : "<a style='color:#f7066a' href='byond://?src=[REF(src)];one_access=1'>ALL</a><hr>"

		t1 += conf_access == null ? "<font color=#f7066a>All</font><br>" : "<a href='byond://?src=[REF(src)];access=all'>All</a><br>"

		t1 += "<br>"

		var/list/accesses = get_all_station_access()
		for(var/acc in accesses)
			var/aname = get_access_desc(acc)

			if(!conf_access?.len || !(acc in conf_access))
				t1 += "<a href='byond://?src=[REF(src)];access=[acc]'>[aname]</a><br>"
			else if(one_access)
				t1 += "<a style='color:#00dd12' href='byond://?src=[REF(src)];access=[acc]'>[aname]</a><br>"
			else
				t1 += "<a style='color:#f7066a' href='byond://?src=[REF(src)];access=[acc]'>[aname]</a><br>"

	var/datum/browser/electronics_win = new(user, "electronics", capitalize_first_letters(name))
	electronics_win.set_content(t1)
	electronics_win.open()

/obj/item/airlock_electronics/Topic(href, href_list)
	..()
	if(use_check_and_message(usr))
		return

	if(href_list["login"])
		if(istype(usr, /mob/living/silicon))
			locked = FALSE
			last_configurator = usr.name
		else
			var/obj/item/card/id/I = usr.GetIdCard()
			if(istype(I) && src.check_access(I))
				locked = FALSE
				last_configurator = I.registered_name

	if(locked)
		return

	if(href_list["unres_dir"])
		var/new_unres_dir = text2num(href_list["unres_dir"])
		unres_dir ^= new_unres_dir

	if(href_list["logout"])
		locked = TRUE

	if(href_list["one_access"])
		one_access = !one_access

	if(href_list["access"])
		toggle_access(href_list["access"])

	if(href_list["id_tag"])
		var/newtag = input(user, "Enter new device tag or leave empty to cancel.", "Airlock configuration", airlock_tag) as text
		if(!newtag)
			return
		airlock_tag = newtag

	if(href_list["frequency"])
		var/newfreq = input(user, "Enter new device frequency or leave empty to cancel.", "Airlock configuration", airlock_tag) as num
		if(!newfreq)
			return
		airlock_frequency = CLAMP(newfreq, 101, 5000)

	attack_self(usr)

/obj/item/airlock_electronics/proc/toggle_access(var/acc)
	if(acc == "all")
		conf_access = null
	else
		var/req = text2num(acc)

		if(conf_access == null)
			conf_access = list()

		if(!(req in conf_access))
			conf_access += req
		else
			conf_access -= req
			if(!conf_access.len)
				conf_access = null

/obj/item/airlock_electronics/attackby(obj/item/attacking_item, mob/user)
	if(istype(attacking_item, /obj/item/airlock_electronics) &&(!isrobot(user)))
		if(src.locked)
			to_chat(user, SPAN_WARNING("\The [src] you're trying to set is locked! Swipe your ID to unlock."))
			return TRUE
		var/obj/item/airlock_electronics/A = attacking_item
		if(A.locked)
			to_chat(user, SPAN_WARNING("\The [src] you're trying to copy is locked! Swipe your ID to unlock."))
			return TRUE
		src.conf_access = A.conf_access
		src.one_access = A.one_access
		src.last_configurator = A.last_configurator
		to_chat(user, SPAN_NOTICE("Configuration settings copied successfully."))
		return TRUE
	else if(attacking_item.GetID())
		var/obj/item/card/id/I = attacking_item.GetID()
		if(check_access(I))
			locked = !locked
			last_configurator = I.registered_name
			to_chat(user, SPAN_NOTICE("You swipe your ID over \the [src], [locked ? "locking" : "unlocking"] it."))
		else
			to_chat(user, SPAN_WARNING("Access denied."))
		return TRUE
	else
		return ..()

/obj/item/airlock_electronics/secure
	name = "secure airlock electronics"
	desc = "Designed to be somewhat more resistant to hacking than standard electronics."
	origin_tech = list(TECH_DATA = 2)
	secure = TRUE

/obj/item/airlock_electronics/secure/mechanics_hints(mob/user, distance, is_adjacent)
	. += ..()
	. += "Airlocks built with this board will have their wires uniquely randomized, and bolts will automatically drop if the airlock is broken."
