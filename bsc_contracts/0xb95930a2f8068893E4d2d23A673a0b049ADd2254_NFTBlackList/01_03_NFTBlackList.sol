/**
 * Submitted for verification at BscScan.com on 2022-09-28
 */

// File: contracts/NFTBlackList.sol
// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTBlackList is Ownable {
    // Token address => Token ID => True/False indicates if NFT is in blacklist or not
    mapping (address=>mapping(uint256 => bool)) blacklist;

    // Token address, Token ID, True/False indicates if NFT is in blacklist or not
    event UpdateBlackList(address token_address, uint256 token_id, bool in_blacklist);

    // add NFT into blacklist
    function addBlackList(address tokenAddress, uint256 tokenId) external onlyOwner {
        require(blacklist[tokenAddress][tokenId] == false, "BlackList: already exist in blacklist");
        blacklist[tokenAddress][tokenId] = true;

        emit UpdateBlackList(tokenAddress, tokenId, true);
    }

    // remove NFT from blacklist
    function removeBlackList(address tokenAddress, uint256 tokenId) external onlyOwner {
        require(blacklist[tokenAddress][tokenId], "BlackList: not exist in blacklist");
        blacklist[tokenAddress][tokenId] = false;

        emit UpdateBlackList(tokenAddress, tokenId, false);
    }    

    // return if NFT is in blacklist or not
    function checkBlackList(address tokenAddress, uint256 tokenId) external view returns(bool) {
        return blacklist[tokenAddress][tokenId];
    }
}