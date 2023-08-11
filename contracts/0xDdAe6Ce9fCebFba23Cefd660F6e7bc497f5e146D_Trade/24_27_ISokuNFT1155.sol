// SPDX-License-Identifier:UNLICENSED
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface ISokuNFT1155 is IERC1155 {
    function owner() external returns (address);
}