// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IPolymorphRoot is IERC721 {
    function mint() external payable;

    function bulkBuy(uint256 amount) external payable;
}