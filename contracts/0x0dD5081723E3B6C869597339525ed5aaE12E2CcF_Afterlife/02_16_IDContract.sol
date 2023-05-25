// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IDContract is IERC721 {

    function burnForAfterlife(uint256 tokenId) external;
}