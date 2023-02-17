// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC721Mintable {
    function safeMint(address to) external returns (uint256);
}