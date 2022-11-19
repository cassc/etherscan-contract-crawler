// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

/// @title The root contract that handles Rango's interaction with Router bridge
/// @author Uchiha Sasuke
/// @dev This is deployed as a separate contract from RangoV1
interface IVoyager {
    function depositETH(
        uint8 destinationChainID,
        bytes32 resourceID,
        bytes calldata data,
        uint256[] memory flags,
        address[] memory path,
        bytes[] calldata dataTx,
        address feeTokenAddress
    ) external payable;
}