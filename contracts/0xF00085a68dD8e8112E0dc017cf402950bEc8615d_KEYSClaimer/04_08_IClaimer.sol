// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

interface IClaimer {
    function registerToken(uint256 tokenId) external;
}