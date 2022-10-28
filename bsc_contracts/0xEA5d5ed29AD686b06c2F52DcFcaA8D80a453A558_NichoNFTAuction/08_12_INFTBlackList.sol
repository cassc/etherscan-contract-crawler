// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

// Interface for NFTBlackList
interface INFTBlackList {
    function checkBlackList(address tokenAddress, uint256 tokenId) external view returns(bool);
}