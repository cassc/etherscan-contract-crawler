// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import "erc721a/contracts/ERC721A.sol";

import "./ScapesArchive.sol";

contract ScapeElements is ERC721A, Ownable {

    address public archiveAddress;

    struct ElementReference {
        string category;
        string name;
    }

    mapping(uint256 => ElementReference) private _data;
    string private _description;

    constructor(address archiveAddress_) ERC721A("Scape Elements", "ELEMENTS") {
        archiveAddress = archiveAddress_;
    }

    /// @notice Mint new elements
    function mint(address to, ElementReference[] calldata elements) external onlyOwner {
        for (uint256 index = _nextTokenId(); index < elements.length; index++) {
            _data[index] = elements[index];
        }

        _mint(to, elements.length);
    }

    /// @notice Get the metadata for a given token ID
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        ElementReference memory elementReference = _data[tokenId];
        ScapesArchive.Element memory element = ScapesArchive(archiveAddress).getElement(
            elementReference.category, elementReference.name
        );

        string memory svg = string.concat(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ',
            Strings.toString(element.metadata.width),
            ' ',
            Strings.toString(element.metadata.height),
            '" height="100%" width="100%" style="image-rendering: pixelated"><image width="',
            Strings.toString(element.metadata.width),
            '" height="',
            Strings.toString(element.metadata.height),
            '" href="data:image/png;base64,',
            Base64.encode(element.data),
            '"/></svg>'
        );

        string memory json = string.concat(
            '{"name":"',
            elementReference.name,
            '","description":"',
            _description,
            '","attributes":[{"trait_type":"Category", "value":"',
            elementReference.category,
            '"}],"image":"data:image/svg+xml;base64,',
            Base64.encode(bytes(svg)),
            '"}'
        );

        return string.concat(
            'data:application/json;base64,',
            Base64.encode(bytes(json))
        );
    }

    /// @notice Set the description of the collection
    function setDescription(string memory description) public onlyOwner {
        _description = description;
    }
}