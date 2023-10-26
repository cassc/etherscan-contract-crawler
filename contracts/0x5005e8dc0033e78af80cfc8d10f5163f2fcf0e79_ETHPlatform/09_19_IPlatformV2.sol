// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ICVIOracleV3.sol";
import "./IFeesCalculatorV3.sol";
import "./IPositionRewardsV2.sol";
import "../../v1/interfaces/IFeesCollector.sol";
import "./ILiquidationV2.sol";

interface IPlatformV2 {

    struct Position {
        uint168 positionUnitsAmount;
        uint8 leverage;
        uint16 openCVIValue;
        uint32 creationTimestamp;
        uint32 originalCreationTimestamp;
    }

    event Deposit(address indexed account, uint256 tokenAmount, uint256 lpTokensAmount, uint256 feeAmount);
    event Withdraw(address indexed account, uint256 tokenAmount, uint256 lpTokensAmount, uint256 feeAmount);
    event OpenPosition(address indexed account, uint256 tokenAmount, uint8 leverage, uint256 feeAmount, uint256 positionUnitsAmount, uint256 cviValue);
    event ClosePosition(address indexed account, uint256 tokenAmount, uint256 feeAmount, uint256 positionUnitsAmount, uint8 leverage, uint256 cviValue);
    event LiquidatePosition(address indexed positionAddress, uint256 currentPositionBalance, bool isBalancePositive, uint256 positionUnitsAmount);

    function deposit(uint256 tokenAmount, uint256 minLPTokenAmount) external returns (uint256 lpTokenAmount);
    function withdraw(uint256 tokenAmount, uint256 maxLPTokenBurnAmount) external returns (uint256 burntAmount, uint256 withdrawnAmount);
    function withdrawLPTokens(uint256 lpTokenAmount) external returns (uint256 burntAmount, uint256 withdrawnAmount);

    function openPosition(uint168 tokenAmount, uint16 maxCVI, uint168 maxBuyingPremiumFeePercentage, uint8 leverage) external returns (uint168 positionUnitsAmount);
    function closePosition(uint168 positionUnitsAmount, uint16 minCVI) external returns (uint256 tokenAmount);

    function liquidatePositions(address[] calldata positionOwners) external returns (uint256 finderFeeAmount);
    function getLiquidableAddresses(address[] calldata positionOwners) external view returns (address[] memory);

    function setRevertLockedTransfers(bool revertLockedTransfers) external;

    function setFeesCollector(IFeesCollector newCollector) external;
    function setFeesCalculator(IFeesCalculatorV3 newCalculator) external;
    function setCVIOracle(ICVIOracleV3 newOracle) external;
    function setRewards(IPositionRewardsV2 newRewards) external;
    function setLiquidation(ILiquidationV2 newLiquidation) external;

    function setLatestOracleRoundId(uint80 newOracleRoundId) external;

    function setLPLockupPeriod(uint256 newLPLockupPeriod) external;
    function setBuyersLockupPeriod(uint256 newBuyersLockupPeriod) external;

    function setEmergencyWithdrawAllowed(bool newEmergencyWithdrawAllowed) external;
    function setStakingContractAddress(address newStakingContractAddress) external;

    function setCanPurgeSnapshots(bool newCanPurgeSnapshots) external;

    function setMaxAllowedLeverage(uint8 newMaxAllowedLeverage) external;

    function getToken() external view returns (IERC20);

    function calculatePositionBalance(address positionAddress) external view returns (uint256 currentPositionBalance, bool isPositive, uint168 positionUnitsAmount, uint8 leverage, uint256 fundingFees, uint256 marginDebt);
    function calculatePositionPendingFees(address positionAddress, uint168 positionUnitsAmount) external view returns (uint256 pendingFees);

    function totalBalance() external view returns (uint256 balance);
    function totalBalanceWithAddendum() external view returns (uint256 balance);

    function calculateLatestTurbulenceIndicatorPercent() external view returns (uint16);

    function positions(address positionAddress) external view returns (uint168 positionUnitsAmount, uint8 leverage, uint16 openCVIValue, uint32 creationTimestamp, uint32 originalCreationTimestamp);
}