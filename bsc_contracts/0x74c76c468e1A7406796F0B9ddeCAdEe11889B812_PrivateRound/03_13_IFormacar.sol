// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


interface IFormacar
{
	struct WhaleData
	{
		uint buyPeriod;
		uint buyVolume1;
		uint buyVolume2;
		uint buyVolume3;
		uint buyVolumeTemp;
		uint sellPeriod;
		uint sellVolume1;
		uint sellVolume2;
		uint sellVolume3;
		uint sellVolumeTemp;
	}

	struct Market
	{
		bool isMarket;

		bool antiBotEnabled;
		bool launchAllowed;
		uint launchedAt;

		uint buyFeeMillis;
		uint sellFeeMillis;

		uint minWhaleLimit;
		uint buyWhaleLimit;
		uint sellWhaleLimit;

		// To fix compilation stack error
		WhaleData whale;
	}

	function markets(address pair) external view returns(Market memory);
}