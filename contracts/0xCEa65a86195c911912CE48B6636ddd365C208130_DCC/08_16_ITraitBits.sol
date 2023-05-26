// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/IERC721A.sol";

interface ITraitBits {
    function getTraitBits(uint256 _tokenId) external view returns (uint256);
    function getTraitBitsMemoized(uint256 _tokenId) external view returns (uint256);
    function memoizeTraitBits(uint256 _tokenId) external returns (uint256);
}