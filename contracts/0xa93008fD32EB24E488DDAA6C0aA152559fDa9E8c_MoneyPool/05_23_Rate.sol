// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import '../libraries/DataStruct.sol';
import '../libraries/Math.sol';

import '../interfaces/ILToken.sol';
import '../interfaces/IDToken.sol';
import '../interfaces/ITokenizer.sol';
import '../interfaces/IInterestRateModel.sol';

library Rate {
  using WadRayMath for uint256;
  using Rate for DataStruct.ReserveData;

  event RatesUpdated(
    address indexed underlyingAssetAddress,
    uint256 lTokenIndex,
    uint256 borrowAPY,
    uint256 depositAPY,
    uint256 totalBorrow,
    uint256 totalDeposit
  );

  struct UpdateRatesLocalVars {
    uint256 totalDToken;
    uint256 newBorrowAPY;
    uint256 newDepositAPY;
    uint256 averageBorrowAPY;
    uint256 totalVariableDebt;
  }

  function updateRates(
    DataStruct.ReserveData storage reserve,
    address underlyingAssetAddress,
    uint256 depositAmount,
    uint256 borrowAmount
  ) public {
    UpdateRatesLocalVars memory vars;

    vars.totalDToken = IDToken(reserve.dTokenAddress).totalSupply();

    vars.averageBorrowAPY = IDToken(reserve.dTokenAddress).getTotalAverageRealAssetBorrowRate();

    uint256 lTokenAssetBalance = IERC20(underlyingAssetAddress).balanceOf(reserve.lTokenAddress);
    (vars.newBorrowAPY, vars.newDepositAPY) = IInterestRateModel(reserve.interestModelAddress)
    .calculateRates(
      lTokenAssetBalance,
      vars.totalDToken,
      depositAmount,
      borrowAmount,
      reserve.moneyPoolFactor
    );

    reserve.borrowAPY = vars.newBorrowAPY;
    reserve.depositAPY = vars.newDepositAPY;

    emit RatesUpdated(
      underlyingAssetAddress,
      reserve.lTokenInterestIndex,
      vars.newBorrowAPY,
      vars.newDepositAPY,
      vars.totalDToken,
      lTokenAssetBalance + depositAmount - borrowAmount + vars.totalDToken
    );
  }
}