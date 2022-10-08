// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IKaijuKingz is IERC721 {
    function totalSupply() external view returns (uint256);
    function babyCount() external view returns (uint256);
    function maxGenCount() external view returns (uint256);
    function maxSupply() external view returns (uint256);
    function fusion(uint256 parent1, uint256 parent2) external;
}