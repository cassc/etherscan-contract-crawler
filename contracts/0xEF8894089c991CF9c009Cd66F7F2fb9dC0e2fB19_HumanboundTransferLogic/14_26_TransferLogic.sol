//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import { ERC721State, ERC721Storage } from "../../../storage/ERC721Storage.sol";
import { RoleState, Permissions } from "@violetprotocol/extendable/storage/PermissionStorage.sol";
import "../getter/IGetterLogic.sol";
import "../receiver/IOnReceiveLogic.sol";
import "../approve/IApproveLogic.sol";
import "../hooks/IERC721Hooks.sol";
import "./ITransferLogic.sol";
import "../Events.sol";

// Functional logic extracted from openZeppelin:
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol
contract TransferLogic is TransferExtension, Events {
    using Address for address;
    using Strings for uint256;

    /**
     * @dev See {ITransferLogic-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(
            IGetterLogic(address(this))._isApprovedOrOwner(_lastExternalCaller(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {ITransferLogic-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {ITransferLogic-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            IGetterLogic(address(this))._isApprovedOrOwner(_lastExternalCaller(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract,
     *      it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            IOnReceiveLogic(address(this))._checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(IGetterLogic(address(this)).ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        IERC721Hooks(address(this))._beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        IApproveLogic(address(this))._approve(address(0), tokenId);

        ERC721State storage erc721State = ERC721Storage._getState();
        erc721State._balances[from] -= 1;
        erc721State._balances[to] += 1;
        erc721State._owners[tokenId] = to;

        emit Events.Transfer(from, to, tokenId);

        IERC721Hooks(address(this))._afterTokenTransfer(from, to, tokenId);
    }
}