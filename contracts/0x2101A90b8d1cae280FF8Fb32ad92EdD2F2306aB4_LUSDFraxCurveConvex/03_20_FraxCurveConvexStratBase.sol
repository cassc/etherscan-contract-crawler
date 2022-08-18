//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import '../interfaces/ICurvePool2.sol';
import './CurveConvexExtraStratBaseUSDC.sol';
import '../utils/Constants.sol';

abstract contract FraxCurveConvexStratBase is CurveConvexExtraStratBaseUSDC {
    using SafeERC20 for IERC20Metadata;

    uint256 constant SAME_POOL_TOKEN_ID = 1;
    int128 constant FRAX_USDC_POOL_USDC_ID = 1;
    int128 constant CRVFRAX_TOKEN_POOL_CRVFRAX_ID = 1;

    // fraxUsdcPool = FRAX + USDC => crvFrax
    ICurvePool2 public fraxUsdcPool;
    IERC20Metadata public fraxUsdcPoolLp; // crvFrax
    // crvFraxTokenPool = crvFrax + Token
    ICurvePool2 public crvFraxTokenPool;
    IERC20Metadata public crvFraxTokenPoolLp;

    constructor(
        Config memory config,
        address fraxUsdcPoolAddr,
        address fraxUsdcPoolLpAddr,
        address poolAddr,
        address poolLPAddr,
        address rewardsAddr,
        uint256 poolPID,
        address tokenAddr,
        address extraRewardsAddr,
        address extraTokenAddr
    )
        CurveConvexExtraStratBaseUSDC(
            config,
            poolLPAddr,
            rewardsAddr,
            poolPID,
            tokenAddr,
            extraRewardsAddr,
            extraTokenAddr
        )
    {
        fraxUsdcPool = ICurvePool2(fraxUsdcPoolAddr);
        fraxUsdcPoolLp = IERC20Metadata(fraxUsdcPoolLpAddr);

        crvFraxTokenPool = ICurvePool2(poolAddr);
        crvFraxTokenPoolLp = IERC20Metadata(poolLPAddr);

        feeTokenId = ZUNAMI_USDC_TOKEN_ID;
    }

    function checkDepositSuccessful(uint256[3] memory tokenAmounts)
        internal
        view
        override
        returns (bool isValidDepositAmount)
    {
        uint256 amountsTotal;
        for (uint256 i = 0; i < tokenAmounts.length; i++) {
            amountsTotal += tokenAmounts[i] * decimalsMultipliers[i];
        }

        uint256 amountsMin = (amountsTotal * minDepositAmount) / DEPOSIT_DENOMINATOR;

        uint256[2] memory amounts;
        amounts[SAME_POOL_TOKEN_ID] = amountsTotal / 1e12;

        uint256 lpPrice = fraxUsdcPool.get_virtual_price();
        uint256 depositedLp = fraxUsdcPool.calc_token_amount(amounts, true);

        isValidDepositAmount = (depositedLp * lpPrice) / CURVE_PRICE_DENOMINATOR >= amountsMin;
    }

    function depositPool(uint256[3] memory tokenAmounts)
        internal
        override
        returns (uint256 cvxDepositLpAmount)
    {
        uint256 usdcBalanceBefore = _config.tokens[ZUNAMI_USDC_TOKEN_ID].balanceOf(address(this));
        if (tokenAmounts[ZUNAMI_DAI_TOKEN_ID] > 0) {
            swapTokenToUSDC(IERC20Metadata(Constants.DAI_ADDRESS));
        }

        if (tokenAmounts[ZUNAMI_USDT_TOKEN_ID] > 0) {
            swapTokenToUSDC(IERC20Metadata(Constants.USDT_ADDRESS));
        }

        uint256 usdcAmount = _config.tokens[ZUNAMI_USDC_TOKEN_ID].balanceOf(address(this)) -
            usdcBalanceBefore +
            tokenAmounts[ZUNAMI_USDC_TOKEN_ID];

        uint256[2] memory amounts;
        amounts[SAME_POOL_TOKEN_ID] = usdcAmount;
        _config.tokens[ZUNAMI_USDC_TOKEN_ID].safeIncreaseAllowance(address(fraxUsdcPool), usdcAmount);
        uint256 crvFraxAmount = fraxUsdcPool.add_liquidity(amounts, 0);

        fraxUsdcPoolLp.safeIncreaseAllowance(address(crvFraxTokenPool), crvFraxAmount);
        amounts[SAME_POOL_TOKEN_ID] = crvFraxAmount;
        cvxDepositLpAmount = crvFraxTokenPool.add_liquidity(amounts, 0);

        crvFraxTokenPoolLp.safeIncreaseAllowance(address(_config.booster), cvxDepositLpAmount);
        _config.booster.depositAll(cvxPoolPID, true);
    }

    function getCurvePoolPrice() internal view override returns (uint256) {
        return crvFraxTokenPool.get_virtual_price();
    }

    function calcWithdrawOneCoin(uint256 userRatioOfCrvLps, uint128 tokenIndex)
        external
        view
        override
        returns (uint256)
    {
        uint256 removingCrvLps = (cvxRewards.balanceOf(address(this)) * userRatioOfCrvLps) / 1e18;
        uint256 crvFraxAmount = crvFraxTokenPool.calc_withdraw_one_coin(
            removingCrvLps,
            CRVFRAX_TOKEN_POOL_CRVFRAX_ID
        );

        return fraxUsdcPool.calc_withdraw_one_coin(crvFraxAmount, FRAX_USDC_POOL_USDC_ID);
    }

    function calcSharesAmount(uint256[3] memory tokenAmounts, bool isDeposit)
        external
        view
        override
        returns (uint256)
    {
        uint256[2] memory amounts = convertZunamiTokensToFraxUsdcs(tokenAmounts, isDeposit);
        return crvFraxTokenPool.calc_token_amount(amounts, isDeposit);
    }

    function convertZunamiTokensToFraxUsdcs(uint256[3] memory tokenAmounts, bool isDeposit)
        internal
        view
        returns (uint256[2] memory amounts)
    {
        amounts[SAME_POOL_TOKEN_ID] = tokenAmounts[0] / 1e12 + tokenAmounts[1] + tokenAmounts[2];
        amounts[SAME_POOL_TOKEN_ID] = fraxUsdcPool.calc_token_amount(amounts, isDeposit);
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
        removingCrvLps = (cvxRewards.balanceOf(address(this)) * userRatioOfCrvLps) / 1e18;

        uint256[2] memory minAmounts = convertZunamiTokensToFraxUsdcs(tokenAmounts, false);
        success = removingCrvLps >= crvFraxTokenPool.calc_token_amount(minAmounts, false);

        tokenAmountsDynamic = new uint256[](2);
    }

    function removeCrvLps(
        uint256 removingCrvLps,
        uint256[] memory tokenAmountsDynamic,
        WithdrawalType withdrawalType,
        uint256[3] memory tokenAmounts,
        uint128 tokenIndex
    ) internal override {
        removeCrvLpsInternal(removingCrvLps, tokenAmounts[ZUNAMI_USDC_TOKEN_ID]);
    }

    function removeCrvLpsInternal(
        uint256 removingCrvLps,
        uint256 minUsdcAmount
    ) internal {
        uint256 crvFraxAmount = crvFraxTokenPool.remove_liquidity_one_coin(
            removingCrvLps,
            CRVFRAX_TOKEN_POOL_CRVFRAX_ID,
            0
        );

        fraxUsdcPool.remove_liquidity_one_coin(
            crvFraxAmount,
            FRAX_USDC_POOL_USDC_ID,
            minUsdcAmount
        );
    }

    function withdrawAllSpecific() internal override {
        removeCrvLpsInternal(
            crvFraxTokenPoolLp.balanceOf(address(this)),
            0
        );
    }

    function sellToken() public {
        uint256 sellBal = token.balanceOf(address(this));
        if (sellBal > 0) {
            token.safeApprove(address(crvFraxTokenPool), sellBal);
            crvFraxTokenPool.exchange_underlying(0, 1, sellBal, 0);
        }
    }

    function swapTokenToUSDC(IERC20Metadata token) internal {
        address[] memory path = new address[](3);
        path[0] = address(token);
        path[1] = Constants.WETH_ADDRESS;
        path[2] = Constants.USDC_ADDRESS;

        uint256 balance = token.balanceOf(address(this));
        if (balance == 0) return;

        token.safeApprove(address(_config.router), balance);
        _config.router.swapExactTokensForTokens(
            balance,
            0,
            path,
            address(this),
            block.timestamp + Constants.TRADE_DEADLINE
        );
    }
}