// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IERC721} from "openzeppelin/token/ERC721/IERC721.sol";
import {IERC721Metadata} from "openzeppelin/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC165} from "openzeppelin/utils/introspection/IERC165.sol";

abstract contract NonTransferrableERC721 is IERC721, IERC721Metadata {
    string public override name;
    string public override symbol;

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _tokens;
    uint256 private _nextTokenId = 1;
    uint256 private _burnedTokenCount;

    error AlreadyMinted();
    error InvalidAddress();
    error InvalidTokenId();
    error NonTransferrable();

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function _mint(address to) internal {
        if (to == address(0)) revert InvalidAddress();
        if (_tokens[to] != 0) revert AlreadyMinted();

        unchecked {
            uint256 tokenId = _nextTokenId++;
            _owners[tokenId] = to;
            _tokens[to] = tokenId;

            emit Transfer(address(0), to, tokenId);
        }
    }

    function _burn(uint256 tokenId) internal {
        address owner = _owners[tokenId];
        if (owner == address(0)) revert InvalidTokenId();

        _owners[tokenId] = address(0);
        _tokens[owner] = 0;
        unchecked {
            _burnedTokenCount++;
        }

        emit Transfer(owner, address(0), tokenId);
    }

    function _burn(address owner) internal {
        uint256 tokenId = _tokens[owner];
        if (tokenId == 0) revert InvalidAddress();

        _owners[tokenId] = address(0);
        _tokens[owner] = 0;
        unchecked {
            _burnedTokenCount++;
        }

        emit Transfer(owner, address(0), tokenId);
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function supportsInterface(bytes4 interfaceID) external pure virtual override returns (bool) {
        return interfaceID == type(IERC165).interfaceId || interfaceID == type(IERC721).interfaceId
            || interfaceID == type(IERC721Metadata).interfaceId;
    }

    function balanceOf(address _owner) external view override returns (uint256) {
        if (_owner == address(0)) revert InvalidAddress();
        return _tokens[_owner] > 0 ? 1 : 0;
    }

    function ownerOf(uint256 _tokenId) external view override returns (address) {
        address owner = _owners[_tokenId];
        if (owner == address(0)) revert InvalidTokenId();
        return owner;
    }

    function safeTransferFrom(address, address, uint256) external pure override {
        revert NonTransferrable();
    }

    function safeTransferFrom(address, address, uint256, bytes calldata) external pure override {
        revert NonTransferrable();
    }

    function transferFrom(address, address, uint256) external pure override {
        revert NonTransferrable();
    }

    function approve(address, uint256) external pure override {
        revert NonTransferrable();
    }

    function setApprovalForAll(address, bool) external pure override {
        revert NonTransferrable();
    }

    function getApproved(uint256) external pure override returns (address) {
        revert NonTransferrable();
    }

    function isApprovedForAll(address, address) external pure override returns (bool) {
        return false;
    }

    function totalSupply() external view returns (uint256) {
        return _nextTokenId - 1 - _burnedTokenCount;
    }
}