pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
interface IERC1404 {
	/// @notice Detects if a transfer will be reverted and if so returns an appropriate reference code
	/// @param from Sending address
	/// @param to Receiving address
	/// @param value Amount of tokens being transferred
	/// @return Code by which to reference message for rejection reasoning
	function detectTransferRestriction(
		address from,
		address to,
		uint256 value
	) external view returns (uint8);

	/// @notice Returns a human-readable message for a given restriction code
	/// @param restrictionCode Identifier for looking up a message
	/// @return Text showing the restriction's reasoning
	function messageForTransferRestriction(uint8 restrictionCode)
		external
		view
		returns (string memory);
}