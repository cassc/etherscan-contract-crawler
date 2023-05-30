// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Uri is Ownable {
    // The token metadata base URI
    string _baseTokenURI;

    // The contract base URI
    string _contractURI;

    /**
     * @notice Token metadata base URI.
     */
    function baseURI() external view returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @notice Sets the Base URI for the token API. "public" modifier is used
     *         so internal methods can call.
     * @param uri The new URI to set
     */
    function setBaseURI(string memory uri) public onlyOwner {
        _baseTokenURI = uri;
    }

    /**
     * @notice Sets the Contract URI for marketplace APIs.
     * @param uri The new URI to set
     */
    function setContractURI(string memory uri) public onlyOwner {
        _contractURI = uri;
    }

    /**
     * @notice OpenSea contract level metdata standard for displaying on
     *         storefront.
     *         Reference: https://docs.opensea.io/docs/contract-level-metadata
     */
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
}