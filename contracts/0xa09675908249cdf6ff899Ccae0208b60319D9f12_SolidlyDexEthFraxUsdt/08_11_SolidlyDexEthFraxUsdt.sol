// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {DefiiWithCustomEnter} from "../DefiiWithCustomEnter.sol";

contract SolidlyDexEthFraxUsdt is DefiiWithCustomEnter {
    using SafeERC20 for IERC20;

    IERC20 constant FRAX = IERC20(0x853d955aCEf822Db058eb8505911ED77F175b99e);
    IERC20 constant USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IERC20 constant pair = IERC20(0x97F088b0175A7319059d8e705286aA035077d624);

    IERC20 constant SOLID = IERC20(0x777172D858dC1599914a1C4c6c9fC48c99a60990);
    IERC20 constant FXS = IERC20(0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0);

    IRouter constant router =
        IRouter(0x77784f96C936042A3ADB1dD29C91a55EB2A4219f);
    IGauge constant gauge = IGauge(0x9972F7c292Deae7759a3831b1aDFF54dD43Dc264);

    function enterParams(uint256 slippage)
        external
        view
        returns (bytes memory)
    {
        require(slippage < 1200, "Slippage must be less than 1200(120%)");
        require(slippage > 900, "Slippage must be higher than 900(90%)");

        (uint256 reserveA, uint256 reserveB) = router.getReserves(
            address(FRAX),
            address(USDT),
            true
        );
        uint256 usdtBalance = USDT.balanceOf(address(this));

        reserveB = reserveB * 1e12;
        usdtBalance = usdtBalance * 1e12;

        uint256 usdtToSwap = (((reserveA * 1e3) /
            (reserveA + reserveB) -
            (reserveA * usdtBalance * 1e3) /
            ((reserveA + reserveB)**2 +
                reserveA *
                usdtBalance +
                reserveB *
                usdtBalance)) * usdtBalance) / 1e3;
        usdtToSwap = usdtToSwap / 1e12;

        usdtToSwap = (usdtToSwap * 999) / 1000;
        (uint256 fraxMinAmount, ) = router.getAmountOut(usdtToSwap, USDT, FRAX);
        return abi.encode(usdtToSwap, (fraxMinAmount * slippage) / 1000);
    }

    function _postInit() internal override {
        USDT.safeIncreaseAllowance(address(router), type(uint256).max);
        FRAX.approve(address(router), type(uint256).max);
    }

    function _enterWithParams(bytes memory params) internal override {
        (uint256 usdtToSwap, uint256 fraxMinAmount) = abi.decode(
            params,
            (uint256, uint256)
        );

        uint256[] memory amounts = router.swapExactTokensForTokensSimple(
            usdtToSwap,
            fraxMinAmount,
            address(USDT),
            address(FRAX),
            true,
            address(this),
            block.timestamp
        );
        uint256 usdtBalance = USDT.balanceOf(address(this));
        _enter(amounts[1], usdtBalance);
    }

    function _enter() internal override {
        uint256 fraxBalance = FRAX.balanceOf(address(this));
        uint256 usdtBalance = USDT.balanceOf(address(this));
        _enter(fraxBalance, usdtBalance);
    }

    function _enter(uint256 fraxAmount, uint256 usdtAmount) internal {
        (, , uint256 liquidity) = router.addLiquidity(
            address(FRAX),
            address(USDT),
            true,
            fraxAmount,
            usdtAmount,
            0,
            0,
            address(this),
            block.timestamp
        );

        pair.approve(address(gauge), liquidity);
        address[] memory optIns = new address[](4);
        optIns[0] = address(FRAX);
        optIns[1] = address(USDT);
        optIns[2] = address(SOLID);
        optIns[3] = address(FXS);
        gauge.depositAndOptIn(liquidity, 0, optIns);
    }

    function _exit() internal override {
        _harvest();

        uint256 lpBalance = gauge.balanceOf(address(this));
        gauge.withdraw(lpBalance);

        pair.approve(address(router), lpBalance);
        router.removeLiquidity(
            address(FRAX),
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
        withdrawERC20(FRAX);
    }

    function _harvest() internal override {
        address[] memory rewards = new address[](2);
        rewards[0] = address(SOLID);
        rewards[1] = address(FXS);

        gauge.getReward(address(this), rewards);
        _claimIncentive(SOLID);
        _claimIncentive(FXS);
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

    function swapExactTokensForTokensSimple(
        uint256 amountIn,
        uint256 amountOutMin,
        address tokenFrom,
        address tokenTo,
        bool stable,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
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