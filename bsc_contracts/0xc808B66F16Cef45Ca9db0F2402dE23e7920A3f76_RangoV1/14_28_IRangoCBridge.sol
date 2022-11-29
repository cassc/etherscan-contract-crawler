// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./Interchain.sol";

/// @title An interface to RangoCBridge.sol contract to improve type hinting
/// @author Uchiha Sasuke
interface IRangoCBridge {
    /// @notice Executes a cBridgeIM call
    /// @param _fromToken The address of source token to bridge
    /// @param _inputAmount The amount of input to be bridged
    /// @param _receiverContract Our RangoCbridge.sol contract in the destination chain that will handle the destination logic
    /// @param _dstChainId The network id of destination chain, ex: 10 for optimism
    /// @param _nonce A nonce mechanism used by cBridge that is generated off-chain, it normally is the time.now()
    /// @param _maxSlippage The maximum tolerable slippage by user on cBridge side (The bridge is not 1-1 and may have slippage in big swaps)
    /// @param _sgnFee The fee amount (in native token) that cBridge IM charges for delivering the message
    /// @param imMessage Our custom interchain message that contains all the required info for the RangoCBridge.sol on the destination
    function cBridgeIM(
        address _fromToken,
        uint _inputAmount,
        address _receiverContract, // The receiver app contract address, not recipient
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage,
        uint _sgnFee,

        Interchain.RangoInterChainMessage memory imMessage
    ) external payable;

    /// @notice Executes a bridging via cBridge
    /// @param _receiver The receiver address in the destination chain
    /// @param _token The token address to be bridged
    /// @param _amount The amount of the token to be bridged
    /// @param _dstChainId The network id of destination chain, ex: 10 for optimism
    /// @param _nonce A nonce mechanism used by cBridge that is generated off-chain, it normally is the time.now()
    /// @param _maxSlippage The maximum tolerable slippage by user on cBridge side (The bridge is not 1-1 and may have slippage in big swaps)
    function send(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage
    ) external;

}