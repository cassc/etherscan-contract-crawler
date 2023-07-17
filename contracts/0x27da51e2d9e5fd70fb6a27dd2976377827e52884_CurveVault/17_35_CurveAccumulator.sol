// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./BaseAccumulator.sol";
import "../strategy/CurveStrategy.sol";

/// @title A contract that accumulates 3crv rewards and notifies them to the LGV4
/// @author StakeDAO
contract CurveAccumulator is BaseAccumulator {
	address public constant CRV3 = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
	address public constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
	address public strategy = 0x20F1d4Fed24073a9b9d388AfA2735Ac91f079ED6;

	/* ========== CONSTRUCTOR ========== */
	constructor(address _tokenReward, address _gauge) BaseAccumulator(_tokenReward, _gauge) {}

	/* ========== MUTATIVE FUNCTIONS ========== */
	/// @notice Notify a 3crv amount to the LGV4
	/// @param _amount amount to notify after the claim
	function notify(uint256 _amount) external {
		CurveStrategy(strategy).claim3Crv(false);
		_notifyReward(tokenReward, _amount);
		_distributeSDT();
	}

	/// @notice Notify all 3crv accumulator balance to the LGV4
	function notifyAll() external {
		CurveStrategy(strategy).claim3Crv(false);
		uint256 crv3Amount = IERC20(CRV3).balanceOf(address(this));
		uint256 crvAmount = IERC20(CRV).balanceOf(address(this));
		_notifyReward(tokenReward, crv3Amount);
		_notifyReward(CRV, crvAmount);
		_distributeSDT();
	}

	function changeStrategy(address _newStrategy) external {
		require(msg.sender == governance, "!gov");
		strategy = _newStrategy;
	}
}