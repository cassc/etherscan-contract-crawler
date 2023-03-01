// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract StakePoolStorage {
    struct Tier {
        string name;
        address collection;
        uint256 stake;
        uint256 weight;
    }

    mapping(address => uint256) internal allocPoints;

    mapping(address => uint256) internal timeLocks;

    mapping(address => uint256) internal tokenBalances;

    mapping(address => mapping(uint256 => address)) internal nftOwners;

    mapping(address => mapping(address => uint256)) internal nftBalances;

    mapping(address => uint256) internal nftAllocPoints;

    mapping(address => uint256) internal promoAllocPoints;

    Tier[] internal tiers;

    address[] internal userAdresses;

    uint256 public totalAllocPoint;

    uint256 public collectedFee;

    uint256 public totalStaked;

    uint256 public totalStakedNft;

    bool public stakeOn;

    bool public withdrawOn;

    uint8 public decimals;

    uint256 public maxStakeOrWithdrawNft;

    uint256 public minStakingAmount;

    uint256[50] private gap;
}