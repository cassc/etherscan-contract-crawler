//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT 0.8.17
pragma solidity ^0.8.17;

import "./BitNFT.sol";

contract BitNFTV2 is BitNFT
{
    function updateTokenURI(
        uint256 tokenId, 
        string memory nftTokenURI
    ) public onlyOwner returns (bool) {
        _setTokenURI(tokenId, nftTokenURI);
        return true;
    }
}