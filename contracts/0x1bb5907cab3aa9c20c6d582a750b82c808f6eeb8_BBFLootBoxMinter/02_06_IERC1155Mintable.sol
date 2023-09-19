// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC1155Mintable {
    function mint(address to, uint256 id, uint256 amount) external;
    function batchMint(address to, uint256[] memory ids, uint256[] memory amounts) external;
}