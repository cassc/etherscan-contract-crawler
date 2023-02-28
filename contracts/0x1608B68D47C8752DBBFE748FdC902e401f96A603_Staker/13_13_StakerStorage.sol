// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.14;

struct Withdrawal {
    address user;
    uint256 amount;
}

abstract contract StakerStorage {
    // Staker constants

    address public stakingTokenAddress;
    address public stakeManagerContractAddress;
    address public validatorShareContractAddress;

    address public whitelistAddress;
    
    address public treasuryAddress;
    
    // Shares, withdrawals, & amounts

    uint256 public totalShares;
    uint256 public claimedRewards;
    uint256 public phi; // basis points
    uint256 public cap;

    mapping(address => uint256) public userShares;
    mapping(uint256 => Withdrawal) public unbondingWithdrawals; // maps unbond nonce to (user, amount)

    // Gap for upgradeability
    uint256[50] private __gap;
}