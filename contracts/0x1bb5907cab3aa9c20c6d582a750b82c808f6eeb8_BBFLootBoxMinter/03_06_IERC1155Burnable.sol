// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC1155Burnable {
    function burn(address from, uint256 id, uint256 amount) external;
    function batchBurn(address from, uint256[] memory ids, uint256[] memory amounts) external;
}