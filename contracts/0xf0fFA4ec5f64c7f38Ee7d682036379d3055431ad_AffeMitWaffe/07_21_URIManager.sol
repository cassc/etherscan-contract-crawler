// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Strings.sol";

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
    using Strings for uint256;

    string private _defaultBaseURI;
    string private _contractURI;
    bool private _URIsAreForeverFrozen;

    /**
     * @dev Initializes the contract in unfrozen state with a particular
     * baseURI (a location containing the matadata for each NFT) and a particular
     * contractURI (a file containing collection-wide data, such as the description,
     * name, image, etc. of the collection.)
     */
    constructor(string memory initialBaseURI, string memory initialContractURI) {
        _setBaseURI(initialBaseURI);
        _setContractURI(initialContractURI);
        _URIsAreForeverFrozen = false;
    }
    
    function _setBaseURI(string memory _uri) internal {
        _defaultBaseURI = _uri;
    }

    function _setContractURI(string memory _newContractURI) internal {
        _contractURI = _newContractURI;
    }

    function _getBaseURI() internal view returns (string memory) {
        return _defaultBaseURI;
    }

    function _buildTokenURI(uint256 tokenId) internal view returns (string memory) {
        // return a concatenation of the baseURI (of the collection), with the tokenID, and the file extension.
        return string(abi.encodePacked(_getBaseURI(), tokenId.toString(), ".json"));
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
    function areURIsForeverFrozen() public view virtual returns (bool) {
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
        require(!areURIsForeverFrozen(), "URIManager: URIs have been frozen forever");
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