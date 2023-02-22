// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {DefiiWithCustomEnter} from "../DefiiWithCustomEnter.sol";

interface IRouter {
    struct route {
        address from;
        address to;
        bool stable;
    }

    function getReserves(
        address tokenA,
        address tokenB,
        bool stable
    ) external view returns (uint256 reserveA, uint256 reserveB);

    function getAmountsOut(uint256 amountIn, route[] memory routes)
        external
        view
        returns (uint256[] memory amounts);

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

interface IGaugeV2 {
    function balanceOf(address account) external view returns (uint256);

    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;
}

contract ThenaBNBUsdtFrax is DefiiWithCustomEnter {
    IERC20 constant THE = IERC20(0xF4C8E32EaDEC4BFe97E0F595AdD0f4450a863a11);
    IERC20 constant FRAX = IERC20(0x90C97F71E18723b0Cf0dfa30ee176Ab653E89F40);
    IERC20 constant USDT = IERC20(0x55d398326f99059fF775485246999027B3197955);
    IERC20 constant pair = IERC20(0x8D65dBe7206A768C466073aF0AB6d76f9e14Fc6D);

    IRouter constant router =
        IRouter(0xd4ae6eCA985340Dd434D38F470aCCce4DC78D109);
    IGaugeV2 constant gauge =
        IGaugeV2(0x4b1F8AC4C46348919B70bCAB62443EeAfB770Aa4);

    function enterParams(uint256 slippage)
        external
        view
        returns (bytes memory enterParams)
    {
        require(slippage < 1200, "Slippage must be less than 1200(120%)");
        require(slippage > 900, "Slippage must be higher than 900(90%)");

        (uint256 reserveA, uint256 reserveB) = router.getReserves(
            address(FRAX),
            address(USDT),
            true
        );
        uint256 usdtBalance = USDT.balanceOf(address(this));

        uint256 usdtToSwap = (((reserveA * 1e3) /
            (reserveA + reserveB) -
            (reserveA * usdtBalance * 1e3) /
            ((reserveA + reserveB)**2 +
                reserveA *
                usdtBalance +
                reserveB *
                usdtBalance)) * usdtBalance) / 1e3;

        usdtToSwap = (usdtToSwap * 999) / 1000;
        IRouter.route[] memory routes = new IRouter.route[](1);
        routes[0].from = address(USDT);
        routes[0].to = address(FRAX);
        routes[0].stable = true;
        uint256[] memory amounts = router.getAmountsOut(usdtToSwap, routes);
        return
            abi.encode(
                usdtToSwap,
                (amounts[amounts.length - 1] * slippage) / 1000
            );
    }

    function _enterWithParams(bytes memory params) internal override {
        (uint256 usdtSwapAmount, uint256 fraxMinOut) = abi.decode(
            params,
            (uint256, uint256)
        );

        USDT.approve(address(router), usdtSwapAmount);
        uint256[] memory amounts = router.swapExactTokensForTokensSimple(
            usdtSwapAmount,
            fraxMinOut,
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
        uint256 fraxAmount = FRAX.balanceOf(address(this));
        uint256 usdtAmount = USDT.balanceOf(address(this));
        _enter(fraxAmount, usdtAmount);
    }

    function _enter(uint256 fraxAmount, uint256 usdtAmount) internal {
        FRAX.approve(address(router), fraxAmount);
        USDT.approve(address(router), usdtAmount);
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
        gauge.deposit(liquidity);
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
        gauge.getReward();
        _claimIncentive(THE);
    }
}