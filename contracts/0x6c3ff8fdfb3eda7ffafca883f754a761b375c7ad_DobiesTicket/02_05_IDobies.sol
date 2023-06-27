// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IDobies {
    function isOwnerOf(address account, uint256[] calldata tokenIds)
        external
        view
        returns (bool);

    function walletOfOwner(address owner)
        external
        view
        returns (uint256[] memory);
}