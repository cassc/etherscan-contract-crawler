//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import '../../../interfaces/ICurvePool.sol';
import '../interfaces/ICurvePool2.sol';
import './CurveStakeDaoExtraStratBase.sol';

contract CurveStakeDaoStrat2 is CurveStakeDaoExtraStratBase {
    using SafeERC20 for IERC20Metadata;

    uint128 public constant CURVE_3POOL_LP_TOKEN_ID = 1;
    int128 public constant CURVE_3POOL_LP_TOKEN_ID_INT = int128(CURVE_3POOL_LP_TOKEN_ID);

    ICurvePool public immutable pool3;
    IERC20Metadata public immutable pool3LP;
    ICurvePool2 public immutable pool;

    constructor(
        Config memory config,
        address vaultAddr,
        address poolLPAddr,
        address tokenAddr,
        address pool3Addr,
        address pool3LPAddr,
        address poolAddr,
        address extraTokenAddr
    ) CurveStakeDaoExtraStratBase(config, vaultAddr, poolLPAddr, tokenAddr, extraTokenAddr) {
        pool3 = ICurvePool(pool3Addr);
        pool3LP = IERC20Metadata(pool3LPAddr);
        pool = ICurvePool2(poolAddr);
    }

    function checkDepositSuccessful(uint256[3] memory amounts)
        internal
        view
        override
        returns (bool)
    {
        uint256 amountsTotal;
        for (uint256 i = 0; i < 3; i++) {
            amountsTotal += amounts[i] * decimalsMultipliers[i];
        }
        uint256 amountsMin = (amountsTotal * minDepositAmount) / DEPOSIT_DENOMINATOR;
        uint256 lpPrice = pool3.get_virtual_price();
        uint256 depositedLp = pool3.calc_token_amount(amounts, true);

        return (depositedLp * lpPrice) / CURVE_PRICE_DENOMINATOR >= amountsMin;
    }

    function depositPool(uint256[3] memory amounts) internal override returns (uint256 poolLPs) {
        for (uint256 i = 0; i < 3; i++) {
            _config.tokens[i].safeIncreaseAllowance(address(pool3), amounts[i]);
        }
        pool3.add_liquidity(amounts, 0);

        uint256[2] memory amounts2;
        amounts2[CURVE_3POOL_LP_TOKEN_ID] = pool3LP.balanceOf(address(this));
        pool3LP.safeIncreaseAllowance(address(pool), amounts2[CURVE_3POOL_LP_TOKEN_ID]);
        poolLPs = pool.add_liquidity(amounts2, 0);

        poolLP.safeIncreaseAllowance(address(vault), poolLPs);
        vault.deposit(address(this), poolLPs, true);
    }

    function getCurvePoolPrice() internal view override returns (uint256) {
        return pool.get_virtual_price();
    }

    function calcWithdrawOneCoin(uint256 userRatioOfCrvLps, uint128 tokenIndex)
        external
        view
        override
        returns (uint256 tokenAmount)
    {
        uint256 removingCrvLps = (vault.liquidityGauge().balanceOf(address(this)) *
            userRatioOfCrvLps) / 1e18;
        uint256 pool3Lps = pool.calc_withdraw_one_coin(removingCrvLps, CURVE_3POOL_LP_TOKEN_ID_INT);
        return pool3.calc_withdraw_one_coin(pool3Lps, int128(tokenIndex));
    }

    function calcSharesAmount(uint256[3] memory tokenAmounts, bool isDeposit)
        external
        view
        override
        returns (uint256 sharesAmount)
    {
        uint256[2] memory tokenAmounts2;
        tokenAmounts2[CURVE_3POOL_LP_TOKEN_ID] = pool3.calc_token_amount(tokenAmounts, isDeposit);
        return pool.calc_token_amount(tokenAmounts2, isDeposit);
    }

    function calcCrvLps(
        WithdrawalType withdrawalType,
        uint256 userRatioOfCrvLps, // multiplied by 1e18
        uint256[3] memory tokenAmounts,
        uint128 tokenIndex
    )
        internal
        view
        override
        returns (
            bool success,
            uint256 removingCrvLps,
            uint256[] memory tokenAmountsDynamic
        )
    {
        uint256[2] memory minAmounts2;
        minAmounts2[CURVE_3POOL_LP_TOKEN_ID] = pool3.calc_token_amount(tokenAmounts, false);

        removingCrvLps =
            (vault.liquidityGauge().balanceOf(address(this)) * userRatioOfCrvLps) /
            1e18;

        success = removingCrvLps >= pool.calc_token_amount(minAmounts2, false);

        if (success && withdrawalType == WithdrawalType.OneCoin) {
            uint256 pool3Lps = pool.calc_withdraw_one_coin(
                removingCrvLps,
                CURVE_3POOL_LP_TOKEN_ID_INT
            );
            success =
                tokenAmounts[tokenIndex] <=
                pool3.calc_withdraw_one_coin(pool3Lps, int128(tokenIndex));
        }

        tokenAmountsDynamic = new uint256[](2);
    }

    function removeCrvLps(
        uint256 removingCrvLps,
        uint256[] memory,
        WithdrawalType withdrawalType,
        uint256[3] memory tokenAmounts,
        uint128 tokenIndex
    ) internal override {
        uint256 prevCrv3Balance = pool3LP.balanceOf(address(this));

        pool.remove_liquidity_one_coin(removingCrvLps, CURVE_3POOL_LP_TOKEN_ID_INT, 0);

        uint256 crv3LiqAmount = pool3LP.balanceOf(address(this)) - prevCrv3Balance;
        if (withdrawalType == WithdrawalType.Base) {
            pool3.remove_liquidity(crv3LiqAmount, tokenAmounts);
        } else if (withdrawalType == WithdrawalType.OneCoin) {
            pool3.remove_liquidity_one_coin(
                crv3LiqAmount,
                int128(tokenIndex),
                tokenAmounts[tokenIndex]
            );
        }
    }

    /**
     * @dev sell base token on strategy can be called by anyone
     */
    function sellToken() public {
        uint256 sellBal = token.balanceOf(address(this));
        if (sellBal > 0) {
            token.safeIncreaseAllowance(address(pool), sellBal);
            pool.exchange_underlying(0, 3, sellBal, 0);
        }
    }

    function withdrawAllSpecific() internal override {
        uint256[2] memory minAmounts2;
        uint256[3] memory minAmounts;
        pool.remove_liquidity(poolLP.balanceOf(address(this)), minAmounts2);
        sellToken();
        pool3.remove_liquidity(pool3LP.balanceOf(address(this)), minAmounts);
    }
}