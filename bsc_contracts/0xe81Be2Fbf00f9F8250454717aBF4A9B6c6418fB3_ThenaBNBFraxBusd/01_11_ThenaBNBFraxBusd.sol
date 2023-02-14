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

contract ThenaBNBFraxBusd is DefiiWithCustomEnter {
    IERC20 constant THE = IERC20(0xF4C8E32EaDEC4BFe97E0F595AdD0f4450a863a11);
    IERC20 constant FRAX = IERC20(0x90C97F71E18723b0Cf0dfa30ee176Ab653E89F40);
    IERC20 constant BUSD = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    IERC20 constant pair = IERC20(0x7fCfE6b06C1F6AAd14884bA24A7f315C1c0C2cEf);

    IRouter constant router =
        IRouter(0x20a304a7d126758dfe6B243D0fc515F83bCA8431);
    IGaugeV2 constant gauge =
        IGaugeV2(0x19549316a62f1D333cA7656bA634ba3cAB843348);

    function enterParams(uint256 slippage)
        external
        view
        returns (bytes memory enterParams)
    {
        require(slippage < 1200, "Slippage must be less than 1200(120%)");
        require(slippage > 900, "Slippage must be higher than 900(90%)");

        (uint256 reserveA, uint256 reserveB) = router.getReserves(
            address(FRAX),
            address(BUSD),
            true
        );
        uint256 busdBalance = BUSD.balanceOf(address(this));

        uint256 busdToSwap = (((reserveA * 1e3) /
            (reserveA + reserveB) -
            (reserveA * busdBalance * 1e3) /
            ((reserveA + reserveB)**2 +
                reserveA *
                busdBalance +
                reserveB *
                busdBalance)) * busdBalance) / 1e3;

        busdToSwap = (busdToSwap * 999) / 1000;
        IRouter.route[] memory routes = new IRouter.route[](1);
        routes[0].from = address(BUSD);
        routes[0].to = address(FRAX);
        routes[0].stable = true;
        uint256[] memory amounts = router.getAmountsOut(busdToSwap, routes);
        return
            abi.encode(
                busdToSwap,
                (amounts[amounts.length - 1] * slippage) / 1000
            );
    }

    function _enterWithParams(bytes memory params) internal override {
        (uint256 busdSwapAmount, uint256 fraxMinOut) = abi.decode(
            params,
            (uint256, uint256)
        );

        BUSD.approve(address(router), busdSwapAmount);
        uint256[] memory amounts = router.swapExactTokensForTokensSimple(
            busdSwapAmount,
            fraxMinOut,
            address(BUSD),
            address(FRAX),
            true,
            address(this),
            block.timestamp
        );
        uint256 busdBalance = BUSD.balanceOf(address(this));
        _enter(amounts[1], busdBalance);
    }

    function _enter() internal override {
        uint256 fraxAmount = FRAX.balanceOf(address(this));
        uint256 busdAmount = BUSD.balanceOf(address(this));
        _enter(fraxAmount, busdAmount);
    }

    function _enter(uint256 fraxAmount, uint256 busdAmount) internal {
        FRAX.approve(address(router), fraxAmount);
        BUSD.approve(address(router), busdAmount);
        (, , uint256 liquidity) = router.addLiquidity(
            address(FRAX),
            address(BUSD),
            true,
            fraxAmount,
            busdAmount,
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
            address(BUSD),
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
        withdrawERC20(BUSD);
        withdrawERC20(FRAX);
    }

    function _harvest() internal override {
        gauge.getReward();
        _claimIncentive(THE);
    }
}