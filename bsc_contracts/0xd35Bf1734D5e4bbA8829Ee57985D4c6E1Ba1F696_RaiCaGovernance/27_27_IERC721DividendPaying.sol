// SPDX-License-Identifier: Unlicense

pragma solidity 0.8.4;


/// @title Dividend-Paying ERC-721 Interface
/// @author Roger Wu (https://github.com/roger-wu) & petdomaa100 (https://github.com/petdomaa100)
/// @dev An interface for a dividend-paying ERC-721 contract.

interface IERC721DividendPaying {
	/// @notice View the amount of total ether that was send for distribution.
	/// @return The amount of total ether that was send for distribution.
	function vault() external view returns(uint256);

	/// @notice View the amount of dividend in wei that an address can withdraw.
	/// @param owner The address of a token holder.
	/// @return The amount of dividend in wei that `owner` can withdraw.
	function dividendOf(address owner) external view returns(uint256);

	/// @notice View the amount of dividend in wei that an address can withdraw.
	/// @param owner The address of a token holder.
	/// @return The amount of dividend in wei that `owner` can withdraw.
	function withdrawableDividendOf(address owner) external view returns(uint256);

	/// @notice View the amount of dividend in wei that an address has withdrawn.
	/// @param owner The address of a token holder.
	/// @return The amount of dividend in wei that `owner` has withdrawn.
	function withdrawnDividendOf(address owner) external view returns(uint256);

	/// @notice View the amount of dividend in wei that an address has earned in total.
	/// @dev accumulativeDividendOf(owner) = withdrawableDividendOf(owner) + withdrawnDividendOf(owner)
	/// @param owner The address of a token holder.
	/// @return The amount of dividend in wei that `owner` has earned in total.
	function accumulativeDividendOf(address owner) external view returns(uint256);

	/// @notice Distributes ether to token holders as dividends.
	/// @dev SHOULD distribute the paid ether to token holders as dividends.
	///  SHOULD NOT directly transfer ether to token holders in this function.
	///  MUST emit a `DividendsDistributed` event when the amount of distributed ether is greater than 0.
	function distributeDividends(uint256 _amount) external;

	/// @notice Withdraws the ether distributed to the sender.
	/// @dev SHOULD transfer `dividendOf(msg.sender)` wei to `msg.sender`, and `dividendOf(msg.sender)` SHOULD be 0 after the transfer.
	///  MUST emit a `DividendWithdrawn` event if the amount of ether transferred is greater than 0.
	function withdrawDividend() external;


	/// @dev This event MUST emit when ether is distributed to token holders.
	/// @param from The address which sends ether to this contract.
	/// @param amount The amount of distributed ether in wei.
	event DividendsDistributed(address indexed from, uint256 amount);

	/// @dev This event MUST emit when an address withdraws their dividend.
	/// @param to The address which withdraws ether from this contract.
	/// @param amount The amount of withdrawn ether in wei.
	event DividendWithdrawn(address indexed to, uint256 amount);
}