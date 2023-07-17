// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/**
 *  @notice IGenesis is interface of genesis token
 */
interface IHLPeaceGenesisAngel {
    function mintBatch(address receiver, uint256 times) external;
}