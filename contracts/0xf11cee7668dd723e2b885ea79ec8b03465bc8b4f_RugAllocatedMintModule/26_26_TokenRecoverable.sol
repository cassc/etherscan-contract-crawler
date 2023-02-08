// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Administrable} from "src/contracts/utils/Administrable/Administrable.sol";
import {ITokenRecoverable} from "./ITokenRecoverable.sol";

/**
 * @title TokenRecoverable
 * @author Syndicate Inc.
 * @custom:license MIT license. Copyright (c) 2021-present Syndicate Inc.
 *
 * Token recovery utility allowing ERC20 and ERC721 tokens erroneously sent to
 * the contract to be returned.
 */
abstract contract TokenRecoverable is Administrable, ITokenRecoverable {
    // Using safeTransfer since interacting with other ERC20s
    using SafeERC20 for IERC20;

    /**
     * Initializes `TokenRecoverable` with a passed-in address as the first
     * admin.
     *
     * Emits an `AdminGranted` event.
     *
     * @dev Unlike `TokenRecoverableUpgradeable`'s initializer, this
     * constructor does NOT take an `admin_` argument, and instead confers
     * admin status on the caller.
     */
    constructor(address admin_) {
        _grantAdmin(admin_);
    }

    /**
     * Transfers ERC20 tokens erroneously sent to the contract.
     *
     * Emits a `TokenRecoveredERC20` event.
     *
     * Requirements:
     * - The caller must be the admin.
     * - `recipient` cannot be the zero address.
     * - This contract must have a balance in `erc20` of at least `amount`.
     * @param recipient Address that erroneously sent the ERC20 token(s)
     * @param erc20 Erroneously-sent ERC20 token to recover
     * @param amount Amount to recover
     */
    function recoverERC20(
        address recipient,
        address erc20,
        uint256 amount
    ) external onlyAdmin {
        IERC20(erc20).safeTransfer(recipient, amount);
        emit TokenRecoveredERC20(recipient, erc20, amount);
    }

    /**
     * Transfers ERC721 tokens erroneously sent to the contract.
     *
     * Emits a `TokenRecoveredERC721` event.
     *
     * Requirements:
     * - The caller must be the admin.
     * - `recipient` cannot be the zero address.
     * - `tokenId` must exist in `erc721`.
     * - `tokenId` in `erc721` must be owned by this contract.
     * @param recipient Address that erroneously sent the ERC721 token
     * @param erc721 Erroneously-sent ERC721 token to recover
     * @param tokenId The tokenId to recover
     */
    function recoverERC721(
        address recipient,
        address erc721,
        uint256 tokenId
    ) external onlyAdmin {
        IERC721(erc721).transferFrom(address(this), recipient, tokenId);
        emit TokenRecoveredERC721(recipient, erc721, tokenId);
    }
}