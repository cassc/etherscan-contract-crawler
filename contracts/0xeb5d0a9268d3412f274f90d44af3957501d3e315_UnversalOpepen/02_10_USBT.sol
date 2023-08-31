// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IERC165} from "./interfaces/IERC165.sol";
import {IERC721} from "./interfaces/IERC721.sol";
import {IERC721Metadata} from "./interfaces/IERC721Metadata.sol";
import {LibString} from "solady/utils/LibString.sol";

contract USBT is IERC721Metadata {
    using LibString for uint256;

    error AlreadyClaimed();
    error InvalidTokenId();
    error SoulboundToken();

    /// Bits Layout:
    /// - [0..1]   `claimed`
    /// - [1..2]   `burned`
    /// - [2..255] `extra`
    mapping(uint256 tokenId => uint256 packedData) internal _tokenData;

    string internal _name;
    string internal _symbol;

    uint256 public constant MAX_TOKEN_ID = type(uint160).max;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    modifier validTokenId(uint256 tokenId) {
        if (tokenId > MAX_TOKEN_ID) revert InvalidTokenId();

        uint256 tokenData = _tokenData[tokenId];
        if (tokenData & 1 == 0) revert InvalidTokenId();
        if (tokenData & 2 == 2) revert InvalidTokenId();

        _;
    }

    function _claim() internal virtual {
        uint256 tokenId = uint256(uint160(msg.sender));
        uint256 tokenData = _tokenData[tokenId];

        if (tokenData & 1 == 1) revert AlreadyClaimed();

        _beforeTokenTransfer(address(0), msg.sender, tokenId, 1);

        _tokenData[tokenId] = tokenData | 1;

        emit Transfer(address(0), msg.sender, tokenId);

        _afterTokenTransfer(address(0), msg.sender, tokenId, 1);
    }

    function _burn() internal virtual {
        uint256 tokenId = uint256(uint160(msg.sender));
        uint256 tokenData = _tokenData[tokenId];

        if (tokenData & 1 == 0) revert InvalidTokenId();
        if (tokenData & 2 == 2) revert InvalidTokenId();
        
        _beforeTokenTransfer(msg.sender, address(0), tokenId, 1);

        _tokenData[tokenId] = tokenData | 2;

        emit Transfer(msg.sender, address(0), tokenId);

        _afterTokenTransfer(msg.sender, address(0), tokenId, 1);
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}

    function _afterTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}

    //--------------------------------------//
    //          ERC721 METADATA             //
    //--------------------------------------//
    function name() external view virtual returns (string memory) {
        return _name;
    }

    function symbol() external view virtual returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) external view virtual validTokenId(tokenId) returns (string memory) {
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string.concat(baseURI, tokenId.toString()) : "";
    }

    //--------------------------------------//
    //              ERC721                  //
    //--------------------------------------//
    function balanceOf(address account) external view virtual returns (uint256) {
        uint256 tokenId = uint256(uint160(account));
        uint256 tokenData = _tokenData[tokenId];

        if (tokenData & 1 == 0) return 0;
        if (tokenData & 2 == 2) return 0;
        return 1;
    }

    function ownerOf(uint256 tokenId) external view virtual validTokenId(tokenId) returns (address) {
        return address(uint160(tokenId));
    }

    function safeTransferFrom(address, address, uint256 tokenId, bytes calldata) external view validTokenId(tokenId) {
        revert SoulboundToken();
    }

    function safeTransferFrom(address, address, uint256 tokenId) external view validTokenId(tokenId) {
        revert SoulboundToken();
    }

    function transferFrom(address, address, uint256 tokenId) external view validTokenId(tokenId) {
        revert SoulboundToken();
    }

    function approve(address, uint256 tokenId) external view validTokenId(tokenId) {
        revert SoulboundToken();
    }

    function setApprovalForAll(address, bool) external pure {
        revert SoulboundToken();
    }

    function getApproved(uint256 tokenId) external view validTokenId(tokenId) returns (address) {
        return address(0);
    }

    function isApprovedForAll(address, address) external pure returns (bool) {
        return false;
    }

    //--------------------------------------//
    //              ERC165                  //
    //--------------------------------------//
    function supportsInterface(bytes4 interfaceId) external view virtual returns (bool) {
        return type(IERC721Metadata).interfaceId == interfaceId || type(IERC721).interfaceId == interfaceId
            || type(IERC165).interfaceId == interfaceId;
    }
}