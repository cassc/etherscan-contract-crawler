// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2022 Simplr
pragma solidity 0.8.11;

import "./PresaleableA.sol";

/// @title RevealableA
/// @author Chain Labs
/// @notice Module that adds functionality of revealing tokens.
/// @dev Handles revealing and structuring project URI
contract RevealableA is PresaleableA {
    using StringsUpgradeable for uint256;
    //------------------------------------------------------//
    //
    //  Storage
    //
    //------------------------------------------------------//
    /// @notice checks if collection is revealable or not
    /// @dev state that shows if Revealable module is active or not
    /// @return isRevealable checks if collection is revealable or not
    bool public isRevealable; // is the collection revealable

    /// @notice checks if collection is revealed or not
    /// @dev state that shows if collection is revealed
    /// @return isRevealed checks if collection is revealed or not
    bool public isRevealed; // is the collection revealed

    /// @notice provenance of final IPFS CID
    /// @dev keccak256 hash of final IPFS CID
    /// @return projectURIProvenance hash of revealed IPFS CID
    bytes32 public projectURIProvenance; // hash to make sure that Project URI dosen't change

    //------------------------------------------------------//
    //
    //  Owner only functions
    //
    //------------------------------------------------------//

    /// @notice set provenance of the collection
    /// @dev keccak hash of IPFS CID is done off chain and passed in as parameter
    /// @param _projectURIProvenance keccak256 hash of final IPFS CID
    function setProvenance(bytes32 _projectURIProvenance) internal {
        if (_projectURIProvenance != keccak256(abi.encode(projectURI))) {
            isRevealable = true;
            projectURIProvenance = _projectURIProvenance;
        } else {
            isRevealed = true;
        }
    }

    /// @notice Reveal and update Project URI
    /// @dev Reveal and update Project URI
    /// @param _projectURI new project URI
    function setProjectURIAndReveal(string memory _projectURI)
        external
        onlyOwner
    {
        require(isRevealable, "Revealable: non revealable");
        isRevealed = true;
        projectURI = _projectURI;
    }

    /// @notice set new project URI
    /// @dev set new project URI
    /// @param _projectURI new project URI
    function setProjectURI(string memory _projectURI) external onlyOwner {
        projectURI = _projectURI;
    }

    //------------------------------------------------------//
    //
    //  Public function
    //
    //------------------------------------------------------//

    /// @inheritdoc	ERC721AUpgradeable
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "R:004");
        string memory baseURI = _baseURI();
        return
            isRevealable
                ? isRevealed
                    ? string(
                        abi.encodePacked(baseURI, tokenId.toString(), ".json")
                    )
                    : baseURI
                : string(
                    abi.encodePacked(baseURI, tokenId.toString(), ".json")
                );
    }
}