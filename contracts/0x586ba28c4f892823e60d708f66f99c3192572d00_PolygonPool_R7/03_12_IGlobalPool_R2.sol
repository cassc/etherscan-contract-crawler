// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

interface IGlobalPool_R2 {

    event StakePending(address indexed staker, uint256 amount);

    event StakePendingV2(address indexed staker, uint256 amount, bool indexed isRebasing);

    event RewardClaimed(address indexed staker, uint256 amount);

    event BondContractChanged(address oldBondContract, address newBondContract);

    event CertContractChanged(address oldCertContract, address newCertContract);

    event TokensBurned(address indexed staker, uint256 amount, uint256 shares, uint256 fee, bool indexed isRebasing);

    event EthFeeCollected(address indexed claimer, uint256 amount);

    event EthUnstakeFeeChanged(uint256 prevValue, uint256 newValue);

    function stake(uint256 amount) external;

    function stakeAndClaimBonds(uint256 amount) external;

    function stakeAndClaimCerts(uint256 amount) external;

    function unstake(uint256 amount, uint256 fee, uint256 useBeforeBlock, bytes memory signature) external payable;

    function unstakeBonds(uint256 amount, uint256 fee, uint256 useBeforeBlock, bytes memory signature) external payable;

    function unstakeCerts(uint256 amount, uint256 fee, uint256 useBeforeBlock, bytes memory signature) external payable;
}