// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// ownable
import "@openzeppelin/contracts/access/Ownable.sol";

import "./IOnChainMetadata.sol";
import "./MetadataUtils.sol";

interface WithTokenTypes {
    function tokenTypes(uint256 tokenId) external view returns (uint256);
}

interface WithRandom {
    function randomNumber() external view returns (uint256);

    function generateBase64(uint256 tokenId)
        external
        view
        returns (string memory);
}

contract PostRevealOnChainMetadata is IOnChainMetadata, Ownable {
    using Strings for uint256;

    string internal _glitchedBase64Data;
    string internal _name;
    string internal _description;
    string internal _external_url;
    string internal _background_color;

    WithRandom internal randomContract;

    constructor(
        string memory glitchedBase64Data_,
        string memory name_,
        string memory description_,
        string memory external_url_,
        string memory background_color_,
        WithRandom randomContract_
    ) {
        _glitchedBase64Data = glitchedBase64Data_;
        _name = name_;
        _description = description_;
        _external_url = external_url_;
        _background_color = background_color_;

        randomContract = randomContract_;
    }

    function generateBase64() public view returns (string memory) {
        return randomContract.generateBase64(0);
    }

    function generateBase64Glitched() external view returns (string memory) {
        return _glitchedBase64Data;
    }

    function tokenImageDataURI(uint256 tokenId, uint256 tokenType)
        public
        view
        returns (string memory)
    {
        if (isGlitched(tokenId, tokenType))
            return
                string(
                    abi.encodePacked(
                        "data:image/svg+xml;base64,",
                        _glitchedBase64Data
                    )
                );
        return
            string(
                abi.encodePacked("data:image/svg+xml;base64,", generateBase64())
            );
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        string memory dataURI = MetadataUtils.tokenMetadataToString(
            TokenMetadata(
                _name,
                _description,
                tokenImageDataURI(
                    tokenId,
                    WithTokenTypes(msg.sender).tokenTypes(tokenId)
                ),
                _external_url,
                _background_color,
                getAttributes(
                    tokenId,
                    WithTokenTypes(msg.sender).tokenTypes(tokenId)
                )
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

    function getAttributes(uint256 tokenId, uint256 tokenType)
        internal
        view
        returns (Attribute[] memory attributes)
    {
        bool glitched = isGlitched(tokenId, tokenType);

        if (glitched) {
            attributes = new Attribute[](2);
            if (tokenType == 0) {
                attributes = new Attribute[](0);
            } else if (tokenType == 1) {
                attributes[0] = Attribute("Class", "The Chosen One");
                attributes[1] = Attribute("State ", "Corrupted");
            } else if (tokenType == 2) {
                attributes[0] = Attribute("Class", "Free Mintooor");
                attributes[1] = Attribute("State ", "Corrupted");
            } else if (tokenType == 3) {
                attributes[0] = Attribute("Class", "Big Money Spendooor");
                attributes[1] = Attribute("State ", "Corrupted");
            }
        } else {
            attributes = new Attribute[](2);
            if (tokenType == 0) {
                attributes = new Attribute[](0);
            } else if (tokenType == 1) {
                attributes[0] = Attribute("Class", "The Chosen One");
                attributes[1] = Attribute("State ", "Rugged");
            } else if (tokenType == 2) {
                attributes[0] = Attribute("Class", "Free Mintooor");
                attributes[1] = Attribute("State ", "Rugged");
            } else if (tokenType == 3) {
                attributes[0] = Attribute("Class", "Big Money Spendooor");
                attributes[1] = Attribute("State ", "Rugged");
            }
        }
    }

    function randomNumber() public view returns (uint256) {
        return randomContract.randomNumber();
    }

    function isGlitched(uint256 tokenId, uint256 tokenType)
        internal
        view
        returns (bool)
    {
        require(randomNumber() != 0, "Random number not yet generated");
        return
            (tokenId == 0)
                ? true
                : uint256(
                    keccak256(
                        abi.encodePacked(tokenId, tokenType, randomNumber())
                    )
                ) %
                    100 ==
                    0;
    }

    function setName(string memory name_) external onlyOwner {
        _name = name_;
    }

    function setDescription(string memory description_) external onlyOwner {
        _description = description_;
    }

    function setbackground_color(string memory background_color_)
        external
        onlyOwner
    {
        _background_color = background_color_;
    }

    function setExternalUrl(string memory external_url_) external onlyOwner {
        _external_url = external_url_;
    }

    function setGlitchedBase64Data(string memory glitchedBase64Data_)
        external
        onlyOwner
    {
        _glitchedBase64Data = glitchedBase64Data_;
    }
}