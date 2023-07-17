// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../errors.sol";
import {IEuler} from "./interfaces.sol";
import {BaseLending} from "./BaseLending.sol";
import {IEulerMarkets, IEToken, IDToken} from "../interfaces/external/IEuler.sol";

contract Euler is IEuler, BaseLending {
    using SafeERC20 for IERC20;

    uint256 constant SUBACCOUNT_ID = 0;

    address constant EULER = 0x27182842E098f60e3D576794A5bFFb0777E025d3;
    IEulerMarkets constant EULER_MARKETS =
        IEulerMarkets(0x3520d5a913427E6F0D6A83E07ccD4A4da316e4d3);

    IUniswapV3Pool constant uniswapPool =
        IUniswapV3Pool(0x3416cF6C708Da44DB2624D63ea0AAef7113527C6);

    function supplyEuler() external onlyOwner {
        _supplyEuler(WBTC);
        _supplyEuler(WETH);
        _supplyEuler(stETH);
        _supplyEuler(wstETH);
    }

    function borrowEuler(IERC20 token, uint256 amount)
        external
        checkToken(token)
        onlyOwner
    {
        IDToken dToken = IDToken(
            EULER_MARKETS.underlyingToDToken(address(token))
        );
        dToken.borrow(SUBACCOUNT_ID, amount);
        _withdrawERC20(token);
    }

    function repayEuler() external onlyOwner {
        _repayEuler(USDT);
        _repayEuler(USDC);
    }

    function withdrawEuler(IERC20 token, uint256 amount) external onlyOwner {
        if (amount == 0) {
            amount = type(uint256).max;
        }

        IEToken eToken = IEToken(
            EULER_MARKETS.underlyingToEToken(address(token))
        );
        eToken.withdraw(SUBACCOUNT_ID, amount);
        _withdrawERC20(token);
    }

    function swapStables(bool usdtToUsdc) external onlyOwner {
        IERC20 token = usdtToUsdc ? USDT : USDC;
        IDToken dToken = IDToken(
            EULER_MARKETS.underlyingToDToken(address(token))
        );
        uint256 debtAmount = dToken.balanceOf(address(this));
        uint256 amount = token.balanceOf(address(this));

        // TODO: fix me
        uint160 sqrtPriceLimitX96;
        if (usdtToUsdc) {
            // int(0.999**0.5 * 2**96)
            sqrtPriceLimitX96 = 79188538524532037328677371904;
        } else {
            // int(1.001**0.5 * 2**96)
            sqrtPriceLimitX96 = 79267766696949822870343647232;
        }
        uniswapPool.swap(
            address(this),
            usdtToUsdc,
            int256(amount) - int256(debtAmount),
            sqrtPriceLimitX96,
            bytes("")
        );
    }

    function uniswapV3SwapCallback(
        int256 amount0,
        int256 amount1,
        bytes calldata
    ) external {
        require(msg.sender == address(uniswapPool));

        IERC20 token;
        uint256 newDebtAmount;

        // USDC -> USDT
        if (amount0 < 0) {
            _repayEuler(USDC);
            token = USDT;
            newDebtAmount = uint256(amount1);
        } else {
            _repayEuler(USDT);
            token = USDC;
            newDebtAmount = uint256(amount0);
        }

        IDToken dToken = IDToken(
            EULER_MARKETS.underlyingToDToken(address(token))
        );
        dToken.borrow(SUBACCOUNT_ID, newDebtAmount);

        token.safeTransfer(address(uniswapPool), newDebtAmount);
    }

    function _supplyEuler(IERC20 token) internal {
        uint256 balance = token.balanceOf(address(this));
        if (balance == 0) return;

        IEToken eToken = IEToken(
            EULER_MARKETS.underlyingToEToken(address(token))
        );
        eToken.deposit(SUBACCOUNT_ID, balance);
    }

    function _repayEuler(IERC20 token) internal {
        uint256 balance = token.balanceOf(address(this));
        if (balance == 0) return;

        IDToken dToken = IDToken(
            EULER_MARKETS.underlyingToDToken(address(token))
        );
        dToken.repay(SUBACCOUNT_ID, balance);
        _withdrawERC20(token);
    }

    function _postInit() internal virtual override {
        WBTC.safeApprove(EULER, type(uint256).max);
        WETH.approve(EULER, type(uint256).max);
        stETH.safeApprove(EULER, type(uint256).max);
        wstETH.safeApprove(EULER, type(uint256).max);
        USDC.safeApprove(EULER, type(uint256).max);
        USDT.safeApprove(EULER, type(uint256).max);

        EULER_MARKETS.enterMarket(SUBACCOUNT_ID, address(WBTC));
        EULER_MARKETS.enterMarket(SUBACCOUNT_ID, address(WETH));
        EULER_MARKETS.enterMarket(SUBACCOUNT_ID, address(stETH));
        EULER_MARKETS.enterMarket(SUBACCOUNT_ID, address(wstETH));
    }
}

interface IUniswapV3Pool {
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);
}