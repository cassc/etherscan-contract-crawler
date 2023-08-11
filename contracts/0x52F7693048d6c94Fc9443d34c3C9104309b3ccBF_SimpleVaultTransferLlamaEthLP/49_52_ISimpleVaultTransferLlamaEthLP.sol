// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

/**
 * @title SimpleVaultTransferLlamaEthLP interface
 */
interface ISimpleVaultTransferLlamaEthLP {
    /**
     * @notice transfers specified amount of LLAMA:ETH LP to the TREASURY
     * @param amount amount of LLAMA:ETH LP to transfer
     */
    function transfer_llamaEthLP(uint256 amount) external;
}