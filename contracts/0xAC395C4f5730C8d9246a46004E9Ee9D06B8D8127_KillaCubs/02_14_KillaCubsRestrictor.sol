// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./KillaCubsStaking.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract KillaCubsRestrictor is KillaCubsStaking, DefaultOperatorFilterer {
    constructor(
        address bitsAddress,
        address gearAddress,
        address superOwner
    ) KillaCubsStaking(bitsAddress, gearAddress, superOwner) {}

    bool public restricted = true;

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override {
        if (restricted) {
            setApprovalForAllRestricted(operator, approved);
        } else {
            super.setApprovalForAll(operator, approved);
        }
    }

    function approve(address operator, uint256 tokenId) public override {
        if (restricted) {
            approveRestricted(operator, tokenId);
        } else {
            super.approve(operator, tokenId);
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        if (restricted) {
            transferFromRestricted(from, to, tokenId);
        } else {
            super.transferFrom(from, to, tokenId);
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        if (restricted) {
            safeTransferFromRestricted(from, to, tokenId);
        } else {
            super.safeTransferFrom(from, to, tokenId);
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override {
        if (restricted) {
            safeTransferFromRestricted(from, to, tokenId);
        } else {
            super.safeTransferFrom(from, to, tokenId, data);
        }
    }

    function setApprovalForAllRestricted(
        address operator,
        bool approved
    ) public onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approveRestricted(
        address operator,
        uint256 tokenId
    ) public onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFromRestricted(
        address from,
        address to,
        uint256 tokenId
    ) public onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFromRestricted(
        address from,
        address to,
        uint256 tokenId
    ) public onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFromRestricted(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}