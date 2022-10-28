//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

interface INichoNFTRewards {
    
    function mintRewards(address tokenAddress, string memory tokenURI, uint256 tokenId, address userAddress, uint256 price, uint256 timestamp) external returns (bool);

    function tradeRewards(address tokenAddress, uint256 tokenId, address userAddress, uint256 timestamp) external returns (bool);

}