// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface ILocker {
    function isLocked(address collectionAddress, uint256 tokenId)
        external
        view
        returns (bool);
}