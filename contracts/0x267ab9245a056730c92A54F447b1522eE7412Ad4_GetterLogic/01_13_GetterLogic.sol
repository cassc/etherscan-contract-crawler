//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import { ERC721State, ERC721Storage } from "../../../storage/ERC721Storage.sol";
import "./IGetterLogic.sol";

// Functional logic extracted from openZeppelin:
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol
// To follow Extension principles, maybe best to separate each function into a different Extension
contract GetterLogic is GetterExtension {
    using Address for address;
    using Strings for uint256;

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        ERC721State storage erc721State = ERC721Storage._getState();
        return erc721State._balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public virtual override returns (address) {
        ERC721State storage erc721State = ERC721Storage._getState();
        address owner = erc721State._owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public virtual override returns (address) {
        require(IGetterLogic(address(this))._exists(tokenId), "ERC721: approved query for nonexistent token");
        ERC721State storage erc721State = ERC721Storage._getState();

        return erc721State._tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        ERC721State storage erc721State = ERC721Storage._getState();
        return erc721State._operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IGetterLogic-_exists}.
     */
    function _exists(uint256 tokenId) public override _internal returns (bool) {
        ERC721State storage erc721State = ERC721Storage._getState();
        return erc721State._owners[tokenId] != address(0);
    }

    /**
     * @dev See {IGetterLogic-_isApprovedOrOwner}.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) public virtual override _internal returns (bool) {
        require(IGetterLogic(address(this))._exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || spender == getApproved(tokenId) || isApprovedForAll(owner, spender));
    }
}