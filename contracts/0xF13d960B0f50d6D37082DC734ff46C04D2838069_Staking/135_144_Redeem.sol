// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../interfaces/IStaking.sol";

/// @title Tokemak Redeem Contract
/// @notice Converts PreToke to Toke
/// @dev Can only be used when fromToken has been unpaused
contract Redeem is Ownable {
	using SafeERC20 for IERC20;

	address public immutable fromToken;
	address public immutable toToken;
	address public immutable stakingContract;
	uint256 public immutable expirationBlock;
	uint256 public immutable stakingSchedule;

	/// @notice Redeem Constructor
	/// @dev approves max uint256 on creation for the toToken against the staking contract
	/// @param _fromToken the token users will convert from
	/// @param _toToken the token users will convert to
	/// @param _stakingContract the staking contract
	/// @param _expirationBlock a block number at which the owner can withdraw the full balance of toToken
	constructor(
		address _fromToken,
		address _toToken,
		address _stakingContract,
		uint256 _expirationBlock,
		uint256 _stakingSchedule
	) public {
		require(_fromToken != address(0), "INVALID_FROMTOKEN");
		require(_toToken != address(0), "INVALID_TOTOKEN");
		require(_stakingContract != address(0), "INVALID_STAKING");

		fromToken = _fromToken;
		toToken = _toToken;
		stakingContract = _stakingContract;
		expirationBlock = _expirationBlock;
		stakingSchedule = _stakingSchedule;

		//Approve staking contract for toToken to allow for staking within convert()
		IERC20(_toToken).safeApprove(_stakingContract, type(uint256).max);
	}

	/// @notice Allows a holder of fromToken to convert into toToken and simultaneously stake within the stakingContract
	/// @dev a user must approve this contract in order for it to burnFrom()
	function convert() external {
		uint256 fromBal = IERC20(fromToken).balanceOf(msg.sender);
		require(fromBal > 0, "INSUFFICIENT_BALANCE");
		ERC20Burnable(fromToken).burnFrom(msg.sender, fromBal);
		IStaking(stakingContract).depositFor(msg.sender, fromBal, stakingSchedule);
	}

	/// @notice Allows the claim on the toToken balance after the expiration has passed
	/// @dev callable only by owner
	function recoupRemaining() external onlyOwner {
		require(block.number >= expirationBlock, "EXPIRATION_NOT_PASSED");
		uint256 bal = IERC20(toToken).balanceOf(address(this));
		IERC20(toToken).safeTransfer(msg.sender, bal);
	}
}