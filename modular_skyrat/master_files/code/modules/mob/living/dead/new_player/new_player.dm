#define LINKIFY_READY(string, value) "<a href='byond://?src=[REF(src)];ready=[value]'>[string]</a>"

/mob/dead/new_player
	flags_1 = NONE
	invisibility = INVISIBILITY_ABSTRACT
	density = FALSE
	stat = DEAD
	hud_possible = list()

	var/ready = FALSE
	/// Referenced when you want to delete the new_player later on in the code.
	var/spawning = FALSE
	/// For instant transfer once the round is set up
	var/mob/living/new_character
	///Used to make sure someone doesn't get spammed with messages if they're ineligible for roles.
	//Used to make sure someone doesn't get spammed with messages if they're ineligible for roles
	var/ineligible_for_roles = FALSE

	var/client/my_client

/mob/dead/new_player/Initialize()
	if(client && SSticker.state == GAME_STATE_STARTUP)
		var/atom/movable/screen/splash/S = new(client, TRUE, TRUE)
		S.Fade(TRUE)

	if(length(GLOB.newplayer_start))
		forceMove(pick(GLOB.newplayer_start))
	else
		forceMove(locate(1,1,1))

	ComponentInitialize()

	. = ..()

	GLOB.new_player_list += src

/mob/dead/new_player/Destroy()
	GLOB.new_player_list -= src
	return ..()

/mob/dead/new_player/prepare_huds()
	return

/**
 * This proc generates the panel that opens to all newly joining players, allowing them to join, observe, view polls, view the current crew manifest, and open the character customization menu.
 */
/mob/dead/new_player/proc/show_titlescreen()
	if (client?.interviewee)
		return

	winset(src, "lobbybrowser", "is-disabled=false;is-visible=true")

	var/datum/asset/assets = get_asset_datum(/datum/asset/simple/lobby) //Sending pictures to the client
	assets.send(src)

	update_titlescreen()


/mob/dead/new_player/proc/update_titlescreen()
	var/dat = get_lobby_html()

	src << browse(GLOB.current_lobby_screen, "file=titlescreen.gif;display=0")
	src << browse(dat, "window=lobbybrowser")

/datum/asset/simple/lobby
	assets = list(
		"FixedsysExcelsior3.01Regular.ttf" = 'html/browser/FixedsysExcelsior3.01Regular.ttf',
	)

/mob/dead/new_player/proc/hide_titlescreen()
	if(my_client.mob)
		winset(my_client, "lobbybrowser", "is-disabled=true;is-visible=false")

