// contracts/MyNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import "erc721a/contracts/extensions/IERC721AQueryable.sol";

interface INuoPass is IERC721AQueryable {
    function burn(uint256 tokenId,address _user) external;
    
}