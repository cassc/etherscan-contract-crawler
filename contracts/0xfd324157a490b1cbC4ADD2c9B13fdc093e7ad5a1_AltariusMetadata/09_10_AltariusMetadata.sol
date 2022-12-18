// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./libs/Base64.sol";

/**
 * @title Altarius Metadata
 *
 * @dev This contract stores the metadata of the Altarius cards.
 * Metadata is stored on-chain, except for images. Only IPFS CID is stored for them.
 *
 * Full metadata is divided into 3 parts:
 * - Name: Stores the name of the card.
 * - Metadata: Stores card metadata to be used by other contracts.
 * - Images: Stores the IPFS CID of the images of the card.
 *
 * Type, rarity and edition strings are linked to their respective mappings for efficiency.
 */
contract AltariusMetadata is AccessControl {
    using Counters for Counters.Counter;

    struct Metadata {
        bool immortal;
        bool borderless;
        bool holographic;
        uint40 level;
        uint24 cardType;
        uint24 rarity;
        uint24 edition;
        uint24 moon;
        uint24 sun;
        uint24 swift;
        uint24 strong;
        uint24 sorcerous;
    }

    struct Images {
        bytes32 highCid1;
        bytes32 highCid2;
        bytes32 thumbnailCid1;
        bytes32 thumbnailCid2;
        bytes32 squareCid1;
        bytes32 squareCid2;
    }

    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");

    mapping(uint256 => bytes32) public cardTypes;
    Counters.Counter public cardTypeCounter;

    mapping(uint256 => bytes32) public rarities;
    Counters.Counter public rarityCounter;

    mapping(uint256 => bytes32) public editions;
    Counters.Counter public editionCounter;

    mapping(uint256 => Metadata) public tokensMetadata;
    mapping(uint256 => bytes32) public tokensName;
    mapping(uint256 => Images) public tokensImages;
    Counters.Counter public tokensMetadataCounter;

    event MetadataCreated(uint256 indexed id);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function createCardType(bytes32 name) external onlyRole(CREATOR_ROLE) {
        cardTypes[cardTypeCounter.current()] = name;
        cardTypeCounter.increment();
    }

    function createRarity(bytes32 name) external onlyRole(CREATOR_ROLE) {
        rarities[rarityCounter.current()] = name;
        rarityCounter.increment();
    }

    function createEdition(bytes32 name) external onlyRole(CREATOR_ROLE) {
        editions[editionCounter.current()] = name;
        editionCounter.increment();
    }

    function createMetadata(
        uint256 id,
        Metadata calldata metadata,
        bytes32 name,
        Images calldata images
    ) external onlyRole(CREATOR_ROLE) {
        tokensMetadataCounter.increment();
        require(id == tokensMetadataCounter.current(), "Invalid id");
        tokensMetadata[id] = metadata;
        tokensName[id] = name;
        tokensImages[id] = images;
        emit MetadataCreated(id);
    }

    function getMetadata(
        uint256 id
    ) external view returns (AltariusMetadata.Metadata memory) {
        return tokensMetadata[id];
    }

    function getName(uint256 id) external view returns (bytes32) {
        return tokensName[id];
    }

    function getImages(
        uint256 id
    ) external view returns (AltariusMetadata.Images memory) {
        return tokensImages[id];
    }

    function getMetadataLength() external view returns (uint256) {
        return tokensMetadataCounter.current();
    }

    function uri(uint256 id) external view returns (string memory) {
        Metadata memory metadata = tokensMetadata[id];
        bytes32 name = tokensName[id];
        Images memory images = tokensImages[id];
        require(name.length > 0, "Metadata not found");
        return _metadataUri(metadata, name, images);
    }

    function _metadataUri(
        Metadata memory metadata,
        bytes32 name,
        Images memory images
    ) private view returns (string memory) {
        string memory json = Base64.encode(
            bytes(
                string.concat(
                    '{"name":"',
                    _bytes32ToString(name),
                    '","image": "ipfs://',
                    string.concat(
                        _bytes32ToString(images.highCid1),
                        _bytes32ToString(images.highCid2)
                    ),
                    '","thumbnail": "ipfs://',
                    string.concat(
                        _bytes32ToString(images.thumbnailCid1),
                        _bytes32ToString(images.thumbnailCid2)
                    ),
                    '","square": "ipfs://',
                    string.concat(
                        _bytes32ToString(images.squareCid1),
                        _bytes32ToString(images.squareCid2)
                    ),
                    '",',
                    _attributesUri(metadata),
                    "}"
                )
            )
        );
        return string.concat("data:application/json;base64,", json);
    }

    function _attributesUri(
        Metadata memory metadata
    ) private view returns (string memory) {
        return
            string.concat(
                '"attributes": [',
                _attributeUri(
                    "Type",
                    _bytes32ToString(cardTypes[metadata.cardType]),
                    true,
                    true
                ),
                _attributeUri(
                    "Level",
                    Strings.toString(metadata.level),
                    false,
                    true
                ),
                _attributeUri(
                    "Rarity",
                    _bytes32ToString(rarities[metadata.rarity]),
                    true,
                    true
                ),
                _attributeUri(
                    "Edition",
                    _bytes32ToString(editions[metadata.edition]),
                    true,
                    true
                ),
                _attributeUri(
                    "Immortal",
                    metadata.immortal ? "true" : "false",
                    false,
                    true
                ),
                _attributeUri(
                    "Borderless",
                    metadata.borderless ? "true" : "false",
                    false,
                    true
                ),
                _attributeUri(
                    "Holographic",
                    metadata.holographic ? "true" : "false",
                    false,
                    true
                ),
                _pipsUri(metadata),
                "]"
            );
    }

    function _pipsUri(
        Metadata memory metadata
    ) private pure returns (string memory) {
        return
            string.concat(
                _attributeUri(
                    "Moon",
                    Strings.toString(metadata.moon),
                    false,
                    true
                ),
                _attributeUri(
                    "Sun",
                    Strings.toString(metadata.sun),
                    false,
                    true
                ),
                _attributeUri(
                    "Swift",
                    Strings.toString(metadata.swift),
                    false,
                    true
                ),
                _attributeUri(
                    "Strong",
                    Strings.toString(metadata.strong),
                    false,
                    true
                ),
                _attributeUri(
                    "Sorcerous",
                    Strings.toString(metadata.sorcerous),
                    false,
                    false
                )
            );
    }

    function _attributeUri(
        string memory traitType,
        string memory value,
        bool isString,
        bool trailingComma
    ) private pure returns (string memory) {
        return
            string.concat(
                '{"trait_type": "',
                traitType,
                '", "value": ',
                isString ? string.concat('"', value, '"') : value,
                "}",
                trailingComma ? "," : ""
            );
    }

    function _bytes32ToString(
        bytes32 data
    ) private pure returns (string memory) {
        uint i = 0;
        while (i < 32 && uint8(data[i]) != 0) {
            ++i;
        }
        bytes memory result = new bytes(i);
        i = 0;
        while (i < 32 && data[i] != 0) {
            result[i] = data[i];
            ++i;
        }
        return string(result);
    }
}