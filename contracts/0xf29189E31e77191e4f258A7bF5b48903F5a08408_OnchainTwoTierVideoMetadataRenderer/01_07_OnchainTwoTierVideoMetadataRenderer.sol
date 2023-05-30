// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Ownable} from "openzeppelin/access/Ownable.sol";
import {Strings} from "openzeppelin/utils/Strings.sol";
import {Base64} from "openzeppelin/utils/Base64.sol";

import "./IMetadataRenderer.sol";

interface IFunMint {
    function mintedSpecialByTokenId(uint256 tokenId) external view returns (bool isSpecial);
}

contract OnchainTwoTierVideoMetadataRenderer is IMetadataRenderer, Ownable {
    mapping(bool => string) public imageURIs;
    mapping(bool => string) public animationURIs;
    mapping(bool => string) public names;
    string private _description;

    constructor(
        string memory _defaultImageURI,
        string memory _premiumImageURI,
        string memory _defaultAnimationURI,
        string memory _premiumAnimationURI,
        string memory _desc,
        string memory _defaultName,
        string memory _premiumName
    ) {
        _description = _desc;
        imageURIs[false] = _defaultImageURI;
        imageURIs[true] = _premiumImageURI;
        animationURIs[false] = _defaultAnimationURI;
        animationURIs[true] = _premiumAnimationURI;
        names[false] = _defaultName;
        names[true] = _premiumName;
    }

    function _renderAttributes(bool isSpecial) internal pure returns (string memory) {
        string[] memory keys = new string[](1);
        keys[0] = "machine";

        string[] memory values = new string[](1);
        values[0] = isSpecial ? "gold" : "pink";

        string memory attributes = "[";
        string memory separator = ",";

        for (uint256 i = 0; i < keys.length; i++) {
            if (i == keys.length - 1) {
                separator = "]";
            }

            attributes = string(
                abi.encodePacked(
                    attributes, "{\"trait_type\": \"", keys[i], "\", \"value\": \"", values[i], "\"}", separator
                )
            );
        }

        return attributes;
    }

    function tokenURIJSON(uint256 tokenID) public view returns (string memory) {
        // We can use msg.sender here as this is intended to be called by the NFT contract
        bool isSpecial = IFunMint(msg.sender).mintedSpecialByTokenId(tokenID);
        string memory imageURI = imageURIs[isSpecial];
        string memory animationURI = animationURIs[isSpecial];
        string memory name = names[isSpecial];

        return string(
            abi.encodePacked(
                "{",
                '"name": "',
                name,
                " #",
                Strings.toString(tokenID),
                '",',
                '"description": "',
                _description,
                '",',
                '"image": "',
                imageURI,
                '","animation_url": "',
                animationURI,
                '","attributes":',
                _renderAttributes(isSpecial),
                "}"
            )
        );
    }

    function tokenURI(uint256 tokenID) public view override returns (string memory) {
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(tokenURIJSON(tokenID)))));
    }

    function setImageUris(string memory _default, string memory _premium) external onlyOwner {
        imageURIs[false] = _default;
        imageURIs[true] = _premium;
    }

    function setAnimationUris(string memory _default, string memory _premium) external onlyOwner {
        animationURIs[false] = _default;
        animationURIs[true] = _premium;
    }

    function setDescription(string memory _newDescription) external onlyOwner {
        _description = _newDescription;
    }
}