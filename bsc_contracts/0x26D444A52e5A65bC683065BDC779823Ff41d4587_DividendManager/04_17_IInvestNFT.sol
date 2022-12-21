// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.14;


import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./IDepositary.sol";


interface IInvestNFT is IERC721Enumerable, IDepositary {}