//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IERC721GalaMintableBurnable is IERC721 {
    function mint(address owner, uint256 tokenId) external;

    function safeMint(address owner, uint256 tokenId) external;

    function burn(uint256 tokenId) external;
}