/mob/dead/new_player/proc/playerpolls()
	var/output
	if (SSdbcore.Connect())
		var/isadmin = FALSE
		if(client?.holder)
			isadmin = TRUE
		var/datum/db_query/query_get_new_polls = SSdbcore.NewQuery({"
			SELECT id FROM [format_table_name("poll_question")]
			WHERE (adminonly = 0 OR :isadmin = 1)
			AND Now() BETWEEN starttime AND endtime
			AND deleted = 0
			AND id NOT IN (
				SELECT pollid FROM [format_table_name("poll_vote")]
				WHERE ckey = :ckey
				AND deleted = 0
			)
			AND id NOT IN (
				SELECT pollid FROM [format_table_name("poll_textreply")]
				WHERE ckey = :ckey
				AND deleted = 0
			)
		"}, list("isadmin" = isadmin, "ckey" = ckey))
		if(!query_get_new_polls.Execute())
			qdel(query_get_new_polls)
			return
		if(query_get_new_polls.NextRow())
			output +={"<a class="menu_ab" href='?src=\ref[src];showpoll=1'>POLLS (NEW)</a>"}
		else
			output +={"<a class="menu_a" href='?src=\ref[src];showpoll=1'>POLLS</a>"}
		qdel(query_get_new_polls)
		if(QDELETED(src))
			return
		return output

/mob/dead/new_player/Topic(href, href_list[])
	if(src != usr || !client)
		return

	if(client.interviewee)
		return FALSE

	//Determines Relevent Population Cap
	var/relevant_cap
	var/hpc = CONFIG_GET(number/hard_popcap)
	var/epc = CONFIG_GET(number/extreme_popcap)
	if(hpc && epc)
		relevant_cap = min(hpc, epc)
	else
		relevant_cap = max(hpc, epc)

	if(href_list["lobby_setup"])
		client.prefs.needs_update = TRUE
		client.prefs.ShowChoices(src)
		return TRUE

	if(href_list["lobby_ready"])
		if(!client.prefs.check_flavor_text())
			ready = PLAYER_NOT_READY
			return

		if(SSticker.current_state <= GAME_STATE_PREGAME)
			client << output(null, "lobbybrowser:imgsrc")
			ready = !ready
		return

	if(href_list["lobby_observe"])
		ready = PLAYER_READY_TO_OBSERVE
		hide_titlescreen()
		make_me_an_observer()
		return

	if(href_list["lobby_antagtoggle"])
		client.prefs.be_antag = !client.prefs.be_antag
		update_titlescreen()
		to_chat(usr, "<span class='notice'>You will now [client.prefs.be_antag ? "be considered" : "not be considered"] for any antagonist positions set in your preferences.</span>")
		return

	if(href_list["lobby_swap"])
		if(!CONFIG_GET(flag/server_swap_enabled))
			return
		if(GLOB.swappable_ips.len == 1)
			var/server_name = GLOB.swappable_ips[1]
			var/server_ip = GLOB.swappable_ips[server_name]
			var/confirm = tgui_alert(usr, "Are you sure you want to swap to [server_name] ([server_ip])?", "Swapping server!", list("Connect me!", "Stay here!"))
			if(confirm == "Connect me!")
				to_chat_immediate(src, "So long, spaceman.")
				client << link(server_ip)
			return
		var/server_name = tgui_input_list(usr, "Please select the server you wish to swap to:", "Swap servers!", GLOB.swappable_ips)
		if(!server_name)
			return
		var/server_ip = GLOB.swappable_ips[server_name]
		var/confirm = tgui_alert(usr, "Are you sure you want to swap to [server_name] ([server_ip])?", "Swapping server!", list("Connect me!", "Stay here!"))
		if(confirm == "Connect me!")
			to_chat_immediate(src, "So long, spaceman.")
			client << link(server_ip)
		return

	if(href_list["lobby_join"])
		if(!client.prefs.check_flavor_text())
			return

		if(!SSticker?.IsRoundInProgress())
			to_chat(usr, "<span class='boldwarning'>The round is either not ready, or has already finished...</span>")
			return

		if(href_list["lobby_join"] == "override")
			LateChoices()
			return

		if(SSticker.queued_players.len || (relevant_cap && living_player_count() >= relevant_cap && !(ckey(key) in GLOB.admin_datums)))
			to_chat(usr, "<span class='danger'>[CONFIG_GET(string/hard_popcap_message)]</span>")

			var/queue_position = SSticker.queued_players.Find(usr)
			if(queue_position == 1)
				to_chat(usr, "<span class='notice'>You are next in line to join the game. You will be notified when a slot opens up.</span>")
			else if(queue_position)
				to_chat(usr, "<span class='notice'>There are [queue_position-1] players in front of you in the queue to join the game.</span>")
			else
				SSticker.queued_players += usr
				to_chat(usr, "<span class='notice'>You have been added to the queue to join the game. Your position in queue is [SSticker.queued_players.len].</span>")
			return
		LateChoices()

	if(href_list["lobby_crew"])
		ViewManifest()
		return


	if(href_list["SelectedJob"])
		if(!client.prefs.check_flavor_text())
			return

		if(!SSticker?.IsRoundInProgress())
			to_chat(usr, "<span class='danger'>The round is either not ready, or has already finished...</span>")
			return

		if(SSlag_switch.measures[DISABLE_NON_OBSJOBS])
			to_chat(usr, "<span class='notice'>There is an administrative lock on entering the game!</span>")
			return

		if(SSticker.queued_players.len && !(ckey(key) in GLOB.admin_datums))
			if((living_player_count() >= relevant_cap) || (src != SSticker.queued_players[1]))
				to_chat(usr, "<span class='warning'>Server is full.</span>")
				return

		AttemptLateSpawn(href_list["SelectedJob"])
		return

	if(href_list["showpoll"])
		handle_player_polling()
		return

	if(href_list["viewpoll"])
		var/datum/poll_question/poll = locate(href_list["viewpoll"]) in GLOB.polls
		poll_player(poll)
		return

	if(href_list["votepollref"])
		var/datum/poll_question/poll = locate(href_list["votepollref"]) in GLOB.polls
		vote_on_poll_handler(poll, href_list)
		return

//When you cop out of the round (NB: this HAS A SLEEP FOR PLAYER INPUT IN IT)
/mob/dead/new_player/proc/make_me_an_observer()
	if(QDELETED(src) || !src.client)
		ready = PLAYER_NOT_READY
		return FALSE

	var/less_input_message
	if(SSlag_switch.measures[DISABLE_DEAD_KEYLOOP])
		less_input_message = " - Notice: Observer freelook is currently disabled."
	var/this_is_like_playing_right = tgui_alert(usr, "Are you sure you wish to observe? You will not be able to play this round![less_input_message]","Player Setup",list("Yes","No"))

	if(QDELETED(src) || !src.client || this_is_like_playing_right != "Yes")
		ready = PLAYER_NOT_READY
		show_titlescreen()
		return FALSE

	var/mob/dead/observer/observer = new()
	spawning = TRUE

	observer.started_as_observer = TRUE
	close_spawn_windows()
	var/obj/effect/landmark/observer_start/O = locate(/obj/effect/landmark/observer_start) in GLOB.landmarks_list
	to_chat(src, "<span class='notice'>Now teleporting.</span>")
	if (O)
		observer.forceMove(O.loc)
	else
		to_chat(src, "<span class='notice'>Teleporting failed. Ahelp an admin please</span>")
		stack_trace("There's no freaking observer landmark available on this map or you're making observers before the map is initialised")
	observer.key = key
	observer.client = client
	observer.set_ghost_appearance()
	if(observer.client && observer.client.prefs)
		observer.real_name = observer.client.prefs.real_name
		observer.name = observer.real_name
		observer.client.init_verbs()
	observer.update_appearance()
	observer.stop_sound_channel(CHANNEL_LOBBYMUSIC)
	deadchat_broadcast(" has observed.", "<b>[observer.real_name]</b>", follow_target = observer, turf_target = get_turf(observer), message_type = DEADCHAT_DEATHRATTLE)
	QDEL_NULL(mind)
	qdel(src)
	return TRUE

/proc/get_job_unavailable_error_message(retval, jobtitle)
	switch(retval)
		if(JOB_AVAILABLE)
			return "[jobtitle] is available."
		if(JOB_UNAVAILABLE_GENERIC)
			return "[jobtitle] is unavailable."
		if(JOB_UNAVAILABLE_BANNED)
			return "You are currently banned from [jobtitle]."
		if(JOB_NOT_VETERAN)
			return "You need to be veteran to join as [jobtitle]."
		if(JOB_UNAVAILABLE_PLAYTIME)
			return "You do not have enough relevant playtime for [jobtitle]."
		if(JOB_UNAVAILABLE_ACCOUNTAGE)
			return "Your account is not old enough for [jobtitle]."
		if(JOB_UNAVAILABLE_SLOTFULL)
			return "[jobtitle] is already filled to capacity."
		if(JOB_UNAVAILABLE_QUIRK)
			return "[jobtitle] is restricted from your quirks."
		if(JOB_UNAVAILABLE_SPECIES)
			return "[jobtitle] is restricted from your species."
		if(JOB_UNAVAILABLE_LANGUAGE)
			return "You don't have the required languages for [jobtitle]."
	return "Error: Unknown job availability."

/mob/dead/new_player/proc/IsJobUnavailable(rank, latejoin = FALSE)
	var/datum/job/job = SSjob.GetJob(rank)
	if(!(job.job_flags & JOB_NEW_PLAYER_JOINABLE))
		return JOB_UNAVAILABLE_GENERIC
	if((job.current_positions >= job.total_positions) && job.total_positions != -1)
		if(is_assistant_job(job))
			if(isnum(client.player_age) && client.player_age <= 14) //Newbies can always be assistants
				return JOB_AVAILABLE
			for(var/datum/job/other_job as anything in SSjob.joinable_occupations)
				if(other_job.current_positions < other_job.total_positions && other_job != job)
					return JOB_UNAVAILABLE_SLOTFULL
		else
			return JOB_UNAVAILABLE_SLOTFULL
	if(is_banned_from(ckey, rank))
		return JOB_UNAVAILABLE_BANNED
	if(QDELETED(src))
		return JOB_UNAVAILABLE_GENERIC
	if(!job.player_old_enough(client))
		return JOB_UNAVAILABLE_ACCOUNTAGE
	if(job.required_playtime_remaining(client))
		return JOB_UNAVAILABLE_PLAYTIME
	if(job.has_banned_quirk(client.prefs))
		return JOB_UNAVAILABLE_QUIRK
	if(job.has_banned_species(client.prefs))
		return JOB_UNAVAILABLE_SPECIES
	if(latejoin && !job.special_check_latejoin(client))
		return JOB_UNAVAILABLE_GENERIC
	if(job.has_banned_quirk(client.prefs))
		return JOB_UNAVAILABLE_QUIRK
	if(job.has_banned_species(client.prefs))
		return JOB_UNAVAILABLE_SPECIES
	if(!job.has_required_languages(client.prefs))
		return JOB_UNAVAILABLE_LANGUAGE
	if(job.veteran_only && !is_veteran_player(client))
		return JOB_NOT_VETERAN
	return JOB_AVAILABLE

/mob/dead/new_player/proc/AttemptLateSpawn(rank)
	var/error = IsJobUnavailable(rank)
	if(error != JOB_AVAILABLE)
		tgui_alert(usr, get_job_unavailable_error_message(error, rank))
		return FALSE

	if(SSshuttle.arrivals)
		close_spawn_windows() //In case we get held up
		if(SSshuttle.arrivals.damaged && CONFIG_GET(flag/arrivals_shuttle_require_safe_latejoin))
			src << tgui_alert(usr,"The arrivals shuttle is currently malfunctioning! You cannot join.")
			return FALSE

		if(CONFIG_GET(flag/arrivals_shuttle_require_undocked))
			SSshuttle.arrivals.RequireUndocked(src)

	//Remove the player from the join queue if he was in one and reset the timer
	SSticker.queued_players -= src
	SSticker.queue_delay = 4

	var/datum/job/job = SSjob.GetJob(rank)

	SSjob.AssignRole(src, job, TRUE)

	mind.late_joiner = TRUE
	var/atom/destination = mind.assigned_role.get_latejoin_spawn_point()
	if(!destination)
		CRASH("Failed to find a latejoin spawn point.")
	var/mob/living/character = create_character(destination)
	if(!character)
		CRASH("Failed to create a character for latejoin.")
	transfer_character()

	SSjob.EquipRank(character, job, character.client)
	job.after_latejoin_spawn(character)

	#define IS_NOT_CAPTAIN 0
	#define IS_ACTING_CAPTAIN 1
	#define IS_FULL_CAPTAIN 2
	var/is_captain = IS_NOT_CAPTAIN
	// If we already have a captain, are they a "Captain" rank and are we allowing multiple of them to be assigned?
	if(is_captain_job(job))
		is_captain = IS_FULL_CAPTAIN
	// If we don't have an assigned cap yet, check if this person qualifies for some from of captaincy.
	else if(!SSjob.assigned_captain && ishuman(character) && SSjob.chain_of_command[rank] && !is_banned_from(ckey, list("Captain")))
		is_captain = IS_ACTING_CAPTAIN
	if(is_captain != IS_NOT_CAPTAIN)
		minor_announce(job.get_captaincy_announcement(character))
		SSjob.promote_to_captain(character, is_captain == IS_ACTING_CAPTAIN)
	#undef IS_NOT_CAPTAIN
	#undef IS_ACTING_CAPTAIN
	#undef IS_FULL_CAPTAIN

	SSticker.minds += character.mind
	character.client.init_verbs() // init verbs for the late join
	var/mob/living/carbon/human/humanc
	if(ishuman(character))
		humanc = character //Let's retypecast the var to be human,

	if(humanc) //These procs all expect humans
		GLOB.data_core.manifest_inject(humanc)
		if(SSshuttle.arrivals)
			SSshuttle.arrivals.QueueAnnounce(humanc, rank)
		else
			AnnounceArrival(humanc, rank)
		AddEmploymentContract(humanc)

		humanc.increment_scar_slot()
		humanc.load_persistent_scars()

		if(GLOB.curse_of_madness_triggered)
			give_madness(humanc, GLOB.curse_of_madness_triggered)

		SEND_GLOBAL_SIGNAL(COMSIG_GLOB_CREWMEMBER_JOINED, humanc, rank)

	GLOB.joined_player_list += character.ckey

	if(CONFIG_GET(flag/allow_latejoin_antagonists) && humanc) //Borgs aren't allowed to be antags. Will need to be tweaked if we get true latejoin ais.
		if(SSshuttle.emergency)
			switch(SSshuttle.emergency.mode)
				if(SHUTTLE_RECALL, SHUTTLE_IDLE)
					SSticker.mode.make_antag_chance(humanc)
				if(SHUTTLE_CALL)
					if(SSshuttle.emergency.timeLeft(1) > initial(SSshuttle.emergencyCallTime)*0.5)
						SSticker.mode.make_antag_chance(humanc)

	if(humanc && CONFIG_GET(flag/roundstart_traits))
		SSquirks.AssignQuirks(humanc, humanc.client)

	log_manifest(character.mind.key,character.mind,character,latejoin = TRUE)

/mob/dead/new_player/proc/AddEmploymentContract(mob/living/carbon/human/employee)
	//TODO:  figure out a way to exclude wizards/nukeops/demons from this.
	for(var/C in GLOB.employmentCabinets)
		var/obj/structure/filingcabinet/employment/employmentCabinet = C
		if(!employmentCabinet.virgin)
			employmentCabinet.addFile(employee)


/mob/dead/new_player/proc/LateChoices()
	var/list/dat = list()
	if(SSlag_switch.measures[DISABLE_NON_OBSJOBS])
		dat += "<div class='notice red' style='font-size: 125%'>Only Observers may join at this time.</div><br>"
	dat += "<div class='notice'>Round Duration: [DisplayTimeText(world.time - SSticker.round_start_time)]</div>"
	dat += "<div class='notice'>Alert Level: [capitalize(num2seclevel(SSsecurity_level.current_level))]</div>"
	if(SSshuttle.emergency)
		switch(SSshuttle.emergency.mode)
			if(SHUTTLE_ESCAPE)
				dat += "<div class='notice red'>The station has been evacuated.</div><br>"
			if(SHUTTLE_CALL)
				if(!SSshuttle.canRecall())
					dat += "<div class='notice red'>The station is currently undergoing evacuation procedures.</div><br>"
	for(var/datum/job/prioritized_job in SSjob.prioritized_jobs)
		if(prioritized_job.current_positions >= prioritized_job.total_positions)
			SSjob.prioritized_jobs -= prioritized_job
	dat += "<table><tr><td valign='top'>"
	var/column_counter = 0
	// render each category's available jobs
	for(var/category in GLOB.position_categories)
		// position_categories contains category names mapped to available jobs and an appropriate color
		var/cat_color = GLOB.position_categories[category]["color"]
		dat += "<fieldset style='width: 185px; border: 2px solid [cat_color]; display: inline'>"
		dat += "<legend align='center' style='color: [cat_color]'>[category]</legend>"
		var/list/dept_dat = list()
		for(var/job in GLOB.position_categories[category]["jobs"])
			var/datum/job/job_datum = SSjob.name_occupations[job]
			if(job_datum && IsJobUnavailable(job_datum.title, TRUE) == JOB_AVAILABLE)
				var/command_bold = ""
				if(job in GLOB.command_positions)
					command_bold = " command"
				var/jobline = "[job_datum.title] ([job_datum.current_positions])"
				if(job_datum in SSjob.prioritized_jobs)
					jobline = "<span class='priority'>[jobline]</span>"
				if(client && client.prefs && client.prefs.alt_titles_preferences[job_datum.title])
					jobline = "[jobline]<br><span style='color:#BBBBBB; font-style: italic;'>(as [client.prefs.alt_titles_preferences[job_datum.title]])</span>"

				jobline = "<a class='job[command_bold]' style='display:block;width:170px' href='byond://?src=[REF(src)];SelectedJob=[job_datum.title]'>[jobline]</a>"
				dept_dat += jobline

		if(!dept_dat.len)
			dept_dat += "<span class='nopositions'>No positions open.</span>"
		dat += jointext(dept_dat, "")
		dat += "</fieldset><br>"
		column_counter++
		if(column_counter > 0 && (column_counter % 3 == 0))
			dat += "</td><td valign='top'>"
	dat += "</td></tr></table></center>"
	dat += "</div></div>"
	var/datum/browser/popup = new(src, "latechoices", "Choose Profession", 680, 580)
	popup.add_stylesheet("playeroptions", 'html/browser/playeroptions.css')
	popup.set_content(jointext(dat, ""))
	popup.open(FALSE) // 0 is passed to open so that it doesn't use the onclose() proc

/// Creates, assigns and returns the new_character to spawn as. Assumes a valid mind.assigned_role exists.
/mob/dead/new_player/proc/create_character(atom/destination)
	spawning = TRUE
	close_spawn_windows()

	mind.active = FALSE //we wish to transfer the key manually
	var/mob/living/spawning_mob = mind.assigned_role.get_spawn_mob(client, destination)
	if(QDELETED(src) || !client)
		return // Disconnected while checking for the appearance ban.
	if(!isAI(spawning_mob)) // Unfortunately there's still snowflake AI code out there.
		mind.original_character_slot_index = client.prefs.default_slot
		mind.transfer_to(spawning_mob) //won't transfer key since the mind is not active
		mind.set_original_character(spawning_mob)
	client.init_verbs()
	. = spawning_mob
	new_character = .

/mob/dead/new_player/proc/transfer_character()
	. = new_character
	if(!.)
		return
	new_character.key = key //Manually transfer the key to log them in,
	new_character.stop_sound_channel(CHANNEL_LOBBYMUSIC)
	var/area/joined_area = get_area(new_character.loc)
	if(joined_area)
		joined_area.on_joining_game(new_character)
	new_character = null
	qdel(src)

/mob/dead/new_player/proc/ViewManifest()
	if(!client)
		return
	if(world.time < client.crew_manifest_delay)
		return
	client.crew_manifest_delay = world.time + (1 SECONDS)

	var/dat = "<html><head><meta http-equiv='Content-Type' content='text/html; charset=UTF-8'></head><body>"
	dat += "<h4>Crew Manifest</h4>"
	dat += GLOB.data_core.get_manifest_html()

	src << browse(dat, "window=manifest;size=387x420;can_close=1")

/mob/dead/new_player/Move()
	return 0


/mob/dead/new_player/proc/close_spawn_windows()

	src << browse(null, "window=latechoices") //closes late choices window
	hide_titlescreen() //closes the player setup window
	src << browse(null, "window=preferences") //closes job selection
	src << browse(null, "window=mob_occupation")
	src << browse(null, "window=latechoices") //closes late job selection

// Used to make sure that a player has a valid job preference setup, used to knock players out of eligibility for anything if their prefs don't make sense.
// A "valid job preference setup" in this situation means at least having one job set to low, or not having "return to lobby" enabled
// Prevents "antag rolling" by setting antag prefs on, all jobs to never, and "return to lobby if preferences not available"
// Doing so would previously allow you to roll for antag, then send you back to lobby if you didn't get an antag role
// This also does some admin notification and logging as well, as well as some extra logic to make sure things don't go wrong
/mob/dead/new_player/proc/check_preferences()
	if(!client)
		return FALSE //Not sure how this would get run without the mob having a client, but let's just be safe.
	if(client.prefs.joblessrole != RETURNTOLOBBY)
		return TRUE
	// If they have antags enabled, they're potentially doing this on purpose instead of by accident. Notify admins if so.
	var/has_antags = FALSE
	if(client.prefs.be_special.len > 0)
		has_antags = TRUE
	if(client.prefs.job_preferences.len == 0)
		if(!ineligible_for_roles)
			to_chat(src, "<span class='danger'>You have no jobs enabled, along with return to lobby if job is unavailable. This makes you ineligible for any round start role, please update your job preferences.</span>")
		ineligible_for_roles = TRUE
		ready = PLAYER_NOT_READY
		if(has_antags)
			log_admin("[src.ckey] has no jobs enabled, return to lobby if job is unavailable enabled and [client.prefs.be_special.len] antag preferences enabled. The player has been forcefully returned to the lobby.")
			message_admins("[src.ckey] has no jobs enabled, return to lobby if job is unavailable enabled and [client.prefs.be_special.len] antag preferences enabled. This is an old antag rolling technique. The player has been asked to update their job preferences and has been forcefully returned to the lobby.")
		return FALSE //This is the only case someone should actually be completely blocked from antag rolling as well
	return TRUE

/**
 * Prepares a client for the interview system, and provides them with a new interview
 *
 * This proc will both prepare the user by removing all verbs from them, as well as
 * giving them the interview form and forcing it to appear.
 */
/mob/dead/new_player/proc/register_for_interview()
	// First we detain them by removing all the verbs they have on client
	for (var/v in client.verbs)
		var/procpath/verb_path = v
		if (!(verb_path in GLOB.stat_panel_verbs))
			remove_verb(client, verb_path)

	// Then remove those on their mob as well
	for (var/v in verbs)
		var/procpath/verb_path = v
		if (!(verb_path in GLOB.stat_panel_verbs))
			remove_verb(src, verb_path)

	// Then we create the interview form and show it to the client
	var/datum/interview/I = GLOB.interviews.interview_for_client(client)
	if (I)
		I.ui_interact(src)

	// Add verb for re-opening the interview panel, and re-init the verbs for the stat panel
	add_verb(src, /mob/dead/new_player/proc/open_interview)
