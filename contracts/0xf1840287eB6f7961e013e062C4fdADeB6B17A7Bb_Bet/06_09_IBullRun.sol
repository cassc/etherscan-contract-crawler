// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.15;

interface IBullRun {
    function StakedNFTInfo(uint16 _tokenID) external returns 
        (uint16 tokenID, address owner, uint80 stakeTimestamp, uint8 typeOfNFT, uint256 value);
    function IsNFTStaked(uint16) external view returns (bool);
}