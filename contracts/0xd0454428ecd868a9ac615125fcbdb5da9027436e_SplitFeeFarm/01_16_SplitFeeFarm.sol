// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./LinearVestingVault.sol";

contract SplitFeeFarm is LinearVestingVault {
    using SafeERC20 for IERC20;

    uint256 private constant ONE_IN_TEN_DECIMALS = 1e10;
    uint256 private constant MAXIMUM_DAO_WITHDRAWAL_IN_TEN_DECIMALS = ONE_IN_TEN_DECIMALS/20;
    uint256 private constant MINIMUM_DURATION_BETWEEN_DAO_FEE_WITHDRAWAL = 7 days;

    uint256 public lastDaoWithdrawal;

    event FeesTaken(
        uint256 entitledFeesInDollars,
        uint256 averagePoolBalanceInDollars,
        uint256 tokensTransferred
    );

    error DAOFeeSplitTooMuch();
    error DAOFeeSplitTooSoon();

    constructor( 
        address _rewardToken,
        address _stakingToken,
        uint256 _targetTokensPerDay,
        uint256 _targetLockedStakingToken,
        uint256 _harvestLockoutTime
    ) LinearVestingVault(
        _rewardToken,
        _stakingToken,
        _targetTokensPerDay,
        _targetLockedStakingToken,
        _harvestLockoutTime
    ) {}

    function takeFees(uint256 entitledFeesInDollars, uint256 averagePoolBalanceInDollars) external onlyOwner {
        // calculate fraction in base ten
        uint256 theFraction = (ONE_IN_TEN_DECIMALS*entitledFeesInDollars)/averagePoolBalanceInDollars;
        // Check: less than the max?
        if(theFraction > MAXIMUM_DAO_WITHDRAWAL_IN_TEN_DECIMALS) {
            revert DAOFeeSplitTooMuch();
        }
        // Check: OK to send?
        if(block.timestamp < lastDaoWithdrawal+MINIMUM_DURATION_BETWEEN_DAO_FEE_WITHDRAWAL){
            revert DAOFeeSplitTooSoon();
        }
        // Effects
        lastDaoWithdrawal = block.timestamp;

        // Interactions
        uint256 tokensToTransfer = (theFraction*totalAssets())/ONE_IN_TEN_DECIMALS;
        IERC20(STAKING_TOKEN).safeTransfer(msg.sender, tokensToTransfer);
        
        emit FeesTaken(entitledFeesInDollars, averagePoolBalanceInDollars, tokensToTransfer);
    }


}