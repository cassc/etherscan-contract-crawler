// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;
interface INewDefinaCard {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function heroIdMap(uint tokenId_) external view returns (uint);

    function rarityMap(uint tokenId_) external view returns (uint);
}