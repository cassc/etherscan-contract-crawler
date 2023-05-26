// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IOpenSeaCompatible {
    /**
     * Get the contract metadata
     */
    function contractURI() external view returns (string memory);

    /**
     * Set the contract metadata
     */
    function setContractURI(string memory contract_uri) external;
}