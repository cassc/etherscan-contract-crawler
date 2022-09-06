// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IERC721Descriptor {
    function tokenURI(address token, uint256 tokenId) external view returns (string memory);
}