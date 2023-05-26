// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ICometEvents {
    /**
     * @dev Emit an event when the contract configuration is updated.
     */
    event ContractConfigUpdated(
        uint256 maxSupply,
        address royalties,
        address beneficiary,
        string baseURI,
        string contractURI
    );

    /**
     * @dev Emit an event when the max supply is updated.
     */
    event MaxSupplyUpdated(uint256 maxSupply);
}