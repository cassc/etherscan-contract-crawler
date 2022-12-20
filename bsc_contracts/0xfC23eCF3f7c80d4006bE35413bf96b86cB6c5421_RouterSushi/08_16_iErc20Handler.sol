// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/// @title Interface to be used with handlers that support ERC20s and ERC721s.
/// @author Router Protocol.
interface IERCHandler {
    function getBridgeFee(uint8 destinationChainID, address feeTokenAddress) external view returns (uint256, uint256);
    function _reserve() external view returns(address);
}