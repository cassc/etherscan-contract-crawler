// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.15;

import {Side} from "../interfaces/IPool.sol";

library PoolErrors {
    error UpdateCauseLiquidation();
    error InvalidTokenPair(address index, address collateral);
    error InvalidLeverage(uint256 size, uint256 margin, uint256 maxLeverage);
    error InvalidPositionSize();
    error OrderManagerOnly();
    error UnknownToken(address token);
    error AssetNotListed(address token);
    error InsufficientPoolAmount(address token);
    error ReserveReduceTooMuch(address token);
    error SlippageExceeded();
    error ValueTooHigh(uint256 maxValue);
    error InvalidInterval();
    error PositionNotLiquidated(bytes32 key);
    error ZeroAmount();
    error ZeroAddress();
    error RequireAllTokens();
    error DuplicateToken(address token);
    error FeeDistributorOnly();
    error InvalidMaxLeverage();
    error SameTokenSwap(address token);
    error InvalidTranche(address tranche);
    error TrancheAlreadyAdded(address tranche);
    error RemoveLiquidityTooMuch(address tranche, uint256 outAmount, uint256 trancheBalance);
    error CannotDistributeToTranches(
        address indexToken, address collateralToken, uint256 amount, bool CannotDistributeToTranches
    );
    error CannotSetRiskFactorForStableCoin(address token);
    error PositionNotExists(address owner, address indexToken, address collateralToken, Side side);
    error MaxNumberOfTranchesReached();
    error TooManyTokenAdded(uint256 number, uint256 max);
    error AddLiquidityNotAllowed(address tranche, address token);
}