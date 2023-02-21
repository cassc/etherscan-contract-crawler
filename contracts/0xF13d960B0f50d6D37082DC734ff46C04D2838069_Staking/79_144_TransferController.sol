// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./BaseController.sol";

contract TransferController is BaseController {
	using SafeERC20 for IERC20;

	address public immutable treasuryAddress;

	constructor(
		address manager,
		address accessControl,
		address addressRegistry,
		address treasury
	) public BaseController(manager, accessControl, addressRegistry) {
		require(treasury != address(0), "INVALID_TREASURY_ADDRESS");
		treasuryAddress = treasury;
	}

	/// @notice Used to transfer funds to our treasury
	/// @dev Calls into external contract
	/// @param tokenAddress Address of IERC20 token
	/// @param amount amount of funds to transfer
	function transferFunds(address tokenAddress, uint256 amount) external onlyManager onlyMiscOperation {
		require(tokenAddress != address(0), "INVALID_TOKEN_ADDRESS");
		require(amount > 0, "INVALID_AMOUNT");
		require(addressRegistry.checkAddress(tokenAddress, 0), "INVALID_TOKEN");

		IERC20(tokenAddress).safeTransfer(treasuryAddress, amount);
	}
}