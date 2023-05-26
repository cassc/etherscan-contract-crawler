// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "../../../bridges/multichain/RangoMultichainModels.sol";

/// @title An interface to RangoMultichain.sol contract to improve type hinting
/// @author Uchiha Sasuke
interface IRangoMultichain {

    /// @notice Executes a MultichainOrg bridge call
    /// @param _actionType The type of bridge action which indicates the name of the function of MultichainOrg contract to be called
    /// @param _fromToken The address of bridging token
    /// @param _underlyingToken For _actionType = OUT_UNDERLYING, it's the address of the underlying token
    /// @param _inputAmount The amount of the token to be bridged
    /// @param multichainRouter Address of MultichainOrg contract on the current chain
    /// @param _receiverAddress The address of end-user on the destination
    /// @param _receiverChainID The network id of destination chain
    function multichainBridge(
        RangoMultichainModels.MultichainBridgeType _actionType,
        address _fromToken,
        address _underlyingToken,
        uint _inputAmount,
        address multichainRouter,
        address _receiverAddress,
        uint _receiverChainID
    ) external payable;

}