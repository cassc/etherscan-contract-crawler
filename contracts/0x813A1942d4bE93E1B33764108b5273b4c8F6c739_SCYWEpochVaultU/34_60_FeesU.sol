// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { SafeERC20Upgradeable as SafeERC20, IERC20Upgradeable as IERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import { AuthU } from "./AuthU.sol";
import { FeeConfig } from "./Fees.sol";

// import "hardhat/console.sol";

abstract contract FeesU is AuthU {
	uint256 public constant MAX_MANAGEMENT_FEE = .05e18; // 5%
	uint256 public constant MAX_PERFORMANCE_FEE = .25e18; // 25%

	/// @notice The percentage of profit recognized each harvest to reserve as fees.
	/// @dev A fixed point number where 1e18 represents 100% and 0 represents 0%.
	uint256 public performanceFee;

	/// @notice Annual management fee.
	/// @dev A fixed point number where 1e18 represents 100% and 0 represents 0%.
	uint256 public managementFee;

	/// @notice address where all fees are sent to
	address public treasury;

	function __Fees_init(FeeConfig memory feeConfig) public onlyInitializing {
		treasury = feeConfig.treasury;
		performanceFee = feeConfig.performanceFee;
		managementFee = feeConfig.managementFee;
		emit SetTreasury(feeConfig.treasury);
		emit SetPerformanceFee(feeConfig.performanceFee);
		emit SetManagementFee(feeConfig.managementFee);
	}

	/// @notice Sets a new performanceFee.
	/// @param _performanceFee The new performance fee.
	function setPerformanceFee(uint256 _performanceFee) public onlyOwner {
		if (_performanceFee > MAX_PERFORMANCE_FEE) revert OverMaxFee();

		performanceFee = _performanceFee;
		emit SetPerformanceFee(performanceFee);
	}

	/// @notice Sets a new performanceFee.
	/// @param _managementFee The new performance fee.
	function setManagementFee(uint256 _managementFee) public onlyOwner {
		if (_managementFee > MAX_MANAGEMENT_FEE) revert OverMaxFee();

		managementFee = _managementFee;
		emit SetManagementFee(_managementFee);
	}

	/// @notice Updates treasury.
	/// @param _treasury New treasury address.
	function setTreasury(address _treasury) public onlyOwner {
		treasury = _treasury;
		emit SetTreasury(_treasury);
	}

	/// @notice Emitted when performance fee is updated.
	/// @param performanceFee The new perforamance fee.
	event SetPerformanceFee(uint256 performanceFee);

	/// @notice Emitted when management fee is updated.
	/// @param managementFee The new management fee.
	event SetManagementFee(uint256 managementFee);

	event SetTreasury(address indexed treasury);

	error OverMaxFee();

	uint256[50] private __gap;
}