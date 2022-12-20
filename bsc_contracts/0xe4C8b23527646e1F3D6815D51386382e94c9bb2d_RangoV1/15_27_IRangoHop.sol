// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

/// @title An interface to RangoHop.sol contract to improve type hinting
/// @author Uchiha Sasuke
interface IRangoHop {
    enum HopActionType { SWAP_AND_SEND, SEND_TO_L2 }

    struct HopRequest {
        HopActionType actionType;
        address bridgeAddress;
        uint256 chainId;
        address recipient;
        uint256 bonderFee;
        uint256 amountOutMin;
        uint256 deadline;
        uint256 destinationAmountOutMin;
        uint256 destinationDeadline;
        address relayer;
        uint256 relayerFee;
    }

    /// @notice Executes a Hop bridge call
    /// @param _request The request object containing required field by hop bridge
    /// @param _amount The amount to be bridged
    function hopBridge(
        HopRequest memory _request,
        address fromToken,
        uint _amount
    ) external payable;
}