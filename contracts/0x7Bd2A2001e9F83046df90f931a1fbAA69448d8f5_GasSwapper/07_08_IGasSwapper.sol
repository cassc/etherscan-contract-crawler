// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/// @title GasSwapper
/// @author 0xPolygon (Daniel Gretzke, Zoran Cuckovic)
/// @notice Allows to bridge tokens from Ethereum to Polygon
/// @notice Uses provided ETH to swap into MATIC to be bridged alongside the token to pay for gas on Polygon
interface IGasSwapper {
    error SwapFailed(bytes reason);
    error RefundFailed();

    event Swap(address indexed token, address indexed user, uint256 bridgedTokenAmount, uint256 bridgedMaticAmount);

    /**
     * @notice swap tokens
     * @param token token to bridge
     * @param amount amount of token to bridge
     * @param user address to receive bridged funds
     * @param swapCallData calldata for 0x swap
     * @dev msg.value amount of ETH to swap into MATIC
     */
    function swapAndBridge(address token, uint256 amount, address user, bytes calldata swapCallData) external payable;
}