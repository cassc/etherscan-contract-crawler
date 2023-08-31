// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {ERC721, ERC721TokenReceiver} from "solmate/tokens/ERC721.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {IAdoptAHyphen} from "./interfaces/IAdoptAHyphen.sol";
import {IERC721} from "./interfaces/IERC721.sol";
import {AdoptAHyphenArt} from "./utils/AdoptAHyphenArt.sol";
import {AdoptAHyphenMetadata} from "./utils/AdoptAHyphenMetadata.sol";
import {Base64} from "./utils/Base64.sol";

/// @title adopt-a-hyphen
/// @notice Adopt a Hyphen: exchange a Hyphen NFT into this contract to mint a
/// Hyphen Guy.
contract AdoptAHyphen is IAdoptAHyphen, ERC721, ERC721TokenReceiver, Owned {
    // -------------------------------------------------------------------------
    // Constants
    // -------------------------------------------------------------------------

    /// @notice Description of the collection.
    string constant COLLECTION_DESCRIPTION =
        unicode"With each passing day, more and more people are switching from "
        unicode"“on-chain” to “onchain.” While this may seem like a harmless ch"
        unicode"oice, thousands of innocent hyphens are losing their place in t"
        unicode"he world. No longer needed to hold “on-chain” together, these h"
        unicode"yphens are in need of a loving place to call home. What if you "
        unicode"could make a difference in a hyphen’s life forever?\\n\\nIntrod"
        unicode"ucing the Adopt-a-Hyphen program, where you can adopt a hyphen "
        unicode"and give it a new home...right in your wallet! Each hyphen in t"
        unicode"his collection was adopted via an on-chain mint and is now safe"
        unicode" and sound in this collection. As is their nature, each hyphen "
        unicode"lives fully on-chain and is rendered in Solidity as cute, gener"
        unicode"ative ASCII art.";

    // -------------------------------------------------------------------------
    // Immutable storage
    // -------------------------------------------------------------------------

    /// @notice The Hyphen NFT contract that must be transferred into this
    /// contract in order to mint a token.
    IERC721 public immutable override hyphenNft;

    // -------------------------------------------------------------------------
    // Constructor + Mint
    // -------------------------------------------------------------------------

    /// @param _owner Initial owner of the contract.
    constructor(
        address _hyphenNft,
        address _owner
    ) ERC721("Adopt-a-Hyphen", "-") Owned(_owner) {
        hyphenNft = IERC721(_hyphenNft);
    }

    /// @inheritdoc IAdoptAHyphen
    function mint(uint256 _tokenId) external {
        // Transfer the Hyphen NFT into this contract.
        hyphenNft.transferFrom(msg.sender, address(this), _tokenId);

        // Mint token.
        _mint(msg.sender, _tokenId);
    }

    // -------------------------------------------------------------------------
    // ERC721Metadata
    // -------------------------------------------------------------------------

    /// @inheritdoc ERC721
    function tokenURI(
        uint256 _tokenId
    ) public view override returns (string memory) {
        // Revert if the token hasn't been minted.
        if (_ownerOf[_tokenId] == address(0)) revert TokenUnminted();

        // Seed to generate the art and metadata from.
        uint256 seed = uint256(keccak256(abi.encodePacked(_tokenId)));

        // Generate the metadata.
        string memory name = AdoptAHyphenMetadata.generateName(seed);
        string memory attributes = AdoptAHyphenMetadata.generateAttributes(
            seed
        );

        return
            string.concat(
                "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                        '{"name":"',
                        name,
                        '","description":"',
                        COLLECTION_DESCRIPTION,
                        '","image_data":"data:image/svg+xml;base64,',
                        Base64.encode(
                            abi.encodePacked(AdoptAHyphenArt.render(seed))
                        ),
                        '","attributes":',
                        attributes,
                        "}"
                    )
                )
            );
    }

    // -------------------------------------------------------------------------
    // Contract metadata
    // -------------------------------------------------------------------------

    /// @inheritdoc IAdoptAHyphen
    function contractURI() external pure override returns (string memory) {
        return
            string.concat(
                "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                        '{"name":"Adopt-a-Hyphen","description":"',
                        COLLECTION_DESCRIPTION,
                        '"}'
                    )
                )
            );
    }
}