// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

 abstract contract IMigration is IERC721{
    function mint(address to,uint256 tokenId) external{}
    function isClaimed(uint tokenId) external view returns(bool tokenExists){}
}