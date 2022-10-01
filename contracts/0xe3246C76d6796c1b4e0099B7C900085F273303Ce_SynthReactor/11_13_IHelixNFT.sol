// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

interface IHelixNFT {
    function setIsStaked(uint256 tokenId, bool isStaked) external;
    function getInfoForStaking(uint256 tokenId) external view returns(address tokenOwner, bool isStaked, uint256 wrappedNFTs);
   
}