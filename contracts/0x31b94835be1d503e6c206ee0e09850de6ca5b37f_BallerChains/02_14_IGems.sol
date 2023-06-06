// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

interface IGems is IERC721Enumerable {
    function burn(uint256 _tokenId) external;
}