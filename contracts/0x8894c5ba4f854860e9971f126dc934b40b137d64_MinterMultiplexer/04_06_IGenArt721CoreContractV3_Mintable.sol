// SPDX-License-Identifier: MIT
// Copyright 2023 Proof Holdings Inc.

pragma solidity >=0.8.0;

/**
 * @notice IGenArt721CoreContractV3_Base minting interface
 */
interface IGenArt721CoreContractV3_Mintable {
    function mint_Ecf(address to, uint256 projectId, address sender) external returns (uint256 _tokenId);
}