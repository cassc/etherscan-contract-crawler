// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { IERC721 } from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

abstract contract Hand is IERC721 {}

abstract contract Honor is IERC721, ERC165 {
    string private _name;
    string private _symbol;
    uint private _total;

    mapping(address => uint) private _balances;
    mapping(uint => address) private _owners;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() external view returns (string memory) {
        return _name;
    }
    
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function totalSupply() external view returns (uint) {
        return _total;
    }

    function balanceOf(address owner) external view returns (uint) {
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        return _owners[tokenId];
    }
    
    function _mint(address to) internal returns (uint) {
        require(to != address(0), "Honor is not yours");

        _total += 1;
        _balances[to] += 1;
        _owners[_total] = to;

        emit Transfer(address(0), to, _total);

        return _total;
    }

    function _exists(uint tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }
}

abstract contract Sacrifice is IERC721 {
    function safeTransferFrom(address, address, uint256, bytes calldata) pure external {
        revert("Honor is not transferable");
    }

    function safeTransferFrom(address, address, uint256) pure external {
        revert("Honor is not transferable");
    }

    function transferFrom(address, address, uint256) pure external {
        revert("Honor is not transferable");
    }

    function approve(address, uint256) pure external {
        revert("Honor is not for sale");
    }

    function getApproved(uint256) pure external returns (address) {
        revert("Honor is not for sale");
    }

    function setApprovalForAll(address, bool) pure external  {
        revert("Honor is not for sale");
    }

    function isApprovedForAll(address, address) pure external returns (bool) {
        return false;
    }
}