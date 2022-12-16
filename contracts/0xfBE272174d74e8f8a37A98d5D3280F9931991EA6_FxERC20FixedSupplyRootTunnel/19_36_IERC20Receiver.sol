// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC20 Token Standard, Tokens Receiver.
/// @notice Interface for supporting safe transfers from ERC20 contracts with the Safe Transfers extension.
/// @dev See https://eips.ethereum.org/EIPS/eip-20
/// @dev Note: the ERC-165 identifier for this interface is 0x4fc35859.
interface IERC20Receiver {
    /// @notice Handles the receipt of ERC20 tokens.
    /// @dev Note: this function is called by an {ERC20SafeTransfer} contract after a safe transfer.
    /// @param operator The initiator of the safe transfer.
    /// @param from The previous tokens owner.
    /// @param value The amount of tokens transferred.
    /// @param data Optional additional data with no specified format.
    /// @return magicValue `bytes4(keccak256("onERC20Received(address,address,uint256,bytes)"))` (`0x4fc35859`) to accept, any other value to refuse.
    function onERC20Received(address operator, address from, uint256 value, bytes calldata data) external returns (bytes4 magicValue);
}