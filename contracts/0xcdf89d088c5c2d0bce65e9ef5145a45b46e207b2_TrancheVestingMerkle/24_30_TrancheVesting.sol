// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { AdvancedDistributor } from "./AdvancedDistributor.sol";
import { ITrancheVesting, Tranche } from "../../interfaces/ITrancheVesting.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract TrancheVesting is AdvancedDistributor, ITrancheVesting {
	// time and vested fraction must monotonically increase in the tranche array
	Tranche[] private tranches;

	constructor(
		IERC20 _token,
		uint256 _total,
		string memory _uri,
		uint256 _voteFactor,
		Tranche[] memory _tranches
	) AdvancedDistributor(_token, _total, _uri, _voteFactor, 10000) {
		// tranches can be set in the constructor or in setTranches()
		_setTranches(_tranches);
	}

	function getVestedFraction(
		address, /*beneficiary*/
		uint256 time
	) public view override returns (uint256) {
		for (uint256 i = tranches.length; i != 0; ) {
			unchecked {
				--i;
			}
			if (time > tranches[i].time) {
				return tranches[i].vestedFraction;
			}
		}
		return 0;
	}

	function getTranche(uint256 i) public view returns (Tranche memory) {
		return tranches[i];
	}

	function getTranches() public view returns (Tranche[] memory) {
		return tranches;
	}

	function _setTranches(Tranche[] memory _tranches) private {
		require(_tranches.length != 0, "tranches required");

		delete tranches;

		uint128 lastTime = 0;
		uint128 lastVestedFraction = 0;

		for (uint256 i = 0; i < _tranches.length; ) {
			require(_tranches[i].vestedFraction != 0, "tranche vested fraction == 0");
			require(_tranches[i].time > lastTime, "tranche time must increase");
			require(
				_tranches[i].vestedFraction > lastVestedFraction,
				"tranche vested fraction must increase"
			);
			lastTime = _tranches[i].time;
			lastVestedFraction = _tranches[i].vestedFraction;
			tranches.push(_tranches[i]);

			emit SetTranche(i, lastTime, lastVestedFraction);

			unchecked {
				++i;
			}
		}

		require(lastTime <= 4102444800, "vesting ends after 4102444800 (Jan 1 2100)");
		require(lastVestedFraction == fractionDenominator, "last tranche must vest all tokens");
	}

	// Adjustable admin functions
	function setTranches(Tranche[] memory _tranches) external onlyOwner {
		_setTranches(_tranches);
	}
}