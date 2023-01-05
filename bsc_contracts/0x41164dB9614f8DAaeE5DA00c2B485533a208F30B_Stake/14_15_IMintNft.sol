//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMintNft {
    function stake(uint256 _tokenId , uint256 _endTime) external;
    function unStake(uint256 _tokenId) external;
}