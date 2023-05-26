// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @dev Contract module which abstracts some aspects of URI management away from the main contract.
 *   This contract:
 *
 *      - Provides an adjustable 'default' URI for the location of the metadata (of tokens
 *        in the collection). Typically this is a folder in IPFS or some sort of web server.
 *
 *      - Enables eventual freezing of all metadata, which is useful if a project wants to start
 *        with centralized metadata and eventually move it to a decentralized location and then 'freeze'
 *        it there for posterity.
 */
abstract contract URIManager {

    string private _baseDefaultURI;
    string private _contractURI;
    bool private _URIsAreForeverFrozen;

    /**
     * @dev Initializes the contract in unfrozen state with a particular
     * baseURI (the default location for the data of all the NFTs)
     */
    constructor(string memory initialBaseURI) {
        _baseDefaultURI = initialBaseURI;
        _URIsAreForeverFrozen = false;
    }
    
    function _setBaseURI(string calldata _uri) internal {
        _baseDefaultURI = _uri;
    }

    function _setContractURI(string calldata _newContractURI) internal {
        _contractURI = _newContractURI;
    }

    function _getBaseURI() internal view returns(string memory) {
        return _baseDefaultURI;
    }

    /**
     * @dev Opensea states that a contract may have a contractURI() function, which
     *  returns metadata for the contract as a whole.
     */
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /**
     * @dev Returns true if the metadata URIs have been finalized forever.
     */
    function AreURIsForeverFrozen() public view virtual returns (bool) {
        return _URIsAreForeverFrozen;
    }

    /**
     * @dev Modifier to make a function callable only if the URIs have not been frozen forever.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier allowIfNotFrozen() {
        require(!AreURIsForeverFrozen(), "URIManager: URIs have been frozen forever");
        _;
    }

    /**
     * @dev Freezes all future changes of the URIs.
     *
     * Requirements:
     *
     * - The URIs must not be frozen already.
     */
    function _freezeURIsForever() internal virtual allowIfNotFrozen {
        _URIsAreForeverFrozen = true;
    }
}