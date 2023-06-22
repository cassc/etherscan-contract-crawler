// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

abstract contract WithERC721AMetadata is ERC721A, Ownable {
    using Strings for uint256;

    /// @dev Emitted when the content identifyer changes
    event MetadataURIChanged(string indexed baseURI);

    // Whether metadata is frozen
    bool public frozen;

    /// @dev The base URI of the folder containing all JSON files.
    string public baseURI;

    /// Instantiate the contract
    /// @param baseURI_ the base URI the token metadata.
    constructor (string memory baseURI_) {
        baseURI = baseURI_;
    }

    /// Get the tokenURI for a tokenID
    /// @param tokenId the token id for which to get the matadata URL
    /// @dev links to the metadata json file on IPFS.
    /// @return the URL to the token metadata file
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        // We don't check whether the _baseURI is set like in the OpenZeppelin implementation
        // as we're deploying the contract with the CID.
        return string(abi.encodePacked(
            _baseURI(), "/", tokenId.toString(), "/metadata.json"
        ));
    }

    /// Configure the baseURI for the tokenURI method.
    /// @dev override the standard OpenZeppelin implementation
    /// @return the IPFS base uri
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /// Set the base URI for this collection.
    /// @param baseURI_ the new base URI
    /// @dev update the base URI for this collection.
    function setBaseURI(string memory baseURI_) public onlyOwner unfrozen {
        baseURI = baseURI_;

        emit MetadataURIChanged(baseURI);
    }

    /// @dev Freeze the metadata
    function freeze() external onlyOwner {
        frozen = true;
    }

    /// @dev Whether metadata is unfrozen
    modifier unfrozen() {
        require(! frozen, "Metadata already frozen");

        _;
    }
}