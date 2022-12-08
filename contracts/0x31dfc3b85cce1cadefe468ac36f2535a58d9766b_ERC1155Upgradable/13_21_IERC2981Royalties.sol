// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IERC2981Royalties {
   function setTokenRoyalty(uint256 tokenId, address recipient, uint256 value) external;
   function royaltyInfo(uint256 tokenId, uint256 value) external view returns (address receiver, uint256 royaltyAmount);
}