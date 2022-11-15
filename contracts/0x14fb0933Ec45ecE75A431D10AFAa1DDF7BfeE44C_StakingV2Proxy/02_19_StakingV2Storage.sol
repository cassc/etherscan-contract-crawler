// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "./libraries/LibStaking.sol";

import "./interfaces/IERC20.sol";

contract StakingV2Storage {

    LibStaking.Epoch public epoch;

    IERC20 public tos;
    address public lockTOS;
    address public treasury;

    uint256 public index_;
    uint256 internal free = 1;
    uint256 public totalLtos;
    uint256 public stakingPrincipal;
    uint256 public rebasePerEpoch;
    uint256 public basicBondPeriod;
    uint256 public stakingIdCounter;
    uint256 public marketIdCounter;

    // 0 비어있는 더미, 1 기간없는 순수 토스 스테이킹
    mapping(address => uint256[]) public userStakings;

    //address - stakeId - 0
    mapping(address => mapping(uint256 => uint256)) public userStakingIndex;

    mapping(uint256 => LibStaking.UserBalance) public allStakings;

    // stakeId - sTOSid
    mapping(uint256 => uint256) public connectId;

    modifier nonZero(uint256 tokenId) {
        require(tokenId != 0, "Staking: zero vallue");
        _;
    }

    modifier nonZeroAddress(address account) {
        require(
            account != address(0),
            "Staking: zero address"
        );
        _;
    }

    /// @dev Check if a function is used or not
    modifier ifFree {
        require(free == 1, "LockId is already in use");
        free = 0;
        _;
        free = 1;
    }

}