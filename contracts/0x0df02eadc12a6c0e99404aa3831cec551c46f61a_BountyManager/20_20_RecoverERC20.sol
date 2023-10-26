// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title RecoverERC20 contract
/// @author Radiant Devs
/// @dev All function calls are currently implemented without side effects
contract RecoverERC20 {
	using SafeERC20 for IERC20;

	/// @notice Emitted when ERC20 token is recovered
	event Recovered(address indexed token, uint256 amount);

	/**
	 * @notice Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
	 */
	function _recoverERC20(address tokenAddress, uint256 tokenAmount) internal {
		IERC20(tokenAddress).safeTransfer(msg.sender, tokenAmount);
		emit Recovered(tokenAddress, tokenAmount);
	}
}