// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {DefiiWithCustomEnter} from "../DefiiWithCustomEnter.sol";

contract SolidlyDexEthUsdcUsdt is DefiiWithCustomEnter {
    using SafeERC20 for IERC20;

    IERC20 constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 constant USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IERC20 constant pair = IERC20(0x63A65a174Cc725824188940255aD41c371F28F28);

    IERC20 constant SOLID = IERC20(0x777172D858dC1599914a1C4c6c9fC48c99a60990);
    IERC20 constant moSOLID =
        IERC20(0x848578e351D25B6Ec0d486E42677891521c3d743);

    IRouter constant router =
        IRouter(0x77784f96C936042A3ADB1dD29C91a55EB2A4219f);
    IGauge constant gauge = IGauge(0x71e0E5F31a71062a08Aa629aFB8587c7A178Dfd9);

    function enterParams(uint256 slippage)
        external
        view
        returns (bytes memory)
    {
        require(slippage < 1200, "Slippage must be less than 1200(120%)");
        require(slippage > 900, "Slippage must be higher than 900(90%)");

        (uint256 reserveA, uint256 reserveB) = router.getReserves(
            address(USDC),
            address(USDT),
            true
        );
        uint256 usdcBalance = USDC.balanceOf(address(this));

        uint256 usdcToSwap = (((reserveA * 1e3) /
            (reserveA + reserveB) -
            (reserveA * usdcBalance * 1e3) /
            ((reserveA + reserveB)**2 +
                reserveA *
                usdcBalance +
                reserveB *
                usdcBalance)) * usdcBalance) / 1e3;

        usdcToSwap = (usdcToSwap * 999) / 1000;
        (uint256 usdtMinAmount, ) = router.getAmountOut(usdcToSwap, USDC, USDT);
        return abi.encode(usdcToSwap, (usdtMinAmount * slippage) / 1000);
    }

    function _postInit() internal override {
        USDT.safeIncreaseAllowance(address(router), type(uint256).max);
        USDC.approve(address(router), type(uint256).max);
    }

    function _enterWithParams(bytes memory params) internal override {
        (uint256 usdcToSwap, uint256 usdtMinAmount) = abi.decode(
            params,
            (uint256, uint256)
        );

        uint256[] memory amounts = router.swapExactTokensForTokensSimple(
            usdcToSwap,
            usdtMinAmount,
            address(USDC),
            address(USDT),
            true,
            address(this),
            block.timestamp
        );
        uint256 usdcBalance = USDC.balanceOf(address(this));
        _enter(usdcBalance, amounts[1]);
    }

    function _enter() internal override {
        uint256 usdcAmount = USDC.balanceOf(address(this));
        uint256 usdtAmount = USDT.balanceOf(address(this));
        _enter(usdcAmount, usdtAmount);
    }

    function _enter(uint256 usdcAmount, uint256 usdtAmount) internal {
        (, , uint256 liquidity) = router.addLiquidity(
            address(USDC),
            address(USDT),
            true,
            usdcAmount,
            usdtAmount,
            0,
            0,
            address(this),
            block.timestamp
        );

        pair.approve(address(gauge), liquidity);
        address[] memory optIns = new address[](4);
        optIns[0] = address(USDC);
        optIns[1] = address(USDT);
        optIns[2] = address(SOLID);
        optIns[3] = address(moSOLID);
        gauge.depositAndOptIn(liquidity, 0, optIns);
    }

    function _exit() internal override {
        _harvest();

        uint256 lpBalance = gauge.balanceOf(address(this));
        gauge.withdraw(lpBalance);

        pair.approve(address(router), lpBalance);
        router.removeLiquidity(
            address(USDC),
            address(USDT),
            true,
            lpBalance,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    function hasAllocation() public view override returns (bool) {
        return gauge.balanceOf(address(this)) > 0;
    }

    function _withdrawFunds() internal override {
        withdrawERC20(USDT);
        withdrawERC20(USDC);
    }

    function _harvest() internal override {
        address[] memory rewards = new address[](2);
        rewards[0] = address(SOLID);
        rewards[1] = address(moSOLID);

        gauge.getReward(address(this), rewards);
        _claimIncentive(SOLID);
        _claimIncentive(moSOLID);
    }
}

interface IRouter {
    function getReserves(
        address tokenA,
        address tokenB,
        bool stable
    ) external view returns (uint256 reserveA, uint256 reserveB);

    function getAmountOut(
        uint256 amountIn,
        IERC20,
        IERC20
    ) external view returns (uint256, bool);

    function swapExactTokensForTokensSimple(
        uint256 amountIn,
        uint256 amountOutMin,
        address tokenFrom,
        address tokenTo,
        bool stable,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);
}

interface IGauge {
    function balanceOf(address account) external view returns (uint256);

    function depositAndOptIn(
        uint256 amount,
        uint256 tokenId,
        address[] memory optInPools
    ) external;

    function withdraw(uint256 amount) external;

    function getReward(address account, address[] memory tokens) external;
}