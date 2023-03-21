// SPDX-License-Identifier: UNLICENSED
// Created by DegenLabs https://bondswap.org

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Strings.sol";

library DateTime {
	function _daysToDate(uint256 _days)
		internal
		pure
		returns (
			uint256 year,
			uint256 month,
			uint256 day
		)
	{
		int256 __days = int256(_days);

		int256 L = __days + 68569 + 2440588;
		int256 N = (4 * L) / 146097;
		L = L - (146097 * N + 3) / 4;
		int256 _year = (4000 * (L + 1)) / 1461001;
		L = L - (1461 * _year) / 4 + 31;
		int256 _month = (80 * L) / 2447;
		int256 _day = L - (2447 * _month) / 80;
		L = _month / 11;
		_month = _month + 2 - 12 * L;
		_year = 100 * (N - 49) + _year + L;

		year = uint256(_year);
		month = uint256(_month);
		day = uint256(_day);
	}

	function timestampToDateTime(uint256 timestamp)
		internal
		pure
		returns (
			uint256 year,
			uint256 month,
			uint256 day,
			uint256 hour,
			uint256 minute,
			uint256 second
		)
	{
		(year, month, day) = _daysToDate(timestamp / 86400);
		uint256 secs = timestamp % 86400;
		hour = secs / 3600;
		secs = secs % 3600;
		minute = secs / 60;
		second = secs % 60;
	}

	function dateTimeToText(uint256 _timestamp) internal pure returns (string memory) {
		(uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second) = timestampToDateTime(
			_timestamp
		);
		return
			string.concat(
				Strings.toString(year),
				"/",
				_padTimeZero(month),
				"/",
				_padTimeZero(day),
				" ",
				_padTimeZero(hour),
				":",
				_padTimeZero(minute),
				":",
				_padTimeZero(second),
				" UTC"
			);
	}

	function _padTimeZero(uint256 _t) internal pure returns (string memory) {
		if (_t < 10) {
			return string.concat("0", Strings.toString(_t));
		} else {
			return Strings.toString(_t);
		}
	}
}