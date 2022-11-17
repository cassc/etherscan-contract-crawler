// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ILocker {
    function isLocked(uint256 tokenId) external view returns (bool);
}