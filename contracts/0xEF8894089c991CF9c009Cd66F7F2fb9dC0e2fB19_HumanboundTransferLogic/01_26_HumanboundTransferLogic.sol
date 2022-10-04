// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "../EAT/AccessTokenConsumerExtension.sol";
import "./IHumanboundTransferLogic.sol";

contract HumanboundTransferLogic is HumanboundTransferExtension, AccessTokenConsumerExtension {
    /**
     * @dev See {ITransferLogic-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        revert("HumanboundTransferLogic-transferFrom: disallowed without EAT");
    }

    /**
     * @dev See {ITransferLogic-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        revert("HumanboundTransferLogic-safeTransferFrom: disallowed without EAT");
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
        revert("HumanboundTransferLogic-safeTransferFrom: disallowed without EAT");
    }

    function transferFrom(
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 expiry,
        address from,
        address to,
        uint256 tokenId
    ) public override(IHumanboundTransferLogic) requiresAuth(v, r, s, expiry) {
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 expiry,
        address from,
        address to,
        uint256 tokenId
    ) public override(IHumanboundTransferLogic) requiresAuth(v, r, s, expiry) {
        _safeTransfer(from, to, tokenId, "");
    }

    function safeTransferFrom(
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 expiry,
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(IHumanboundTransferLogic) requiresAuth(v, r, s, expiry) {
        _safeTransfer(from, to, tokenId, data);
    }
}