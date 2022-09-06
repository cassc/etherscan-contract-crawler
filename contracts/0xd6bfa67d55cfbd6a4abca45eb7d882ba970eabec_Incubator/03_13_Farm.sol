// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IERC721} from "openzeppelin/token/ERC721/IERC721.sol";

interface Chicken is IERC721 {}

interface Egg is IERC721 {
    function burn(uint256 tokenId) external;
}