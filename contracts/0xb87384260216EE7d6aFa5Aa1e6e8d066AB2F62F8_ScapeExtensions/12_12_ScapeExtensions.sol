// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import {ERC721ChildMulti} from "./ERC721ChildMulti.sol";

/// @title  ScapeExtensions
/// @author akuti.eth | scapes.eth
/// @notice Child tokens following the Scapes.
/// @dev    Child tokens following the parent contract.
contract ScapeExtensions is ERC721ChildMulti {
    constructor(address parent_)
        ERC721ChildMulti("ScapeExtensions", "SCAPEXT", parent_)
    {}

    /// @notice Adds a new child token by baseURI before the parent contract minted any token.
    /// @param baseURI The base URI for the new child token.
    function addBaseURIBeforeMint(string memory baseURI) external onlyOwner {
        if (_baseURIs.length >= MAX_CHILD_COLLECTIONS)
            revert ERC721Child__MaxChildContractsReached();
        _baseURIs.push(baseURI);
    }

    /// @notice Adds a new child token by baseURI after the parent contract minted tokens.
    /// @param baseURI The base URI for the new child token.
    /// @param tokenOwners The owners of the parent NFTs.
    function addBaseURIAfterMint(
        string memory baseURI,
        address[] calldata tokenOwners
    ) external onlyOwner {
        if (_baseURIs.length >= MAX_CHILD_COLLECTIONS)
            revert ERC721Child__MaxChildContractsReached();
        _init_using_tokenOwners(baseURI, tokenOwners);
    }

    /// @notice Update an existing baseURI by index.
    /// @param baseURI The new baseURI for an existing child token.
    /// @param index The the index of the child token to update.
    function updateBaseURI(string memory baseURI, uint256 index)
        external
        onlyOwner
    {
        if (index >= _baseURIs.length) revert ERC721Child__InvalidArgument();
        _baseURIs[index] = baseURI;
    }

    /// @notice Update the baseURI for merge tokens.
    /// @param baseURI The new baseURI for the merge tokens.
    function updateMergeBaseURI(string memory baseURI) external onlyOwner {
        _mergeBaseURI = baseURI;
    }
}