// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

/// @title An interface to RangoMultichain.sol contract to improve type hinting
/// @author Uchiha Sasuke
interface IRangoMultichain {
    enum MultichainBridgeType { OUT, OUT_UNDERLYING, OUT_NATIVE }

    /// @notice The request object for MultichainOrg bridge call
    /// @param _actionType The type of bridge action which indicates the name of the function of MultichainOrg contract to be called
    /// @param _underlyingToken For _actionType = OUT_UNDERLYING, it's the address of the underlying token
    /// @param _multichainRouter Address of MultichainOrg contract on the current chain
    /// @param _receiverAddress The address of end-user on the destination
    /// @param _receiverChainID The network id of destination chain
    struct MultichainBridgeRequest {
        IRangoMultichain.MultichainBridgeType _actionType;
        address _underlyingToken;
        address _multichainRouter;
        address _receiverAddress;
        uint _receiverChainID;
    }

    /// @notice Executes a MultichainOrg bridge call
    /// @param _fromToken The address of bridging token
    /// @param _inputAmount The amount of the token to be bridged
    /// @param _request The other required field by MultichainOrg bridge
    function multichainBridge(
        address _fromToken, 
        uint _inputAmount, 
        MultichainBridgeRequest memory _request
    ) external payable;

}