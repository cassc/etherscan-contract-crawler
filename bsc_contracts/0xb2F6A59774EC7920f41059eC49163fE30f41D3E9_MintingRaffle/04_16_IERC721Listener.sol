// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721Listener {
    function beforeTokenTransfer(address from, address to, uint256 tokenId) external;
    function afterTokenTransfer(address from, address to, uint256 tokenId) external;
}