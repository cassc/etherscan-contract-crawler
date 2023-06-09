// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../library/util/Expirable.sol";
import "../../library/ERC20/ERC20Partition.sol";

import "../../core/Staking/IStaking.sol";

import "../Affiliate/AffiliateRouter.sol";

import "./StakingPositionManager/IStakingPositionManager.sol";

import "./IStakingRouter.sol";

contract StakingRouter is IStakingRouter, AffiliateRouter, Expirable {
    using SafeERC20 for IERC20;

    address public immutable override STAKING_POSITION_MANAGER;
    address public immutable override STAKING_TOKEN;
    address public immutable override STAKING;

    constructor(address stakingPositionManager) {
        STAKING_POSITION_MANAGER = stakingPositionManager;
        STAKING = IStakingPositionManager(stakingPositionManager).STAKING();
        STAKING_TOKEN = IStakingPositionManager(stakingPositionManager).STAKING_TOKEN();

        IERC20(STAKING_TOKEN).approve(STAKING_POSITION_MANAGER, type(uint256).max);
    }

    function rewardBalance(uint256 tokenId) external override view returns (uint256) {
        (bytes32 stakeId, uint256 stakeAmount) = IStakingPositionManager(STAKING_POSITION_MANAGER).stakeBalanceOf(tokenId);
        return IStaking(STAKING).rewardBalance(stakeId, stakeAmount);
    }

    function totalBalance(uint256 tokenId) external override view returns (uint256) {
        (bytes32 stakeId, uint256 stakeAmount) = IStakingPositionManager(STAKING_POSITION_MANAGER).stakeBalanceOf(tokenId);
        return IStaking(STAKING).totalBalance(stakeId, stakeAmount);
    }

    function stake(
        uint256 tokenAmount,
        uint32 stakingDuration,
        uint256 minMultiplier,
        address stakeTo,
        uint256 deadline
    ) external override whenNotPaused expires(deadline) returns (uint256 tokenId) {
        require(tokenAmount > 0, 'StakingRouter: INVALID_AMOUNT');
        IKEI.Snapshot memory k = _snapshot();

        _assignReferrer(k.referral);

        address _sender = _msgSender();

        IERC20(k.token).safeTransferFrom(_sender, k.treasury, tokenAmount);

        (bytes32 _stakeId, IStaking.StakeDetails memory _stake) = IStaking(STAKING).stake(address(this), 0, stakingDuration, 0);

        tokenId = IStakingPositionManager(STAKING_POSITION_MANAGER).mint(
            _stakeId,
            _stake.totalSupply,
            stakeTo,
            "StakingRouter: STAKE_CREATED"
        );

        require(_stake.rewardMultiplier >= minMultiplier, 'StakingRouter: INSUFFICIENT_MULTIPLIER');
    }

    function lockStake(
        uint256 tokenAmount,
        uint32 stakingDuration,
        uint32 lockDuration,
        uint256 minMultiplier,
        address stakeTo,
        uint256 deadline
    ) external whenNotPaused override expires(deadline) returns (uint256 tokenId) {
        require(tokenAmount > 0, 'StakingRouter: INVALID_AMOUNT');
        IKEI.Snapshot memory k = _snapshot();

        _assignReferrer(k.referral);

        address _sender = _msgSender();

        IERC20(k.token).safeTransferFrom(_sender, k.treasury, tokenAmount);

        (bytes32 _stakeId, IStaking.StakeDetails memory _stake) = IStaking(STAKING).stake(address(this), 0, stakingDuration, lockDuration);

        tokenId = IStakingPositionManager(STAKING_POSITION_MANAGER).mint(
            _stakeId,
            _stake.totalSupply,
            stakeTo,
            "StakingRouter: STAKE_CREATED"
        );

        require(_stake.rewardMultiplier >= minMultiplier, 'StakingRouter: INSUFFICIENT_MULTIPLIER');
    }

    function splitStake(
        uint256 tokenId,
        SplitStakeOptions calldata options,
        uint256 deadline
    ) external override whenNotPaused expires(deadline) returns (uint256[] memory newTokenIds) {
        require(options.amounts.length == options.stakeTo.length, "StakingRouter: INVALID_LENGTHS");
        require(options.amounts.length > 1, "StakingRouter: INVALID_LENGTHS");

        _assignReferrer(K.referral());

        newTokenIds = new uint256[](options.amounts.length);
        uint256 validateTotal;

        (bytes32 stakeId, uint256 tokensReleased) = IStakingPositionManager(STAKING_POSITION_MANAGER).burn(
            tokenId,
            address(this),
            "StakingRouter: SPLITTING_STAKE"
        );

        for (uint i = 0; i < options.amounts.length; ++i) {
            uint256 amount = options.amounts[i];
            validateTotal += amount;

            newTokenIds[i] = IStakingPositionManager(STAKING_POSITION_MANAGER).mint(
                stakeId,
                amount,
                options.stakeTo[i],
                "StakingRouter: SPLIT_STAKE"
            );
        }

        require(validateTotal == tokensReleased, 'StakingRouter: INVALID_TOTAL_AMOUNTS');
    }

    function unstake(
        uint256 tokenId,
        uint256 stakeAmount,
        uint256 maxUnstakePenalty,
        address unstakeTo,
        address stakeTo,
        uint256 deadline
    ) external override whenNotPaused expires(deadline) returns (uint256 newTokenId) {
        require(stakeAmount > 0, 'StakingRouter: INVALID_AMOUNT');

        _assignReferrer(K.referral());

        (bytes32 stakeId, uint256 tokensReleased) = IStakingPositionManager(STAKING_POSITION_MANAGER).burn(
            tokenId,
            address(this),
            "StakingRouter: BURNING_TO_UNSTAKE"
        );
        require(tokensReleased >= stakeAmount, "StakingRouter: INSUFFICIENT_STAKE");

        IERC20Partition(STAKING_TOKEN).transfer(
            STAKING,
            stakeId,
            stakeAmount,
            "StakingRouter: PREPARE_UNSTAKE"
        );
        IStaking.UnstakeReceipt memory _receipt = IStaking(STAKING).unstake(stakeId, unstakeTo);

        if (tokensReleased > stakeAmount) {
            newTokenId = IStakingPositionManager(STAKING_POSITION_MANAGER).mint(
                stakeId,
                tokensReleased - stakeAmount,
                stakeTo,
                "StakingRouter: REMAINING_STAKED"
            );
        }

        require(_receipt.unstakePenalty <= maxUnstakePenalty, 'StakingRouter: MAX_PENALTY_BREACHED');
    }
}