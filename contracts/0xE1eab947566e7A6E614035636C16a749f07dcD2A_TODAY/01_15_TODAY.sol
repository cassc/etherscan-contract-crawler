// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./SVG.sol";

contract TODAY is IERC721, Ownable, ERC721Enumerable {
	SVG private svg;
	uint256 public constant PRICE_MAX = 1024_000_000_000 gwei;
	uint256 public constant PRICE_MIN = 10_000_000 gwei;
	uint256 public constant PRICE_DECREASE_PERCENTAGE = 50;
	uint256 private constant ORIGIN_YEAR = 1970;
	uint256 private constant HOUR_IN_SECONDS = 3_600;
	uint256 private constant DAY_IN_SECONDS = 86_400;
	uint256 private constant YEAR_IN_SECONDS = 31_536_000;
	uint256 private constant LEAP_YEAR_IN_SECONDS = 31_622_400;
	uint256 private constant DIFF_HOURS = 5;
	uint256 private constant DIFF_SECONDS = DIFF_HOURS * HOUR_IN_SECONDS;
	mapping(uint256 => uint256) private timeByTokenId;

	constructor() ERC721("TODAY", "TODAY") {
		svg = new SVG();
	}

	function mint() public payable {
		uint256 time = block.timestamp;
		require(msg.value == getPrice(), "Incorrect payable amount");
		uint256 tokenId = getTodayId(time);
		timeByTokenId[tokenId] = time;
		_mint(_msgSender(), tokenId);
	}

	function getTodayId(uint256 time) public pure returns (uint256) {
		(uint256 year, uint256 month, uint256 day) = parseTime(time);
		return year * 10000 + month * 100 + day;
	}

	function getPrice() public view returns (uint256) {
		uint256 _est = getEST(block.timestamp);
		uint256 hour = (_est / 1 hours) % 24;
		uint256 price = PRICE_MAX;
		for (uint256 i = 0; i < hour; i++) {
			uint256 currentPrice = (price * PRICE_DECREASE_PERCENTAGE) / 100;
			price = PRICE_MIN >= currentPrice ? PRICE_MIN : currentPrice;
		}
		return price;
	}

	function isMinted() public view returns (bool) {
		return _exists(getTodayId(block.timestamp));
	}

	function tokenURI(uint256 tokenId) public view override returns (string memory) {
		require(_exists(tokenId), "Nonexistent token");
		string memory dateStr = getDateStr(timeByTokenId[tokenId]);
		return
			string(
				abi.encodePacked(
					"data:application/json;base64,",
					Base64.encode(
						abi.encodePacked(
							'{"name": "',
							dateStr,
							'", "image": "data:image/svg+xml;base64,',
							Base64.encode(bytes(svg.render(dateStr))),
							'"}'
						)
					)
				)
			);
	}

	function currentImage() public view returns (string memory) {
		return
			string(
				abi.encodePacked(
					"data:image/svg+xml;base64,",
					Base64.encode(bytes(svg.render(getDateStr(block.timestamp))))
				)
			);
	}

	function getDateStr(uint256 time) private pure returns (string memory) {
		(uint256 year, uint256 month, uint256 day) = parseTime(time);
		string[12] memory monthStr = [
			"JAN",
			"FEB",
			"MAR",
			"APR",
			"MAY",
			"JUN",
			"JUL",
			"AUG",
			"SEP",
			"OCT",
			"NOV",
			"DEC"
		];
		return string(abi.encodePacked(monthStr[month - 1], ".", Strings.toString(day), ",", Strings.toString(year)));
	}

	function parseTime(uint256 time)
		private
		pure
		returns (
			uint256 year,
			uint256 month,
			uint256 day
		)
	{
		uint256 est = getEST(time);
		year = ORIGIN_YEAR + est / YEAR_IN_SECONDS;
		uint256 numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);
		uint256 secondsAccountedFor = LEAP_YEAR_IN_SECONDS * numLeapYears;
		secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);
		while (secondsAccountedFor > est) {
			if (isLeapYear(year - 1)) {
				secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
			} else {
				secondsAccountedFor -= YEAR_IN_SECONDS;
			}
			year -= 1;
		}
		uint256 buf = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);
		secondsAccountedFor = LEAP_YEAR_IN_SECONDS * buf;
		secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - buf);
		for (uint256 i = 1; i <= 12; i++) {
			uint256 secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, year);
			if (secondsInMonth + secondsAccountedFor > est) {
				month = i;
				break;
			}
			secondsAccountedFor += secondsInMonth;
		}
		for (uint256 i = 1; i <= getDaysInMonth(month, year); i++) {
			if (DAY_IN_SECONDS + secondsAccountedFor > est) {
				day = i;
				break;
			}
			secondsAccountedFor += DAY_IN_SECONDS;
		}
	}

	function isLeapYear(uint256 year) private pure returns (bool) {
		if (year % 4 != 0) return false;
		if (year % 100 != 0) return true;
		if (year % 400 != 0) return false;
		return true;
	}

	function leapYearsBefore(uint256 year) private pure returns (uint256) {
		year -= 1;
		return year / 4 - year / 100 + year / 400;
	}

	function getDaysInMonth(uint256 month, uint256 year) private pure returns (uint256) {
		if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) return 31;
		else if (month == 4 || month == 6 || month == 9 || month == 11) return 30;
		else if (isLeapYear(year)) return 29;
		else return 28;
	}

	function getEST(uint256 time) private pure returns (uint256) {
		return time - DIFF_SECONDS;
	}

	function withdraw() public pure {
		revert();
	}
}