//THIS FILE WAS EDITED BY SKYRAT EDIT

//SKYRAT EDIT ADDITION
GLOBAL_LIST_INIT(central_command_positions, list(
	"Nanotrasen Representative",
	"Blueshield"))
//SKYRAT EDIT END

GLOBAL_LIST_INIT(command_positions, list(
	"Captain",
	"Head of Personnel",
	"Head of Security",
	"Chief Engineer",
	"Research Director",
	"Quartermaster", //SKYRAT EDIT ADDITION
	"Chief Medical Officer"))


GLOBAL_LIST_INIT(engineering_positions, list(
	"Chief Engineer",
	"Station Engineer",
	"Atmospheric Technician"))


GLOBAL_LIST_INIT(medical_positions, list(
	"Chief Medical Officer",
	"Medical Doctor",
	"Paramedic",
	"Virologist",
	"Chemist"))


GLOBAL_LIST_INIT(science_positions, list(
	"Research Director",
	"Scientist",
	"Geneticist",
	"Roboticist",
	"Vanguard Operative")) //SKYRAT EDIT ADDITION


GLOBAL_LIST_INIT(supply_positions, list(
	"Quartermaster",
	"Cargo Technician",
	"Shaft Miner"))


GLOBAL_LIST_INIT(service_positions, list(
	"Head of Personnel",
	"Bartender",
	"Botanist",
	"Cook",
	"Janitor",
	"Curator",
	"Psychologist",
	"Lawyer",
	"Chaplain",
	"Clown",
	"Mime",
	"Prisoner",
	"Assistant"))

//we really need to split service into civillian positions officially, until then this is my solution
GLOBAL_LIST_INIT(service_food_positions, list(
	"Bartender",
	"Botanist",
	"Cook"))

GLOBAL_LIST_INIT(security_positions, list(
	"Head of Security",
	"Warden",
	"Detective",
	"Security Officer",
	"Security Medic",
	"Security Sergeant",
	"Civil Disputes Officer",
	"Corrections Officer")) //SKYRAT EDIT - LIST AMENDED

/// These aren't defacto jobs, but are the special departmental variants for sec officers.
GLOBAL_LIST_INIT(security_sub_positions, list(
	"Security Officer (Cargo)",
	"Security Officer (Engineering)",
	"Security Officer (Medical)",
	"Security Officer (Science)",
))

GLOBAL_LIST_INIT(nonhuman_positions, list(
	"AI",
	"Cyborg",
	ROLE_PAI))

// job categories for rendering the late join menu
GLOBAL_LIST_INIT(position_categories, list(
	EXP_TYPE_CENTRAL_COMMAND = list("jobs" = central_command_positions, "#8df1b7"), //SKYRAT EDIT ADDITION
	EXP_TYPE_COMMAND = list("jobs" = command_positions, "color" = "#ccccff"),
	EXP_TYPE_ENGINEERING = list("jobs" = engineering_positions, "color" = "#ffeeaa"),
	EXP_TYPE_SUPPLY = list("jobs" = supply_positions, "color" = "#ddddff"),
	EXP_TYPE_SILICON = list("jobs" = nonhuman_positions - "pAI", "color" = "#ccffcc"),
	EXP_TYPE_SERVICE = list("jobs" = service_positions, "color" = "#bbe291"),
	EXP_TYPE_MEDICAL = list("jobs" = medical_positions, "color" = "#ffddf0"),
	EXP_TYPE_SCIENCE = list("jobs" = science_positions, "color" = "#ffddff"),
	EXP_TYPE_SECURITY = list("jobs" = security_positions, "color" = "#ffdddd")
))

