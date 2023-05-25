// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./BaseAccumulator.sol";

/// @title A contract that accumulates 3crv rewards and notifies them to the LGV4
/// @author StakeDAO
contract CurveAccumulator is BaseAccumulator {
	address public constant CRV3 = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;

	/* ========== CONSTRUCTOR ========== */
	constructor(address _tokenReward) BaseAccumulator(_tokenReward) {}

	/* ========== MUTATIVE FUNCTIONS ========== */
	/// @notice Notify a 3crv amount to the LGV4
	/// @param _amount amount to notify after the claim
	function notify(uint256 _amount) external {
		_notifyReward(tokenReward, _amount, true);
	}

	/// @notice Notify all 3crv accumulator balance to the LGV4
	function notifyAll() external {
		uint256 crv3Amount = IERC20(CRV3).balanceOf(address(this));
		_notifyReward(tokenReward, crv3Amount, true);
	}
}