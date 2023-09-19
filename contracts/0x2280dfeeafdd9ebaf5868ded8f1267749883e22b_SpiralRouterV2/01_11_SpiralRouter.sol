// SPDX-License-Identifier: GPL-3.0-or-later.
// Copyright (C) 2023 Spiral DAO, [email protected]
// Full Notice is available in the root folder.
pragma solidity 0.8.16;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {
    IStaking,
    IERC20,
    IVirtualRebaseViewer,
    IBalancerVault,
    IBalancerPool,
    ICurveZap,
    ICurvePool,
    IMaverickPool,
    IMaverickFactory,
    RouterConstants
} from "./Helper.sol";

contract SpiralRouterV2 {
    using SafeERC20 for IERC20;

    constructor() {
        _refreshAllowances();
    }

    function refreshAllowances() external {
        _refreshAllowances();
    }

    function _refreshAllowances() internal {
        IERC20(RouterConstants.coil).forceApprove(address(RouterConstants.staking), type(uint256).max);
        IERC20(RouterConstants.spiral).forceApprove(address(RouterConstants.staking), type(uint256).max);

        IERC20(RouterConstants.coil).forceApprove(address(RouterConstants.balVault), type(uint256).max);
        IERC20(RouterConstants.usdc).forceApprove(address(RouterConstants.balVault), type(uint256).max);

        IERC20(RouterConstants.coil).forceApprove(address(RouterConstants.curvePool), type(uint256).max);
        IERC20(RouterConstants.usdc).forceApprove(address(RouterConstants.curvePool), type(uint256).max);

        IERC20(RouterConstants.coil).forceApprove(address(RouterConstants.curveZap), type(uint256).max);
        IERC20(RouterConstants.usdc).forceApprove(address(RouterConstants.curveZap), type(uint256).max);

        IERC20(RouterConstants.coil).forceApprove(address(RouterConstants.maverickPool), type(uint256).max);
        IERC20(RouterConstants.usdc).forceApprove(address(RouterConstants.maverickPool), type(uint256).max);
    }

    function swap(address tokenIn, address tokenOut, uint256[3] calldata amounts, uint256 minAmountOut) external {
        uint256 amountIn = amounts[0] + amounts[1] + amounts[2];
        uint256 amountCurve = amounts[0];
        uint256 amountBalancer = amounts[1];
        uint256 amountMaverick = amounts[2];
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        if (tokenIn == address(RouterConstants.spiral)) {
            RouterConstants.staking.unstake(amountIn);
            uint256 index_ = RouterConstants.staking.index();
            tokenIn = address(RouterConstants.coil);
            amountIn = RouterConstants.coil.balanceOf(address(this));
            amountCurve = amountCurve * index_ / 1e18;
            amountBalancer = amountBalancer * index_ / 1e18;
            amountMaverick = amountMaverick * index_ / 1e18;
        }
        address tokenOut_ = tokenOut;
        if (tokenOut == address(RouterConstants.spiral)) {
            tokenOut_ = address(RouterConstants.coil);
        }
        uint256 balanceBefore = IERC20(tokenOut_).balanceOf(address(this));
        if (amountCurve > 0) {
            curveSwap(IERC20(tokenIn), IERC20(tokenOut_), amountCurve);
        }
        if (amountBalancer > 0) {
            balancerSwap(tokenIn, tokenOut_, amountBalancer);
        }
        if (amountMaverick > 0) {
            maverickSwap(tokenIn, tokenOut_, IERC20(tokenIn).balanceOf(address(this)));
        }
        uint256 actualOut = IERC20(tokenOut_).balanceOf(address(this)) - balanceBefore;
        if (tokenOut == address(RouterConstants.spiral)) {
            RouterConstants.staking.stake(actualOut);
            require(RouterConstants.spiral.balanceOf(address(this)) >= minAmountOut, "slippage");
            RouterConstants.spiral.safeTransfer(msg.sender, RouterConstants.spiral.balanceOf(address(this)));
        } else {
            require(actualOut >= minAmountOut, "slippage");
            IERC20(tokenOut).safeTransfer(msg.sender, actualOut);
        }
    }

    function curveSwap(IERC20 tokenIn, IERC20 tokenOut, uint256 amountIn) internal {
        ICurvePool pool = ICurvePool(RouterConstants.curvePool);
        uint256 i;
        uint256 j;
        if (address(tokenIn) == address(RouterConstants.coil)) {
            i = 0;
            j = 2;
        } else {
            i = 2;
            j = 0;
        }
        RouterConstants.curveZap.exchange(address(pool), i, j, amountIn, 0);
    }

    function balancerSwap(address tokenIn, address tokenOut, uint256 amountIn) internal {
        RouterConstants.balVault.swap(
            IBalancerVault.SingleSwap(
                RouterConstants.balancerPoolId,
                IBalancerVault.SwapKind.GIVEN_IN,
                tokenIn,
                tokenOut,
                amountIn,
                new bytes(0)
            ),
            IBalancerVault.FundManagement(address(this), false, payable(address(this)), false),
            0,
            block.timestamp
        );
    }

    function maverickSwap(address tokenIn, address tokenOut, uint256 amount) internal {
        IMaverickPool pool = RouterConstants.maverickPool;

        pool.swap(
            address(this),
            amount,
            tokenIn < tokenOut,
            false,
            0,
            abi.encode(
                IMaverickPool.SwapCallbackData({
                    path: abi.encodePacked(tokenIn, address(pool), tokenOut),
                    payer: address(this),
                    exactOutput: false
                })
            )
        );
    }

    /**
     * @dev required to perform maverick swap
     */
    function swapCallback(uint256 amountToPay, uint256 amountOut, bytes calldata _data) external {
        require(amountToPay > 0 && amountOut > 0);
        require(RouterConstants.maverickFactory.isFactoryPool(msg.sender));

        IMaverickPool.SwapCallbackData memory data = abi.decode(_data, (IMaverickPool.SwapCallbackData));

        bytes memory path = data.path;
        address tokenToPay;
        address pool;
        assembly ("memory-safe") {
            tokenToPay := div(mload(add(add(path, 0x20), 0)), 0x1000000000000000000000000)
            pool := div(mload(add(add(path, 0x34), 0)), 0x1000000000000000000000000)
        }
        require(msg.sender == pool);

        IERC20(tokenToPay).safeTransfer(pool, amountToPay);
    }
}