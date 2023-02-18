// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IBAGC {
    function isUserToken(uint256 tokenId) external returns (bool);
}