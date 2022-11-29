// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./Interchain.sol";

/// @title An interface to RangoVoyager.sol contract to improve type hinting
/// @author Uchiha Sasuke
interface IRangoVoyager {
    /// @notice The request object for Voyager bridge call
    struct VoyagerBridgeRequest {
        uint8 voyagerDestinationChainId;
        bytes32 resourceID;
        address feeTokenAddress;
        address reserveContract;
        uint256 dstTokenAmount;
        uint256 feeAmount;
        bytes data;
    }

    /// @notice Executes an Voyager bridge call
    /// @param fromToken The erc20 address of the input token, 0x000...00 for native token
    /// @param amount Amount of tokens to deposit. Will be amount of tokens to receive less fees.
    /// @param request The other required fields for Voyager bridge contract
    function voyagerBridge(address fromToken, uint256 amount, VoyagerBridgeRequest memory request) external payable;
}