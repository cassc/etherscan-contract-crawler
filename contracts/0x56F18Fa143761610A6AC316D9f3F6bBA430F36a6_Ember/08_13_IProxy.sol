// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IProxy{

    function getNFT(address _nft, uint256 _tokenId, uint256 _lendingId) external;
    
}