//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.11;

import "./IERC721A.sol";

interface ITheNFTIslands is IERC721A {
    function getTokenType(uint256 tokenId) external view returns (uint256);
}