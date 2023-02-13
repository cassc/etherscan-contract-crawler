// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {INFTLocker} from './INFTLocker.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IWETH9} from './IWETH9.sol';

import {ISwapRouter} from '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import {TransferHelper} from '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';

contract ETHMahaXLocker {
    INFTLocker public locker;
    ISwapRouter public router;
    IERC20 public maha;
    IWETH9 public weth9;

    address private me;

    constructor(
        address _locker,
        address _maha,
        address _weth,
        address _router
    ) {
        locker = INFTLocker(_locker);
        maha = IERC20(_maha);
        weth9 = IWETH9(_weth);

        maha.approve(_locker, type(uint256).max);
        maha.approve(_router, type(uint256).max);
        weth9.approve(_router, type(uint256).max);

        router = ISwapRouter(_router);

        me = address(this);
    }

    receive() external payable {
        // nothing
    }

    // convert maha into NFTs
    function createLocks(uint256 count, uint256 amount) public {
        // take maha from the user
        maha.transferFrom(msg.sender, me, amount * count);

        // create the locks for the user as specified.
        for (uint i = 0; i < count; i++) {
            locker.createLockFor(
                amount,
                86400 * 365 * 4, // 4 years
                msg.sender,
                false
            );
        }
    }

    // convert the eth from sales into maha from uniswap
    function swapETHforMAHA(
        uint256 amountOutMAHA,
        uint256 amountInETHMax,
        address to,
        bool unwrapWETH
    ) public payable returns (uint256 amountIn) {
        if (unwrapWETH) weth9.deposit{value: amountInETHMax}();
        else weth9.transferFrom(msg.sender, me, amountInETHMax);

        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: address(weth9),
                tokenOut: address(maha),
                fee: 10000,
                recipient: to,
                deadline: block.timestamp,
                amountOut: amountOutMAHA,
                amountInMaximum: amountInETHMax,
                sqrtPriceLimitX96: 0
            });

        // Executes the swap returning the amountIn needed to spend to receive the desired amountOut.
        amountIn = router.exactOutputSingle(params);

        // For exact output swaps, the amountInMaximum may not have all been spent.
        // If the actual amount spent (amountIn) is less than the specified maximum amount, we must refund the msg.sender and approve the swapRouter to spend 0.
        if (amountIn < amountInETHMax) {
            if (unwrapWETH) {
                weth9.withdraw(amountInETHMax - amountIn);
                payable(msg.sender).transfer(amountInETHMax - amountIn);
            } else weth9.transfer(msg.sender, amountInETHMax - amountIn);
        }
    }

    // convert the eth from sales into maha nfts
    function swapETHforLocks(
        uint256 ethInMax,
        uint256 count,
        uint256 amount,
        bool unwrapWETH
    ) public payable {
        // weth -> maha
        swapETHforMAHA(count * amount, ethInMax, me, unwrapWETH);

        // create the locks for the user as specified.
        for (uint i = 0; i < count; i++) {
            locker.createLockFor(
                amount,
                86400 * 365 * 4, // 4 years
                msg.sender,
                false
            );
        }
    }
}