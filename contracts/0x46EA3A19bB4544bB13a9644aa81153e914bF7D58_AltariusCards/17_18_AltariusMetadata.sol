// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./libs/Base64.sol";

contract AltariusMetadata is AccessControl {
    using Counters for Counters.Counter;

    struct Metadata {
        string name;
        string highCid;
        string thumbnailCid;
        string squareCid;
        string cardType;
        string rarity;
        string edition;
        bool immortal;
        bool borderless;
        bool holographic;
        uint232 level;
        Pips pips;
    }

    struct Pips {
        uint48 moon;
        uint48 sun;
        uint48 swift;
        uint48 strong;
        uint48 sorcerous;
    }

    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");

    mapping(uint256 => Metadata) public tokensMetadata;
    Counters.Counter public tokensMetadataCounter;

    event MetadataCreated(uint256 indexed id, string name);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function createMetadata(
        Metadata calldata metadata
    ) external onlyRole(CREATOR_ROLE) {
        tokensMetadataCounter.increment();
        tokensMetadata[tokensMetadataCounter.current()] = metadata;
        emit MetadataCreated(tokensMetadataCounter.current(), metadata.name);
    }

    function getMetadata(
        uint256 id
    ) external view returns (AltariusMetadata.Metadata memory) {
        return tokensMetadata[id];
    }

    function getMetadataLength() external view returns (uint256) {
        return tokensMetadataCounter.current();
    }

    function uri(uint256 id) external view returns (string memory) {
        Metadata memory metadata = tokensMetadata[id];
        require(bytes(metadata.name).length > 0, "Metadata not found");
        return _metadataUri(tokensMetadata[id]);
    }

    function _metadataUri(
        Metadata memory metadata
    ) private pure returns (string memory) {
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name":"',
                        metadata.name,
                        '","image": "ipfs://',
                        metadata.highCid,
                        '","thumbnail": "ipfs://',
                        metadata.thumbnailCid,
                        '","square": "ipfs://',
                        metadata.squareCid,
                        '",',
                        _attributesUri(metadata),
                        "}"
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function _attributesUri(
        Metadata memory metadata
    ) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '"attributes": [',
                    _attributeUri("Type", metadata.cardType, true, true),
                    _attributeUri("Rarity", metadata.rarity, true, true),
                    _attributeUri("Edition", metadata.edition, true, true),
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
                    _attributeUri(
                        "Level",
                        Strings.toString(metadata.level),
                        false,
                        true
                    ),
                    _pipsUri(metadata.pips),
                    "]"
                )
            );
    }

    function _pipsUri(Pips memory pips) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    _attributeUri(
                        "Moon",
                        Strings.toString(pips.moon),
                        false,
                        true
                    ),
                    _attributeUri(
                        "Sun",
                        Strings.toString(pips.sun),
                        false,
                        true
                    ),
                    _attributeUri(
                        "Swift",
                        Strings.toString(pips.swift),
                        false,
                        true
                    ),
                    _attributeUri(
                        "Strong",
                        Strings.toString(pips.strong),
                        false,
                        true
                    ),
                    _attributeUri(
                        "Sorcerous",
                        Strings.toString(pips.sorcerous),
                        false,
                        false
                    )
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
            string(
                abi.encodePacked(
                    '{"trait_type": "',
                    traitType,
                    '", "value": ',
                    isString
                        ? string(abi.encodePacked('"', value, '"'))
                        : value,
                    "}",
                    trailingComma ? "," : ""
                )
            );
    }
}