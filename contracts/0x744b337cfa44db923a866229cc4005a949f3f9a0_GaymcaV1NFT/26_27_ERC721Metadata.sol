// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 *  @dev this contract holds all the usual metadata items we want to have in our contracts.
 */
abstract contract ERC721Metadata {
    using ECDSA for bytes32;

    string internal _contractURI;
    string internal _tokenBaseURI;
    // to insert the hash of the NFT images
    string public provenanceHash;

    /**
     * @dev allow you to set new baseUri
     */
    function _setBaseUri(string memory _newBaseUri) internal {
        _tokenBaseURI = _newBaseUri;
    }

    /**
     * @dev allow you to set new contractUri
     */
    function _setContractURI(string memory URI) internal {
        _contractURI = URI;
    }

    /**
     * @dev contractURI for general metadata for the contract.
     */
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /// @dev set the provenance hash for the nft collection
    function _setProvenanceHash(string calldata hash) internal {
        provenanceHash = hash;
    }
}