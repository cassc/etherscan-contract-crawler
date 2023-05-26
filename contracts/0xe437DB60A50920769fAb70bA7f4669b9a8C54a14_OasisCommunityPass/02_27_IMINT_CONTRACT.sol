//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.18;

/**
 * IMINT_CONTRACT
 *
 * Interfaces that all contracts handled by Mint must meet
 * in order for the Mint system to recognize deployed contracts
 *
 * ERC721_MINT_V1 is an exception
 */
interface IMINT_CONTRACT {
    /**
     * @dev Returns the type of the contract
     */
    function contractType() external returns (bytes32);
}