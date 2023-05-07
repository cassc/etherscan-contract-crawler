//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import "../../../../curve/interfaces/ICurvePool2.sol";
import "../CurveStakeDaoExtraApsStratBase.sol";
import "../../../../../interfaces/IZunamiVault.sol";
import "../../../../../interfaces/IZunamiStableVault.sol";

//import "hardhat/console.sol";

abstract contract FraxCurveStakeDaoApsStratBase is CurveStakeDaoExtraApsStratBase {
    using SafeERC20 for IERC20Metadata;

    uint128 constant ZUNAMI_USDC_TOKEN_ID = 1;

    uint256 constant FRAX_USDC_POOL_USDC_ID = 1;
    int128 constant FRAX_USDC_POOL_USDC_ID_INT = 1;
    uint256 constant CRVFRAX_TOKEN_POOL_TOKEN_ID = 0;
    int128 constant CRVFRAX_TOKEN_POOL_TOKEN_ID_INT = 0;
    uint256 constant CRVFRAX_TOKEN_POOL_CRVFRAX_ID = 1;
    int128 constant CRVFRAX_TOKEN_POOL_CRVFRAX_ID_INT = 1;

    IZunamiVault public zunamiPool;
    IZunamiStableVault public zunamiStable;

    // fraxUsdcPool = FRAX + USDC => crvFrax
    ICurvePool2 public fraxUsdcPool;
    IERC20Metadata public fraxUsdcPoolLp; // crvFrax
    // crvFraxTokenPool = crvFrax + Token
    ICurvePool2 public crvFraxTokenPool;
    IERC20Metadata public crvFraxTokenPoolLp;

    constructor(
        Config memory config,
        address zunamiPoolAddr,
        address zunamiStableAddr,
        address fraxUsdcPoolAddr,
        address fraxUsdcPoolLpAddr,
        address crvFraxTokenPoolAddr,
        address crvFraxTokenPoolLpAddr,
        address vaultAddr,
        address tokenAddr,
        address extraRewardTokenAddr
    )
        CurveStakeDaoExtraApsStratBase(
            config,
            vaultAddr,
            crvFraxTokenPoolLpAddr,
            tokenAddr,
            extraRewardTokenAddr
        )
    {
        zunamiPool = IZunamiVault(zunamiPoolAddr);
        zunamiStable = IZunamiStableVault(zunamiStableAddr);

        fraxUsdcPool = ICurvePool2(fraxUsdcPoolAddr);
        fraxUsdcPoolLp = IERC20Metadata(fraxUsdcPoolLpAddr);

        crvFraxTokenPool = ICurvePool2(crvFraxTokenPoolAddr);
        crvFraxTokenPoolLp = IERC20Metadata(crvFraxTokenPoolLpAddr);
    }

    function checkDepositSuccessful(uint256 tokenAmount)
        internal
        view
        override
        returns (bool isValidDepositAmount)
    {
        uint256 amountsMin = (tokenAmount * minDepositAmount) / DEPOSIT_DENOMINATOR;

        uint256[2] memory amounts;
        amounts[CRVFRAX_TOKEN_POOL_TOKEN_ID] = tokenAmount;

        uint256 lpPrice = crvFraxTokenPool.get_virtual_price();
        uint256 depositedLp = crvFraxTokenPool.calc_token_amount(amounts, true);

        isValidDepositAmount = (depositedLp * lpPrice) / CURVE_PRICE_DENOMINATOR >= amountsMin;
    }

    function depositPool(uint256 tokenAmount, uint256 usdcAmount)
        internal
        override
        returns (uint256 poolLpAmount)
    {
        uint256 crvFraxAmount;

        if(usdcAmount > 0) {
            uint256[2] memory amounts;
            amounts[FRAX_USDC_POOL_USDC_ID] = usdcAmount;
            IERC20Metadata(Constants.USDC_ADDRESS).safeIncreaseAllowance(
                address(fraxUsdcPool),
                usdcAmount
            );

            crvFraxAmount = fraxUsdcPool.add_liquidity(amounts, 0);
            fraxUsdcPoolLp.safeIncreaseAllowance(address(crvFraxTokenPool), crvFraxAmount);
        }

        if(tokenAmount > 0) {
            token.safeIncreaseAllowance(address(crvFraxTokenPool), tokenAmount);
        }

        uint256[2] memory tokenPoolAmounts;
        tokenPoolAmounts[CRVFRAX_TOKEN_POOL_TOKEN_ID] = tokenAmount;
        tokenPoolAmounts[CRVFRAX_TOKEN_POOL_CRVFRAX_ID] = crvFraxAmount;
        poolLpAmount = crvFraxTokenPool.add_liquidity(tokenPoolAmounts, 0);

        crvFraxTokenPoolLp.safeIncreaseAllowance(address(vault), poolLpAmount);

        vault.deposit(address(this), poolLpAmount, true);
    }

    function getCurvePoolPrice() internal view override returns (uint256) {
        return crvFraxTokenPool.get_virtual_price();
    }

    function calcWithdrawOneCoin(uint256 userRatioOfCrvLps)
        external
        view
        override
        returns (uint256)
    {
        uint256 removingCrvLps = (vault.liquidityGauge().balanceOf(address(this)) *
        userRatioOfCrvLps) / 1e18;

        return crvFraxTokenPool.calc_withdraw_one_coin(removingCrvLps, CRVFRAX_TOKEN_POOL_TOKEN_ID_INT);
    }

    function calcSharesAmount(uint256 tokenAmount, bool isDeposit)
        external
        view
        override
        returns (uint256)
    {
        uint256[2] memory tokenAmounts2;
        tokenAmounts2[CRVFRAX_TOKEN_POOL_TOKEN_ID] = tokenAmount;
        return crvFraxTokenPool.calc_token_amount(tokenAmounts2, isDeposit);
    }

    function calcCrvLps(
        uint256 userRatioOfCrvLps, // multiplied by 1e18
        uint256 tokenAmount
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
        removingCrvLps = (vault.liquidityGauge().balanceOf(address(this)) *
        userRatioOfCrvLps) / 1e18;

        uint256[2] memory minAmounts;
        minAmounts[CRVFRAX_TOKEN_POOL_TOKEN_ID] = tokenAmount;
        success = removingCrvLps >= crvFraxTokenPool.calc_token_amount(minAmounts, false);

        tokenAmountsDynamic = new uint256[](2);
    }

    function removeCrvLps(
        uint256 removingCrvLps,
        uint256[] memory,
        uint256 tokenAmount
    ) internal override {
        removeCrvLpsInternal(removingCrvLps, tokenAmount);
    }

    function removeCrvLpsInternal(uint256 removingCrvLps, uint256 minTokenAmount) internal {
        crvFraxTokenPool.remove_liquidity_one_coin(
            removingCrvLps,
            CRVFRAX_TOKEN_POOL_TOKEN_ID_INT,
            minTokenAmount
        );
    }

    function withdrawAllSpecific() internal override {
        removeCrvLpsInternal(crvFraxTokenPoolLp.balanceOf(address(this)), 0);
    }

    function inflate(uint256 ratioOfCrvLps, uint256 minInflatedAmount) external onlyOwner {
        uint256 removingCrvLps = (vault.liquidityGauge().balanceOf(address(this)) *
            ratioOfCrvLps) / 1e18;

        vault.withdraw(removingCrvLps);

        uint256 crvFraxAmount = crvFraxTokenPool.remove_liquidity_one_coin(
            removingCrvLps,
            CRVFRAX_TOKEN_POOL_CRVFRAX_ID_INT,
            0
        );

        uint256 usdcAmount = fraxUsdcPool.remove_liquidity_one_coin(
            crvFraxAmount,
            FRAX_USDC_POOL_USDC_ID_INT,
            minInflatedAmount
        );

        IERC20Metadata(Constants.USDC_ADDRESS).safeIncreaseAllowance(address(zunamiPool), usdcAmount);
        uint256 zlpAmount = zunamiPool.deposit([0,usdcAmount,0]);

        IERC20Metadata(address(zunamiPool)).safeIncreaseAllowance(address(zunamiStable), zlpAmount);
        zunamiStable.deposit(zlpAmount, address(this));

        uint256 uzdAmount = IERC20Metadata(address(zunamiStable)).balanceOf(address(this));

        depositPool(uzdAmount, 0);
    }

    function deflate(uint256 ratioOfCrvLps, uint256 minDeflateAmount) external onlyOwner {
        uint256 removingCrvLps = (vault.liquidityGauge().balanceOf(address(this)) *
            ratioOfCrvLps) / 1e18;

        vault.withdraw(removingCrvLps);

        uint256 tokenAmount = crvFraxTokenPool.remove_liquidity_one_coin(
            removingCrvLps,
            CRVFRAX_TOKEN_POOL_TOKEN_ID_INT,
            0
        );

        IERC20Metadata(address(zunamiStable)).safeIncreaseAllowance(address(zunamiStable), tokenAmount);
        zunamiStable.withdraw(tokenAmount, address(this), address(this));

        uint256 zlpAmount = IERC20Metadata(address(zunamiPool)).balanceOf(address(this));

        IERC20Metadata(address(zunamiPool)).safeIncreaseAllowance(address(zunamiPool), zlpAmount);
        zunamiPool.withdraw(
            zlpAmount,
            [0, minDeflateAmount, 0],
            IStrategy.WithdrawalType.OneCoin,
            ZUNAMI_USDC_TOKEN_ID
        );

        uint256 usdcAmount = IERC20Metadata(Constants.USDC_ADDRESS).balanceOf(address(this));

        depositPool(0, usdcAmount - managementFees);
    }
}