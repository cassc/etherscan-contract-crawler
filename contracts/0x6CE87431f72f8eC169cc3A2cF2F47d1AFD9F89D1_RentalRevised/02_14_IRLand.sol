// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IRLand is IERC721Upgradeable{
    function getTokenId(uint256 x, uint256 y) external view returns (uint256);
}