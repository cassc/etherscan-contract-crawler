// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;
interface IDefinaCard {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function cardInfoes(uint cardId_) external returns (uint cardId, uint camp, uint rarity, string memory name, uint currentAmount, uint maxAmount, string memory cardURI);

    function cardIdMap(uint tokenId_) external view returns (uint);
}