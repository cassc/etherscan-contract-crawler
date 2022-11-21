// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IAnito {
    function safeMintSingle(address player, uint256 gachaCategory) external returns(uint256);
    function safeMint(address player,uint256 quantity, uint256 gachaCategory) external;
    function executeSummoning(address player, uint256 master1, uint256 master2, bool hasRarityStone, bool hasClassStone, bool hasStatStone) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function totalSupply() external view returns (uint256);
}