// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IUniswapV2Router02.sol";

contract AutoSwap is Ownable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    // 基础配置
    address public router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public usdt = 0xBB8224b8A3bFd027C0865c3649A8124071Ac8FDA;

    IERC20 private usdtToken;
    IUniswapV2Router02 private swapRouter;

    constructor() {
        usdtToken = IERC20(usdt);
        swapRouter = IUniswapV2Router02(router);
        usdtToken.safeApprove(router, 2**255 - 1);
    }

    function swapOne(uint256 amountIn, uint256 amountOut, address[] memory path, address[] calldata receiver) public {
        for (uint256 i = 0; i < receiver.length; i++) {
            try swapRouter.swapExactTokensForTokens(amountIn, amountOut, path, receiver[i], block.timestamp + 15) {} catch {}
        }
    }

    function swapTwo(uint256 amountIn, uint256 amountOut, address[] memory path, address[] calldata receiver) public {
        for (uint256 i = 0; i < receiver.length; i++) {
            try swapRouter.swapTokensForExactTokens(amountIn, amountOut, path, receiver[i], block.timestamp + 15) {} catch {}
        }
    }

    function rescue(IERC20 token, uint256 amount) public onlyOwner {
        token.safeTransfer(msg.sender, amount);
    }
}