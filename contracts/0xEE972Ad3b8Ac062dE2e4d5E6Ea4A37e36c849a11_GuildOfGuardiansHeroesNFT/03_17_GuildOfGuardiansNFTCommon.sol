// contracts/GuildOfGuardiansNFTCommon.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./interfaces/Mintable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract GuildOfGuardiansNFTCommon is
    AccessControl,
    ERC721URIStorage,
    Mintable
{
    string public standard = "Guild of Guardians";
    mapping(uint256 => uint16) protos;
    mapping(uint256 => uint256) serialNumbers;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant SET_URI_ROLE = keccak256("SET_URI_ROLE");

    event SetTokenURI(uint256 tokenId, string tokenURI);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(SET_URI_ROLE, msg.sender);
    }

    function setTokenURI(uint256 tokenId, string memory tokenURI) external {
        require(hasRole(SET_URI_ROLE, msg.sender), "Caller is not URI setter");
        require(
            bytes(super.tokenURI(tokenId)).length == 0,
            "Token URI already set"
        );
        _setTokenURI(tokenId, tokenURI);
        emit SetTokenURI(tokenId, tokenURI);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _mintCommon(
        address to,
        uint256 tokenId,
        string memory tokenURI,
        uint16 proto,
        uint256 serialNumber
    ) internal {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not minter");
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
        protos[tokenId] = proto;
        serialNumbers[tokenId] = serialNumber;
    }
}