// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./IOnChainMetadata.sol";
import "./MetadataUtils.sol";

interface WithTokenTypes {
    function tokenTypes(uint256 tokenId) external view returns (uint256);
}

contract PreRevealOnChainMetadata is IOnChainMetadata {
    using Strings for uint256;

    string internal _base64Data;

    string internal _name;
    string internal _description;
    string internal _external_url;
    string internal _background_color;

    constructor(
        string memory base64Data_,
        string memory name_,
        string memory description_,
        string memory external_url_,
        string memory background_color_
    ) {
        _base64Data = base64Data_;
        _name = name_;
        _description = description_;
        _external_url = external_url_;
        _background_color = background_color_;
    }

    function generateBase64(uint256 tokenId)
        external
        view
        returns (string memory)
    {
        return _base64Data;
    }

    function tokenImageDataURI(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        return
            string(abi.encodePacked("data:image/svg+xml;base64,", _base64Data));
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        string memory dataURI = MetadataUtils.tokenMetadataToString(
            TokenMetadata(
                _name,
                _description,
                tokenImageDataURI(tokenId),
                _external_url,
                _background_color,
                getAttributes(WithTokenTypes(msg.sender).tokenTypes(tokenId))
            )
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(bytes(dataURI))
                )
            );
    }

    function getAttributes(uint256 tokenType)
        internal
        view
        returns (Attribute[] memory attributes)
    {
        attributes = new Attribute[](1);
        if (tokenType == 0) {
            attributes = new Attribute[](0);
        } else if (tokenType == 1) {
            attributes[0] = Attribute("type", "The Chosen One");
        } else if (tokenType == 2) {
            attributes[0] = Attribute("type", "Unrevealed");
        } else if (tokenType == 3) {
            attributes[0] = Attribute("type", "Unrevealed");
        }
    }
}