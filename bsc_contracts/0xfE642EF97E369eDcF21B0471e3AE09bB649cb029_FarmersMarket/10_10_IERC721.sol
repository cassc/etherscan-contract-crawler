// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC721 {
    function safeMint(address to, string memory tokenURI) external;
}