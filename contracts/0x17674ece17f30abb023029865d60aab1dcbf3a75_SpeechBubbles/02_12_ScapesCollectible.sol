// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import "erc721a/contracts/ERC721A.sol";

import "./ScapesArchive.sol";

abstract contract ScapesCollectible is ERC721A, Ownable  {

    /// @notice The ScapesArchive, storing all Elements of ScapeLand
    address public archive;

    /// @dev Collection description
    string private _baseDescription;

    /// @dev We need to keep track of the token names, also to retreive the artwork from the Archive
    mapping(uint256 => string) internal _names;

    constructor(
        string memory name,
        string memory symbol,
        string memory description,
        address archive_
    )
        ERC721A(name, symbol)
    {
        _baseDescription = description;
        archive = archive_;
    }

    /// @notice Mint new items
    function mint(address to, string[] calldata names) external onlyOwner {
        for (uint256 index = _nextTokenId(); index < names.length; index++) {
            _names[index] = names[index];
        }

        _mint(to, names.length);
    }

    /// @notice Get the metadata for a given token ID
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory collection = symbol();
        string memory name = _names[tokenId];

        ScapesArchive.Element memory element = ScapesArchive(archive).getElement(collection, name);

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
            _name(tokenId),
            '","description":"',
            _description(tokenId),
            '",',
            _attributes(tokenId),
            '"image":"data:image/svg+xml;base64,',
            Base64.encode(bytes(svg)),
            '"}'
        );

        return string.concat(
            'data:application/json;base64,',
            Base64.encode(bytes(json))
        );
    }

    /// @dev Override this to add a custom name
    function _name(uint256 tokenId)
        internal virtual view
        returns (string memory)
    {
        return _names[tokenId];
    }

    /// @dev Override this to add a custom description
    function _description(uint256 tokenId)
        internal virtual view
        returns (string memory)
    {
        return _baseDescription;
    }

    /// @dev Override this to add custom attributes
    function _attributes(uint256 tokenId)
        internal virtual view
        returns (string memory)
    {
        return '';
    }

    /// @notice Mint a new item within the collection
    function setDescription(string memory description) public onlyOwner {
        _baseDescription = description;
    }
}