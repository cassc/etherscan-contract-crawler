//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ExponentialNoError.sol";
import "./ComptrollerInterface.sol";
import "./VTokenInterface.sol";

contract Lens is ExponentialNoError {
    /**
     * @dev Local vars for avoiding stack-depth limits in calculating account liquidity.
     *  Note that `vTokenBalance` is the number of vTokens the account owns in the market,
     *  whereas `borrowBalance` is the amount of underlying that the account has borrowed.
     */
    struct AccountLiquidityLocalVars {
        uint totalCollateral;
        uint sumCollateral;
        uint sumBorrowPlusEffects;
        uint vTokenBalance;
        uint borrowBalance;
        uint exchangeRateMantissa;
        uint oraclePriceMantissa;
        Exp collateralFactor;
        Exp exchangeRate;
        Exp oraclePrice;
        Exp tokensToDenom;
        Exp tokensToDenom1;
    }

    function getAccountPosition(address comptroller, address account) internal view returns (
        uint totalCollateral,
        uint totalDebt,
        uint availableBorrows,
        uint ltv
    ) {
        AccountLiquidityLocalVars memory vars; // Holds all our calculation results
        uint oErr;

        address[] memory assets = ComptrollerInterface(comptroller).getAssetsIn(account);
        uint assetsCount = assets.length;
        for (uint i = 0; i < assetsCount; ++i) {
            VTokenInterface asset = VTokenInterface(assets[i]);

            // Read the balances and exchange rate from the vToken
            (oErr, vars.vTokenBalance, vars.borrowBalance, vars.exchangeRateMantissa) = asset.getAccountSnapshot(
                account
            );
            if (oErr != 0) {
                // semi-opaque error code, we assume NO_ERROR == 0 is invariant between upgrades
                continue;
            }
            (, uint collateralFactorMantissa, ) = ComptrollerInterface(comptroller).markets(address(asset));
            vars.collateralFactor = Exp({ mantissa: collateralFactorMantissa });
            vars.exchangeRate = Exp({ mantissa: vars.exchangeRateMantissa });

            // Get the normalized price of the asset
            vars.oraclePriceMantissa = ComptrollerInterface(comptroller).oracle().getUnderlyingPrice(address(asset));
            if (vars.oraclePriceMantissa == 0) {
                continue;
            }
            vars.oraclePrice = Exp({ mantissa: vars.oraclePriceMantissa });

            // Pre-compute a conversion factor from tokens -> bnb (normalized price value)
            vars.tokensToDenom = mul_(mul_(vars.collateralFactor, vars.exchangeRate), vars.oraclePrice);

            // sumCollateral += tokensToDenom * vTokenBalance
            vars.sumCollateral = mul_ScalarTruncateAddUInt(vars.tokensToDenom, vars.vTokenBalance, vars.sumCollateral);

            vars.tokensToDenom1 = mul_(vars.exchangeRate, vars.oraclePrice);
            vars.totalCollateral = mul_ScalarTruncateAddUInt(vars.tokensToDenom1, vars.vTokenBalance, vars.totalCollateral);

            // sumBorrowPlusEffects += oraclePrice * borrowBalance
            vars.sumBorrowPlusEffects = mul_ScalarTruncateAddUInt(
                vars.oraclePrice,
                vars.borrowBalance,
                vars.sumBorrowPlusEffects
            );
        }

        VAIControllerInterface vaiController = ComptrollerInterface(comptroller).vaiController();
        if (address(vaiController) != address(0)) {
            vars.sumBorrowPlusEffects = add_(vars.sumBorrowPlusEffects, vaiController.getVAIRepayAmount(account));
        }

        return (
            vars.totalCollateral,
            vars.sumBorrowPlusEffects,
            vars.sumCollateral > vars.sumBorrowPlusEffects ?  vars.sumCollateral - vars.sumBorrowPlusEffects : 0,
            vars.totalCollateral > 0 ? divRound_(vars.sumCollateral * 1e4, vars.totalCollateral) : 0
        );
    }
}