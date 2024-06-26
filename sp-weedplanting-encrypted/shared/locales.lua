local Locales = {
    ['place_sapling'] = 'Засаждане на растение',
	['canceled'] = 'Отказване..',
	['place_or_cancel'] = '[E] - Посадете растение / [G] - Отказ',
	['missing_filling_water'] = 'Липсва ти нещо, за да напълниш вода..',
	['missing_water'] = 'Липсва ти нещо, за да поливаш растението..',
	['missing_fertilizer'] = 'Нямаш тор..',
	['missing_mseed'] = 'Нямаш мъжко семе..',
	['clear_plant'] = 'Чисто растение',
	['harvesting_plant'] = 'Прибиране на реколтата',
	['watering_plant'] = 'Поливане на растение',
	['filling_water'] = 'Пълнене на вода',
	['fertilizing_plant'] = 'Наторяване на растението',
	['adding_male_seed'] = 'Добавяне на мъжко семе',
	['missing_tub'] = 'Нямате вана, за да засадите семето..',
	['check_plant'] = 'Проверете растението',
	['plant_header'] = 'Растение канабис',
	['empty_watering_can_header'] = 'Градинарска лейка',
	['esc_to_close'] = 'ESC или щракнете за затваряне',
	['filled_can'] = 'Напълнихте лейката',
	['watered_plant'] = 'Напоихте растението',
	['fertilizer_added'] = 'Наторихте растението',
	['male_seed_added'] = 'Добавихте мъжко семе към растението',
	['processing_branch'] = 'Обработка на клон',
	['processing'] = 'Обработка....',
	['processing_drying'] = 'Обработване на марихуана..',
	['processing_joint'] = 'Свиване на джонка..',
	['ready_for_harvest'] = 'Това растение е готово за прибиране на реколтата!',
	['clear_plant_header'] = 'Чисто растение',
	['fill_can_header'] = 'Напълнете лейка',
	['open_box'] = 'Шкаф',
	['fill_can_text'] = 'Напълнете лейката с вода..',
	['clear_plant_text'] = 'Растението е умряло',
	['process_branch'] = 'Обработка на Трева..',
	['process_joint'] = 'Направи си джонка..',
	['process_menu'] = 'Отвори..',
	['process_branchinfo'] = 'Ще са ви нужни плевели...',
	['drying_marijuana'] = 'Обработка на марихуана..',
	['create_joint'] = 'Направи Джойнт..',
	['pack_dry_weed'] = 'Опаковате на изсушена марихуана',
	['destroy_plant'] = 'Унищожи растението',
	['add_water'] = 'Полейте растението',
	['add_fertilizer'] = 'Наторете растението',
	['add_mseed'] = 'Добави мъжко семе',
	['not_enough_dryweed'] = 'Нямаш достатъчно изсушена трева..',
	['packaging_weed'] = 'Пакетиране..',
	['package_goods'] = 'Опакована стока',
	['grab_packaged_goods'] = 'Вземете пакет',
	['start_delivering'] = 'Започни доставка',
	['stop_delivering'] = 'при доставката',
    ['dont_have_branch'] = 'Нямате необходимите елементи',
	['dont_have_enough_dryweed'] = 'Нямате необходими/достатъчно елементи',
	['police_burn'] = 'Изгорете растението и извадете саксията.',
	['dont_have_key'] = 'Като нямаш ключ за тази врата как да се получат нещата ?',
}

function _U(entry)
	return Locales[entry]
end