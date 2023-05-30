// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

abstract contract IFancyBearStaking {

    struct TokenStakingData {
        address owner;
        uint256 timestamp;
    }

    mapping(uint256 => TokenStakingData) public stakingDataByTokenId;
    uint256 public minimumHoneyConsumption;
    uint256 public cooldown;

    function getOwnerOf(uint256 _tokenId) public virtual returns (address);
    function getTimestampOf(uint256 _tokenId) public virtual returns (uint256);
}