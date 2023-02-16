// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ILevelsArtERC721TokenURI.sol";

library LevelsArtERC721Storage {
    struct Layout {
        // =============================================================
        //                            STORAGE
        // =============================================================

        // The contract that generates and returns tokenURIs
        ILevelsArtERC721TokenURI _tokenUriContract;
        // Contract version
        uint16 _version;
        // Contract description
        string _description;
        // Contract external link
        string _externalLink;
        // Max number of editions that can be minted
        uint256 _maxEditions;
        // Designated address of the Minter
        address _MINTER;
        // Keep tabs on mintTime of each tokenId
        mapping(uint256 tokenId => uint256 timestamp) _tokenIdMintedAt;
        // Seed for randomizing the URIs
        uint256 _tokenUriSeed;
        // The designated admin of the contract
        address _ADMIN;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("LevelsArt.contracts.storage.LevelsArtERC721");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}