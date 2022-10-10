// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface I721 is IERC721 {
    // function ownerOf(uint256 tokenId) external view returns (address);
    // function isOwnerOf(address, uint256) external view returns (bool);
    function mint(address player, uint256 cardId) external returns (uint256);

    function mintBatch(
        address player,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external returns (bool);

    function mintMulti(
        address player,
        uint256 cardId,
        uint256 amount
    ) external returns (uint256);

    function burn(uint256 id) external returns (bool);

    function burnMulti(uint256[] calldata ids) external returns (bool);

    function tokenToCard(uint256 tokenId) external view returns (uint256);
}