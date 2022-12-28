// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Defii} from "../Defii.sol";

contract BabyDogeSwapBscUsdtBusd is Defii {
    IERC20 constant USDC = IERC20(0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d);
    IERC20 constant USDT = IERC20(0x55d398326f99059fF775485246999027B3197955);
    IERC20 constant BUSD = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    IERC20 constant BabyDoge =
        IERC20(0xc748673057861a797275CD8A068AbB95A902e8de);
    IPair constant pair = IPair(0xc769FA5aC102ffb129c2BA5F31a4d071cE454fc2);

    IRouter constant babyDogeSwapRouter =
        IRouter(0xC9a0F685F39d05D835c369036251ee3aEaaF3c47);
    IFarming constant babyDogeSwapFarming =
        IFarming(0x3FDbAF9eE8AD48d2bD9204210234afb4aD651FB0);

    IRouter constant pancakeSwapRouter =
        IRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    IWombatPool constant wombatPool =
        IWombatPool(0x312Bc7eAAF93f1C60Dc5AfC115FcCDE161055fb0);

    function hasAllocation() external view override returns (bool) {
        (uint256 shares, , ) = babyDogeSwapFarming.userInfo(address(this));
        return shares > 0;
    }

    function _enter() internal override {
        uint256 usdcAmount = USDC.balanceOf(address(this));
        USDC.approve(address(wombatPool), usdcAmount);

        // 50% USDC -> USDT (with 0.1% slippage)
        uint256 usdcForUsdt = usdcAmount / 2;
        (uint256 usdtAmount, ) = wombatPool.swap(
            address(USDC),
            address(USDT),
            usdcForUsdt,
            (usdcForUsdt * 999) / 1000,
            address(this),
            block.timestamp
        );

        // 50% USDC -> BUSD (with 0.1% slippage)
        uint256 usdcForBusd = usdcAmount - usdcForUsdt;
        (uint256 busdAmount, ) = wombatPool.swap(
            address(USDC),
            address(BUSD),
            usdcForUsdt,
            (usdcForBusd * 999) / 1000,
            address(this),
            block.timestamp
        );

        // Provide liquidity
        USDT.approve(address(babyDogeSwapRouter), usdtAmount);
        BUSD.approve(address(babyDogeSwapRouter), busdAmount);
        (, , uint256 liquidity) = babyDogeSwapRouter.addLiquidity(
            address(USDT),
            address(BUSD),
            usdtAmount,
            busdAmount,
            0,
            0,
            address(this),
            block.timestamp
        );

        // Deposit to farming
        pair.approve(address(babyDogeSwapFarming), liquidity);
        babyDogeSwapFarming.deposit(liquidity);
    }

    function _exit() internal override {
        (uint256 shares, , ) = babyDogeSwapFarming.userInfo(address(this));
        babyDogeSwapFarming.withdraw(shares);

        pair.transfer(address(pair), pair.balanceOf(address(this)));
        pair.burn(address(this));
        _claimIncentive(BabyDoge);
    }

    function _harvest() internal override {
        babyDogeSwapFarming.withdraw(0);
        _claimIncentive(BabyDoge);
    }

    function _withdrawFunds() internal override {
        withdrawERC20(USDC);
        withdrawERC20(BUSD);
        withdrawERC20(USDT);
    }
}

interface IPair is IERC20 {
    function burn(
        address to
    ) external returns (uint256 amount0, uint256 amount1);
}

interface IRouter {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);
}

interface IFarming {
    function deposit(uint256 amount) external;

    function withdraw(uint256 _shares) external;

    function userInfo(
        address wallet
    )
        external
        view
        returns (uint256 shares, uint256 rewardDebt, uint256 depositBlock);
}

interface IWombatPool {
    function swap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 actualToAmount, uint256 haircut);
}