// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

/// @title Interface to be used with handlers that support ERC20s and ERC721s.
/// @author Router Protocol.
interface IERCHandlerDecimals {
    function setTokenDecimals(
        address[] calldata tokenAddress,
        uint8[] calldata destinationChainID,
        uint8[] calldata decimals
    ) external;
}