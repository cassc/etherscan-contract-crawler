//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import '../../../../interfaces/ICurvePool.sol';
import "../../../interfaces/ICurvePool2.sol";
import "../../../interfaces/IStableConverter.sol";
import "../CurveStakeDaoExtraStratBase.sol";

//import "hardhat/console.sol";

contract UsdtCurveStakeDaoStrat is CurveStakeDaoExtraStratBase {
    using SafeERC20 for IERC20Metadata;

    uint128 public constant CURVE_POOL_USDT_ID = 0;
    int128 public constant CURVE_POOL_USDT_ID_INT = int128(CURVE_POOL_USDT_ID);

    ICurvePool2 public immutable pool;

    IStableConverter public stableConverter;

    event SetStableConverter(address stableConverter);

    constructor(
        Config memory config,
        address vaultAddr,
        address poolLPAddr,
        address tokenAddr,
        address poolAddr,
        address extraTokenAddr
    ) CurveStakeDaoExtraStratBase(config, vaultAddr, poolLPAddr, tokenAddr, extraTokenAddr) {
        pool = ICurvePool2(poolAddr);
    }

    function setStableConverter(address stableConverterAddr) external onlyOwner {
        stableConverter = IStableConverter(stableConverterAddr);
        emit SetStableConverter(stableConverterAddr);
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

        uint256 lpPrice = pool.get_virtual_price();
        uint256 depositedLp = pool.calc_token_amount(calcPoolUsdtAmounts(amounts), true);

        return (depositedLp * lpPrice) / CURVE_PRICE_DENOMINATOR >= amountsMin;
    }

    function depositPool(uint256[3] memory amounts) internal override returns (uint256 poolLPs) {
        IERC20Metadata usdt = _config.tokens[ZUNAMI_USDT_TOKEN_ID];

        for (uint256 i = 0; i < 2; i++) { //convert USDC and DAI to USDT
            convertZunamiStableToUsdt(i, amounts[i]);
        }

        uint256[2] memory amounts2;
        amounts2[CURVE_POOL_USDT_ID] = usdt.balanceOf(address(this)) - managementFees;
        usdt.safeIncreaseAllowance(address(pool), amounts2[CURVE_POOL_USDT_ID]);
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
        uint256 amount = pool.calc_withdraw_one_coin(removingCrvLps, CURVE_POOL_USDT_ID_INT);

        if(tokenIndex == ZUNAMI_USDT_TOKEN_ID) return amount;

        return stableConverter.valuate(
            address(_config.tokens[ZUNAMI_USDT_TOKEN_ID]),
            address(_config.tokens[tokenIndex]),
            amount
        );
    }

    function calcSharesAmount(uint256[3] memory tokenAmounts, bool isDeposit)
        external
        view
        override
        returns (uint256 sharesAmount)
    {
        return pool.calc_token_amount(calcPoolUsdtAmounts(tokenAmounts), isDeposit);
    }

    function calcCrvLps(
        WithdrawalType,
        uint256 userRatioOfCrvLps, // multiplied by 1e18
        uint256[3] memory tokenAmounts,
        uint128
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
        removingCrvLps =
            (vault.liquidityGauge().balanceOf(address(this)) * userRatioOfCrvLps) /
            1e18;

        success = removingCrvLps >= pool.calc_token_amount(calcPoolUsdtAmounts(tokenAmounts), false);

        tokenAmountsDynamic = new uint256[](2);
    }

    function removeCrvLps(
        uint256 removingCrvLps,
        uint256[] memory,
        WithdrawalType withdrawalType,
        uint256[3] memory tokenAmounts,
        uint128 tokenIndex
    ) internal override {
        pool.remove_liquidity_one_coin(removingCrvLps, CURVE_POOL_USDT_ID_INT, calcPoolUsdtAmounts(tokenAmounts)[CURVE_POOL_USDT_ID]);

        if (withdrawalType == WithdrawalType.OneCoin) {
            convertUsdtToZunamiStable(
                tokenIndex,
                _config.tokens[ZUNAMI_USDT_TOKEN_ID].balanceOf(address(this)) - managementFees
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
        pool.remove_liquidity_one_coin(poolLP.balanceOf(address(this)), CURVE_POOL_USDT_ID_INT, 0);
    }

    function calcPoolUsdtAmounts(uint256[3] memory amounts) internal view returns(uint256[2] memory amounts2) {
        if(
            amounts[ZUNAMI_USDT_TOKEN_ID] == 0 &&
            amounts[ZUNAMI_USDC_TOKEN_ID] == 0 &&
            amounts[ZUNAMI_DAI_TOKEN_ID] == 0
        ) return [uint256(0),0];

        amounts2[CURVE_POOL_USDT_ID] =
            amounts[ZUNAMI_USDT_TOKEN_ID] +
            stableConverter.valuate(
                address(_config.tokens[ZUNAMI_USDC_TOKEN_ID]),
                address(_config.tokens[ZUNAMI_USDT_TOKEN_ID]),
                amounts[ZUNAMI_USDC_TOKEN_ID]
            ) +
            stableConverter.valuate(
                address(_config.tokens[ZUNAMI_DAI_TOKEN_ID]),
                address(_config.tokens[ZUNAMI_USDT_TOKEN_ID]),
                amounts[ZUNAMI_DAI_TOKEN_ID]
            );
    }

    function convertZunamiStableToUsdt(uint256 zunamiTokenIndex, uint256 tokenAmount) internal {
        convertStables(zunamiTokenIndex, ZUNAMI_USDT_TOKEN_ID, tokenAmount);
    }

    function convertUsdtToZunamiStable(uint256 zunamiTokenIndex, uint256 usdtAmount) internal {
        convertStables(ZUNAMI_USDT_TOKEN_ID, zunamiTokenIndex, usdtAmount);
    }

    function convertStables(uint256 fromZunamiIndex, uint256 toZunamiIndex, uint256 fromAmount) internal {
        IERC20Metadata fromToken = _config.tokens[fromZunamiIndex];
        fromToken.safeTransfer(address(stableConverter), fromAmount);

        stableConverter.handle(
            address(fromToken),
            address(_config.tokens[toZunamiIndex]),
            fromAmount,
            0
        );
    }
}