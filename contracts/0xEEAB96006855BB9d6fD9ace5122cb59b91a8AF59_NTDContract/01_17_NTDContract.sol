//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import {LicenseVersion, CantBeEvil} from "@a16z/contracts/licenses/CantBeEvil.sol";

contract NTDContract is
    ERC721,
    ERC721URIStorage,
    ERC721Enumerable,
    Ownable,
    CantBeEvil
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    //define variables to identify relations between tokenIDs, dates, names
    mapping(uint256 => uint256) public tokenIdToDate;
    mapping(uint256 => uint256) public dateToTokenId;
    mapping(uint256 => string) public dateToName;
    mapping(uint256 => string) public tokenIdToName;
    mapping(string => uint256) public NameToTokenId;
    mapping(string => uint256) public NameToDate;
    mapping(string => bool) public nameExists;
    mapping(uint256 => bool) public dateExists;

    //Events
    event newName(string _name, uint256 _tokenId, uint256 _blockNumber);

    event newDIP(uint256 _tokenId, uint256 _blockNumber);

    event newTokenURI(string _tokenURI, uint256 _tokenId);

    constructor()
        ERC721("NameTheDip", "NTD")
        CantBeEvil(LicenseVersion.CBE_NECR)
    {}

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(CantBeEvil, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Determines if the text is safe for use
     * @dev Each character is individually checked
     * @param str The string to interrogate
     * @return Boolean indicating if the text is safe only containing allowed characters & less than 31 characters
     */
    function isSafeName(string memory str) public pure returns (bool) {
        bytes memory b = bytes(str);
        if (b.length < 1) return false;
        if (b.length > 20) return false; // Cannot be longer than 25 characters
        if (b[0] == 0x20) return false; // Leading space
        if (b[b.length - 1] == 0x20) return false; // Trailing space

        bytes1 lastChar = b[0];

        for (uint256 i; i < b.length; i++) {
            bytes1 char = b[i];

            if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces

            if (
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x20) //space
            ) return false;

            lastChar = char;
        }

        return true;
    }

    /**
     *@notice Determines if the date is valid
     * @dev timeStamp is chronologically after last token and before current block timeStamp
     * @param date The date to interrogate
     * @return Boolean indicating if the text is safe only containing allowed characters & less than 31 characters
     */
    function isValidDate(uint256 date) public view returns (bool) {
        if (date <= tokenIdToDate[totalSupply() - 1]) return false;
        if (date >= block.timestamp) return false;

        return true;
    }

    /**
     * @notice Converts name to lowercase
     * @param str the name to interrogate
     * @return str the str with all characters converted to lowercase
     */
    function toLowercase(string memory str)
        public
        pure
        returns (string memory)
    {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint256 i = 0; i < bStr.length; i++) {
            // Uppercase character
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    /**
     * @dev
     */
    function nameTheDip(uint256 tokenId, string memory name) public {
        string memory proposedNameFormatted = toLowercase(name);
        require(!nameExists[proposedNameFormatted], "name has been used");
        require(
            ownerOf(tokenId) == msg.sender,
            "you are not the owner of the DIP"
        );
        require(isSafeName(name), "not a valid name");
        require(
            keccak256(abi.encodePacked(tokenIdToName[tokenId])) ==
                keccak256(abi.encodePacked("none")),
            "DIP is named"
        );
        tokenIdToName[tokenId] = name;
        NameToTokenId[name] = tokenId;
        nameExists[proposedNameFormatted] = true;
        emit newName(name, tokenId, block.number);
    }

    //assign URI after minting, can only be assigned once
    function addTokenURI(uint256 tokenId, string memory _tokenURI)
        public
        onlyOwner
    {
        require(
            keccak256(abi.encodePacked(tokenURI(tokenId))) ==
                keccak256(abi.encodePacked("none")),
            "TokenURI already exists"
        );
        _setTokenURI(tokenId, _tokenURI);
        emit newTokenURI(_tokenURI, tokenId);
    }

    //assing date after minting, can only be assigned once
    function assignTokenDate(uint256 tokenId, uint256 date) public onlyOwner {
        require(tokenIdToDate[tokenId] == 0, "Token already assigned date");
        require(!dateExists[date], "date already exists");
        require(isValidDate(date), "not a valid date");
        tokenIdToDate[tokenId] = date;
        NameToDate[tokenIdToName[tokenId]] = date;
        dateToName[date] = tokenIdToName[tokenId];
        dateToTokenId[date] = tokenId;
        dateExists[date] = true;
    }

    //mint NFT
    function mintNTD(address to) public onlyOwner {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        nameExists["none"] = true;
        tokenIdToName[newItemId] = "none";
        tokenIdToDate[newItemId] = 0;
        _safeMint(to, newItemId);
        _setTokenURI(newItemId, "none");
        emit newDIP(newItemId, block.number);
    }
}