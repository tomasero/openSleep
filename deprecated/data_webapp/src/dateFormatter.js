
export function getDate(format, dateString) {
	let year = ""
	let month = ""
	let day = ""
	let hour = ""
	let minutes = ""
	let seconds = ""
	let milliseconds = 0

	var dateStringIndex = 0;

	for(let char of format) {
		switch(char) {
			case "%":
				break;
			case "Y":
				year = parseInt(dateString.substring(dateStringIndex, dateStringIndex + 4));
				dateStringIndex += 4;
				break;
			case "m":
				month = parseInt(dateString.substring(dateStringIndex, dateStringIndex + 2));
				dateStringIndex += 2;
				break;
			case "d":
				day = parseInt(dateString.substring(dateStringIndex, dateStringIndex + 2));
				dateStringIndex += 2;
				break;
			case "M":
				minutes = parseInt(dateString.substring(dateStringIndex, dateStringIndex + 2));
				dateStringIndex += 2;
				break;
			case "H":
				hour = parseInt(dateString.substring(dateStringIndex, dateStringIndex + 2));
				dateStringIndex += 2;
				break;
			case "S":
				seconds = parseInt(dateString.substring(dateStringIndex, dateStringIndex + 2));
				dateStringIndex += 2;
				break;
			case ".":
				milliseconds = Math.floor(parseInt(dateString.substring(dateStringIndex+1, dateStringIndex+4)))
			default:
				dateStringIndex += 1;
				break;
		}
	}

	return new Date(year, month - 1, day, hour, minutes, seconds, milliseconds);
}