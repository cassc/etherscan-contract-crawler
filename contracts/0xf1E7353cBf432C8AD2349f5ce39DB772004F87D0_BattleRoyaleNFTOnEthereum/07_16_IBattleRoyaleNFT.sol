pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT
pragma abicoder v2;
//import "../lib/forge-std/src/console.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IBattleRoyaleNFT is IERC721Enumerable {
    function tokenType(uint tokenId) external view returns (uint);
    function tokenProperty(uint tokenId) external view returns (uint);
    function nextTokenId() external view returns (uint);

    function burn(uint256 tokenId) external;

    function setProperty(uint tokenId, uint newProperty) external;
    function mintByGame(address to, uint property) external returns (uint);

    function games() external view returns (address[] memory);
}