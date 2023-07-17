// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

interface INFT{
    function setStartStake(uint256[] calldata _tokenIds) external;
    function setEndStake(uint256[] calldata _tokenIds) external;
    function ownerOf(uint256 tokenId) external returns (address);
    function getStakeState(uint256 _tokenId,uint256 _info)external returns (uint256);
}