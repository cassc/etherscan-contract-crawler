//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { ERC721State, ERC721Storage } from "../../../storage/ERC721Storage.sol";
import "./IApproveLogic.sol";
import "../getter/IGetterLogic.sol";

// Functional logic extracted from openZeppelin:
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol
// To follow Extension principles, maybe best to separate each function into a different Extension
contract ApproveLogic is ApproveExtension {
    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = IGetterLogic(address(this)).ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _lastExternalCaller() == owner ||
                IGetterLogic(address(this)).isApprovedForAll(owner, _lastExternalCaller()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        // must use external call for _internal to resolve correctly
        IApproveLogic(address(this))._approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_lastExternalCaller(), operator, approved);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        ERC721State storage erc721State = ERC721Storage._getState();
        erc721State._operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) public virtual override _internal {
        ERC721State storage erc721State = ERC721Storage._getState();
        erc721State._tokenApprovals[tokenId] = to;
        emit Approval(IGetterLogic(address(this)).ownerOf(tokenId), to, tokenId);
    }
}