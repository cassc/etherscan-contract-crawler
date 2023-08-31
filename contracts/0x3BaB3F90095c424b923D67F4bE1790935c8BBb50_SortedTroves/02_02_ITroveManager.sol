// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ITroveManager {
    event BaseRateUpdated(uint256 _baseRate);
    event CollateralSent(address _to, uint256 _amount);
    event LTermsUpdated(uint256 _L_collateral, uint256 _L_debt);
    event LastFeeOpTimeUpdated(uint256 _lastFeeOpTime);
    event Redemption(
        uint256 _attemptedDebtAmount,
        uint256 _actualDebtAmount,
        uint256 _collateralSent,
        uint256 _collateralFee
    );
    event RewardClaimed(address indexed account, address indexed recipient, uint256 claimed);
    event SystemSnapshotsUpdated(uint256 _totalStakesSnapshot, uint256 _totalCollateralSnapshot);
    event TotalStakesUpdated(uint256 _newTotalStakes);
    event TroveIndexUpdated(address _borrower, uint256 _newIndex);
    event TroveSnapshotsUpdated(uint256 _L_collateral, uint256 _L_debt);
    event TroveUpdated(address indexed _borrower, uint256 _debt, uint256 _coll, uint256 _stake, uint8 _operation);

    function addCollateralSurplus(address borrower, uint256 collSurplus) external;

    function applyPendingRewards(address _borrower) external returns (uint256 coll, uint256 debt);

    function claimCollateral(address _receiver) external;

    function claimReward(address receiver) external returns (uint256);

    function closeTrove(address _borrower, address _receiver, uint256 collAmount, uint256 debtAmount) external;

    function closeTroveByLiquidation(address _borrower) external;

    function collectInterests() external;

    function decayBaseRateAndGetBorrowingFee(uint256 _debt) external returns (uint256);

    function decreaseDebtAndSendCollateral(address account, uint256 debt, uint256 coll) external;

    function fetchPrice() external returns (uint256);

    function finalizeLiquidation(
        address _liquidator,
        uint256 _debt,
        uint256 _coll,
        uint256 _collSurplus,
        uint256 _debtGasComp,
        uint256 _collGasComp
    ) external;

    function getEntireSystemBalances() external returns (uint256, uint256, uint256);

    function movePendingTroveRewardsToActiveBalances(uint256 _debt, uint256 _collateral) external;

    function notifyRegisteredId(uint256[] calldata _assignedIds) external returns (bool);

    function openTrove(
        address _borrower,
        uint256 _collateralAmount,
        uint256 _compositeDebt,
        uint256 NICR,
        address _upperHint,
        address _lowerHint,
        bool _isRecoveryMode
    ) external returns (uint256 stake, uint256 arrayIndex);

    function redeemCollateral(
        uint256 _debtAmount,
        address _firstRedemptionHint,
        address _upperPartialRedemptionHint,
        address _lowerPartialRedemptionHint,
        uint256 _partialRedemptionHintNICR,
        uint256 _maxIterations,
        uint256 _maxFeePercentage
    ) external;

    function setAddresses(address _priceFeedAddress, address _sortedTrovesAddress, address _collateralToken) external;

    function setParameters(
        uint256 _minuteDecayFactor,
        uint256 _redemptionFeeFloor,
        uint256 _maxRedemptionFee,
        uint256 _borrowingFeeFloor,
        uint256 _maxBorrowingFee,
        uint256 _interestRateInBPS,
        uint256 _maxSystemDebt,
        uint256 _MCR
    ) external;

    function setPaused(bool _paused) external;

    function setPriceFeed(address _priceFeedAddress) external;

    function startSunset() external;

    function updateBalances() external;

    function updateTroveFromAdjustment(
        bool _isRecoveryMode,
        bool _isDebtIncrease,
        uint256 _debtChange,
        uint256 _netDebtChange,
        bool _isCollIncrease,
        uint256 _collChange,
        address _upperHint,
        address _lowerHint,
        address _borrower,
        address _receiver
    ) external returns (uint256, uint256, uint256);

    function vaultClaimReward(address claimant, address) external returns (uint256);

    function BOOTSTRAP_PERIOD() external view returns (uint256);

    function CCR() external view returns (uint256);

    function DEBT_GAS_COMPENSATION() external view returns (uint256);

    function DECIMAL_PRECISION() external view returns (uint256);

    function L_collateral() external view returns (uint256);

    function L_debt() external view returns (uint256);

    function MAX_INTEREST_RATE_IN_BPS() external view returns (uint256);

    function MCR() external view returns (uint256);

    function PERCENT_DIVISOR() external view returns (uint256);

    function PRISMA_CORE() external view returns (address);

    function SUNSETTING_INTEREST_RATE() external view returns (uint256);

    function Troves(
        address
    )
        external
        view
        returns (
            uint256 debt,
            uint256 coll,
            uint256 stake,
            uint8 status,
            uint128 arrayIndex,
            uint256 activeInterestIndex
        );

    function accountLatestMint(address) external view returns (uint32 amount, uint32 week, uint32 day);

    function activeInterestIndex() external view returns (uint256);

    function baseRate() external view returns (uint256);

    function borrowerOperationsAddress() external view returns (address);

    function borrowingFeeFloor() external view returns (uint256);

    function claimableReward(address account) external view returns (uint256);

    function collateralToken() external view returns (address);

    function dailyMintReward(uint256) external view returns (uint256);

    function debtToken() external view returns (address);

    function defaultedCollateral() external view returns (uint256);

    function defaultedDebt() external view returns (uint256);

    function emissionId() external view returns (uint16 debt, uint16 minting);

    function getBorrowingFee(uint256 _debt) external view returns (uint256);

    function getBorrowingFeeWithDecay(uint256 _debt) external view returns (uint256);

    function getBorrowingRate() external view returns (uint256);

    function getBorrowingRateWithDecay() external view returns (uint256);

    function getCurrentICR(address _borrower, uint256 _price) external view returns (uint256);

    function getEntireDebtAndColl(
        address _borrower
    ) external view returns (uint256 debt, uint256 coll, uint256 pendingDebtReward, uint256 pendingCollateralReward);

    function getEntireSystemColl() external view returns (uint256);

    function getEntireSystemDebt() external view returns (uint256);

    function getNominalICR(address _borrower) external view returns (uint256);

    function getPendingCollAndDebtRewards(address _borrower) external view returns (uint256, uint256);

    function getRedemptionFeeWithDecay(uint256 _collateralDrawn) external view returns (uint256);

    function getRedemptionRate() external view returns (uint256);

    function getRedemptionRateWithDecay() external view returns (uint256);

    function getTotalActiveCollateral() external view returns (uint256);

    function getTotalActiveDebt() external view returns (uint256);

    function getTotalMints(uint256 week) external view returns (uint32[7] memory);

    function getTroveCollAndDebt(address _borrower) external view returns (uint256 coll, uint256 debt);

    function getTroveFromTroveOwnersArray(uint256 _index) external view returns (address);

    function getTroveOwnersCount() external view returns (uint256);

    function getTroveStake(address _borrower) external view returns (uint256);

    function getTroveStatus(address _borrower) external view returns (uint256);

    function getWeek() external view returns (uint256 week);

    function getWeekAndDay() external view returns (uint256, uint256);

    function guardian() external view returns (address);

    function hasPendingRewards(address _borrower) external view returns (bool);

    function interestPayable() external view returns (uint256);

    function interestRate() external view returns (uint256);

    function lastActiveIndexUpdate() external view returns (uint256);

    function lastCollateralError_Redistribution() external view returns (uint256);

    function lastDebtError_Redistribution() external view returns (uint256);

    function lastFeeOperationTime() external view returns (uint256);

    function lastUpdate() external view returns (uint32);

    function liquidationManager() external view returns (address);

    function maxBorrowingFee() external view returns (uint256);

    function maxRedemptionFee() external view returns (uint256);

    function maxSystemDebt() external view returns (uint256);

    function minuteDecayFactor() external view returns (uint256);

    function owner() external view returns (address);

    function paused() external view returns (bool);

    function periodFinish() external view returns (uint32);

    function priceFeed() external view returns (address);

    function redemptionFeeFloor() external view returns (uint256);

    function rewardIntegral() external view returns (uint256);

    function rewardIntegralFor(address) external view returns (uint256);

    function rewardRate() external view returns (uint128);

    function rewardSnapshots(address) external view returns (uint256 collateral, uint256 debt);

    function sortedTroves() external view returns (address);

    function sunsetting() external view returns (bool);

    function surplusBalances(address) external view returns (uint256);

    function systemDeploymentTime() external view returns (uint256);

    function totalCollateralSnapshot() external view returns (uint256);

    function totalStakes() external view returns (uint256);

    function totalStakesSnapshot() external view returns (uint256);

    function vault() external view returns (address);
}