GLOBAL_LIST_INIT(exp_jobsmap, list(
	EXP_TYPE_CREW = list("titles" = central_command_positions | command_positions | engineering_positions | medical_positions | science_positions | supply_positions | security_positions | service_positions | list("AI","Cyborg")), // crew positions //SKYRAT EDIT ADDITION
	EXP_TYPE_CENTRAL_COMMAND = list("titles" = central_command_positions), //SKYRAT EDIT ADDITION
	EXP_TYPE_COMMAND = list("titles" = command_positions),
	EXP_TYPE_ENGINEERING = list("titles" = engineering_positions),
	EXP_TYPE_MEDICAL = list("titles" = medical_positions),
	EXP_TYPE_SCIENCE = list("titles" = science_positions),
	EXP_TYPE_SUPPLY = list("titles" = supply_positions),
	EXP_TYPE_SECURITY = list("titles" = security_positions),
	EXP_TYPE_SILICON = list("titles" = list("AI","Cyborg")),
	EXP_TYPE_SERVICE = list("titles" = service_positions)
))

// TO DO: Replace this with job datum flags instead.
GLOBAL_LIST_INIT(exp_specialmap, list(
	EXP_TYPE_LIVING = list(), // all living mobs
	EXP_TYPE_ANTAG = list(),
	EXP_TYPE_SPECIAL = list(
		ROLE_LIFEBRINGER,
		ROLE_ASHWALKER,
		ROLE_EXILE,
		ROLE_SERVANT_GOLEM,
		ROLE_FREE_GOLEM,
		ROLE_HERMIT,
		ROLE_ESCAPED_PRISONER,
		ROLE_HOTEL_STAFF,
		ROLE_SPACE_SYNDICATE,
		ROLE_ANCIENT_CREW,
		ROLE_SPACE_DOCTOR,
		ROLE_SPACE_BARTENDER,
		ROLE_BEACH_BUM,
		ROLE_SKELETON,
		ROLE_ZOMBIE,
		ROLE_SPACE_BAR_PATRON,
		ROLE_LAVALAND_SYNDICATE,
		ROLE_MAINTENANCE_DRONE,
		ROLE_GHOST_ROLE,
		), // Ghost roles
	EXP_TYPE_GHOST = list() // dead people, observers
))
GLOBAL_PROTECT(exp_jobsmap)
GLOBAL_PROTECT(exp_specialmap)

//this is necessary because antags happen before job datums are handed out, but NOT before they come into existence
//so I can't simply use job datum.department_head straight from the mind datum, laaaaame.
/proc/get_department_heads(job_title)
	if(!job_title)
		return list()

	for(var/datum/job/job as anything in SSjob.joinable_occupations)
		if(job.title == job_title)
			return job.department_head //this is a list

/proc/get_full_job_name(job)
	var/static/regex/cap_expand = new("cap(?!tain)")
	var/static/regex/cmo_expand = new("cmo")
	var/static/regex/hos_expand = new("hos")
	var/static/regex/hop_expand = new("hop")
	var/static/regex/rd_expand = new("rd")
	var/static/regex/ce_expand = new("ce")
	var/static/regex/qm_expand = new("qm")
	var/static/regex/sec_expand = new("(?<!security )officer")
	var/static/regex/engi_expand = new("(?<!station )engineer")
	var/static/regex/atmos_expand = new("atmos tech")
	var/static/regex/doc_expand = new("(?<!medical )doctor|medic(?!al)")
	var/static/regex/mine_expand = new("(?<!shaft )miner")
	var/static/regex/chef_expand = new("chef")
	var/static/regex/borg_expand = new("(?<!cy)borg")

	job = lowertext(job)
	job = cap_expand.Replace(job, "captain")
	job = cmo_expand.Replace(job, "chief medical officer")
	job = hos_expand.Replace(job, "head of security")
	job = hop_expand.Replace(job, "head of personnel")
	job = rd_expand.Replace(job, "research director")
	job = ce_expand.Replace(job, "chief engineer")
	job = qm_expand.Replace(job, "quartermaster")
	job = sec_expand.Replace(job, "security officer")
	job = engi_expand.Replace(job, "station engineer")
	job = atmos_expand.Replace(job, "atmospheric technician")
	job = doc_expand.Replace(job, "medical doctor")
	job = mine_expand.Replace(job, "shaft miner")
	job = chef_expand.Replace(job, "cook")
	job = borg_expand.Replace(job, "cyborg")
	return job
