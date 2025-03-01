/datum/job/head_of_security
	title = "Head of Security"
	auto_deadmin_role_flags = DEADMIN_POSITION_HEAD|DEADMIN_POSITION_SECURITY
	department_head = list("Captain")
	head_announce = list(RADIO_CHANNEL_SECURITY)
	faction = FACTION_STATION
	total_positions = 1
	spawn_positions = 1
	supervisors = "the captain"
	selection_color = "#ffdddd"
	req_admin_notify = 1
	minimal_player_age = 14
	exp_requirements = 300
	exp_type = EXP_TYPE_CREW
	exp_type_department = EXP_TYPE_SECURITY

	outfit = /datum/outfit/job/hos
	plasmaman_outfit = /datum/outfit/plasmaman/head_of_security
	departments = DEPARTMENT_SECURITY | DEPARTMENT_COMMAND

	mind_traits = list(TRAIT_DONUT_LOVER)
	liver_traits = list(TRAIT_LAW_ENFORCEMENT_METABOLISM, TRAIT_ROYAL_METABOLISM)

	paycheck = PAYCHECK_COMMAND
	paycheck_department = ACCOUNT_SEC

	display_order = JOB_DISPLAY_ORDER_HEAD_OF_SECURITY
	bounty_types = CIV_JOB_SEC

	family_heirlooms = list(/obj/item/book/manual/wiki/security_space_law)

	job_flags = JOB_ANNOUNCE_ARRIVAL | JOB_CREW_MANIFEST | JOB_EQUIP_RANK | JOB_CREW_MEMBER | JOB_NEW_PLAYER_JOINABLE

	voice_of_god_power = 1.4 //Command staff has authority


/datum/job/head_of_security/get_captaincy_announcement(mob/living/captain)
	return "Due to staffing shortages, newly promoted Acting Captain [captain.real_name] on deck!"


/datum/outfit/job/hos
	name = "Head of Security"
	jobtype = /datum/job/head_of_security

	id = /obj/item/card/id/advanced/silver
	belt = /obj/item/pda/heads/hos
	ears = /obj/item/radio/headset/heads/hos/alt
	uniform = /obj/item/clothing/under/rank/security/head_of_security/peacekeeper //SKYRAT EDIT CHANGE - SEC_HAUL - ORIGINAL: /obj/item/clothing/under/rank/security/head_of_security
	shoes = /obj/item/clothing/shoes/combat/peacekeeper //SKYRAT EDIT CHANGE - SEC_HAUL
	suit = /obj/item/clothing/suit/armor/hos/trenchcoat/peacekeeper //SKYRAT EDIT CHANGE - SEC_HAUL - ORIGINAL: /obj/item/clothing/suit/armor/hos/trenchcoat
	gloves = /obj/item/clothing/gloves/combat/peacekeeper //SKYRAT EDIT CHANGE - SEC_HAUL - ORIGINAL: gloves = /obj/item/clothing/gloves/color/black
	head = /obj/item/clothing/head/hos/beret/peacekeeper //SKYRAT EDIT CHANGE - SEC_HAUL - ORIGINAL: /obj/item/clothing/head/hos/beret
	glasses = /obj/item/clothing/glasses/hud/security/sunglasses/peacekeeper //SKYRAT EDIT CHANGE - SEC_HAUL - ORIGINAL: /obj/item/clothing/glasses/hud/security/sunglasses
	suit_store = /obj/item/flashlight/seclite //SKYRAT EDIT CHANGE - SEC_HAUL & HOS_NERF - ORIGINAL: /obj/item/gun/energy/e_gun SEC_HAUL: /obj/item/gun/ballistic/automatic/pistol/g18
	r_pocket = /obj/item/assembly/flash/handheld
	l_pocket = /obj/item/restraints/handcuffs
	backpack_contents = list(/obj/item/melee/baton/loaded=1, /obj/item/modular_computer/tablet/preset/advanced/command=1)

	backpack = /obj/item/storage/backpack/security/peacekeeper //SKYRAT EDIT CHANGE - SEC_HAUL - ORIGINAL: backpack = /obj/item/storage/backpack/security
	satchel = /obj/item/storage/backpack/satchel/sec/peacekeeper
	duffelbag = /obj/item/storage/backpack/duffelbag/sec/peacekeeper
	box = /obj/item/storage/box/survival/security

	implants = list(/obj/item/implant/mindshield)

	chameleon_extras = list(/obj/item/gun/energy/e_gun/hos, /obj/item/stamp/hos)

	id_trim = /datum/id_trim/job/head_of_security

/datum/outfit/job/hos/hardsuit
	name = "Head of Security (Hardsuit)"

	mask = /obj/item/clothing/mask/gas/sechailer
	suit = /obj/item/clothing/suit/space/hardsuit/security/hos
	suit_store = /obj/item/tank/internals/oxygen
	backpack_contents = list(/obj/item/melee/baton/loaded=1)
