// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

interface ITopDogBeachClub is IERC721Enumerable {
    function getBirthday(uint256 tokenId) external view returns (uint256);
}