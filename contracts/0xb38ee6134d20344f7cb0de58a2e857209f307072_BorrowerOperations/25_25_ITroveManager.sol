// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./ILiquityBase.sol";
import "./IStabilityPool.sol";
import "./ITHUSDToken.sol";
import "./IPCV.sol";


// Common interface for the Trove Manager.
interface ITroveManager is ILiquityBase {

    enum Status {
        nonExistent,
        active,
        closedByOwner,
        closedByLiquidation,
        closedByRedemption
    }

    // --- Events ---

    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event PriceFeedAddressChanged(address _newPriceFeedAddress);
    event THUSDTokenAddressChanged(address _newTHUSDTokenAddress);
    event ActivePoolAddressChanged(address _activePoolAddress);
    event DefaultPoolAddressChanged(address _defaultPoolAddress);
    event StabilityPoolAddressChanged(address _stabilityPoolAddress);
    event GasPoolAddressChanged(address _gasPoolAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
    event SortedTrovesAddressChanged(address _sortedTrovesAddress);
    event PCVAddressChanged(address _pcvAddress);

    event Liquidation(uint256 _liquidatedDebt, uint256 _liquidatedColl, uint256 _collGasCompensation, uint256 _THUSDGasCompensation);
    event Redemption(uint256 _attemptedTHUSDAmount, uint256 _actualTHUSDAmount, uint256 _collateralSent, uint256 _collateralFee);
    event TroveUpdated(address indexed _borrower, uint256 _debt, uint256 _coll, uint256 stake, uint8 operation);
    event TroveLiquidated(address indexed _borrower, uint256 _debt, uint256 _coll, uint8 operation);
    event BaseRateUpdated(uint256 _baseRate);
    event LastFeeOpTimeUpdated(uint256 _lastFeeOpTime);
    event TotalStakesUpdated(uint256 _newTotalStakes);
    event SystemSnapshotsUpdated(uint256 _totalStakesSnapshot, uint256 _totalCollateralSnapshot);
    event LTermsUpdated(uint256 _L_Collateral, uint256 _L_THUSDDebt);
    event TroveSnapshotsUpdated(uint256 _L_Collateral, uint256 _L_THUSDDebt);
    event TroveIndexUpdated(address _borrower, uint256 _newIndex);

    // --- Functions ---

    function setAddresses(
        address _borrowerOperationsAddress,
        address _activePoolAddress,
        address _defaultPoolAddress,
        address _stabilityPoolAddress,
        address _gasPoolAddress,
        address _collSurplusPoolAddress,
        address _priceFeedAddress,
        address _thusdTokenAddress,
        address _sortedTrovesAddress,
        address _pcvAddress
    ) external;

    function stabilityPool() external view returns (IStabilityPool);
    function thusdToken() external view returns (ITHUSDToken);
    function pcv() external view returns (IPCV);

    function getTroveOwnersCount() external view returns (uint);

    function getTroveFromTroveOwnersArray(uint256 _index) external view returns (address);

    function getNominalICR(address _borrower) external view returns (uint);
    function getCurrentICR(address _borrower, uint256 _price) external view returns (uint);

    function liquidate(address _borrower) external;

    function liquidateTroves(uint256 _n) external;

    function batchLiquidateTroves(address[] calldata _troveArray) external;

    function redeemCollateral(
        uint256 _THUSDAmount,
        address _firstRedemptionHint,
        address _upperPartialRedemptionHint,
        address _lowerPartialRedemptionHint,
        uint256 _partialRedemptionHintNICR,
        uint256 _maxIterations,
        uint256 _maxFee
    ) external;

    function updateStakeAndTotalStakes(address _borrower) external returns (uint);

    function updateTroveRewardSnapshots(address _borrower) external;

    function addTroveOwnerToArray(address _borrower) external returns (uint256 index);

    function applyPendingRewards(address _borrower) external;

    function getPendingCollateralReward(address _borrower) external view returns (uint);

    function getPendingTHUSDDebtReward(address _borrower) external view returns (uint);

     function hasPendingRewards(address _borrower) external view returns (bool);

    function getEntireDebtAndColl(address _borrower) external view returns (
        uint256 debt,
        uint256 coll,
        uint256 pendingTHUSDDebtReward,
        uint256 pendingCollateralReward
    );

    function closeTrove(address _borrower) external;

    function removeStake(address _borrower) external;

    function getRedemptionRate() external view returns (uint);
    function getRedemptionRateWithDecay() external view returns (uint);

    function getRedemptionFeeWithDecay(uint256 _collateralDrawn) external view returns (uint);

    function getBorrowingRate() external view returns (uint);
    function getBorrowingRateWithDecay() external view returns (uint);

    function getBorrowingFee(uint256 THUSDDebt) external view returns (uint);
    function getBorrowingFeeWithDecay(uint256 _THUSDDebt) external view returns (uint);

    function decayBaseRateFromBorrowing() external;

    function getTroveStatus(address _borrower) external view returns (Status);

    function getTroveStake(address _borrower) external view returns (uint);

    function getTroveDebt(address _borrower) external view returns (uint);

    function getTroveColl(address _borrower) external view returns (uint);

    function setTroveStatus(address _borrower, Status _status) external;

    function increaseTroveColl(address _borrower, uint256 _collIncrease) external returns (uint);

    function decreaseTroveColl(address _borrower, uint256 _collDecrease) external returns (uint);

    function increaseTroveDebt(address _borrower, uint256 _debtIncrease) external returns (uint);

    function decreaseTroveDebt(address _borrower, uint256 _collDecrease) external returns (uint);

    function getTCR(uint256 _price) external view returns (uint);

    function checkRecoveryMode(uint256 _price) external view returns (bool);
}