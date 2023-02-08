// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IMetadata.sol";
import "./Base64.sol";

contract MetadataV1 is IMetadata, Ownable {
    using Strings for uint256;

    struct Metadata {
        string name;
        string description;
        string image;
    }

    mapping(uint256 => Metadata) public tokensMetadata;

    function setMetadataForToken(
        uint256 _tokenId,
        string memory _name,
        string memory _description,
        string memory _image
    ) external onlyOwner {
        tokensMetadata[_tokenId] = Metadata(_name, _description, _image);
    }

    function getTokenURI(uint256 _tokenId)
        external
        view
        returns (string memory uri)
    {
        require(
            bytes(tokensMetadata[_tokenId].name).length != 0,
            "No data defined for the given tokenId"
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                tokensMetadata[_tokenId].name,
                                '", "image": "',
                                tokensMetadata[_tokenId].image,
                                '","description":"',
                                tokensMetadata[_tokenId].description,
                                '"}'
                            )
                        )
                    )
                )
            );
    }
}