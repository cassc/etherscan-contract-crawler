// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.6;

import "CLPBase.sol";
import "IUniswapV2Router02.sol";
import "IUniswapV2Factory.sol";
import "IUniswapV2Pair.sol";
import "ICLPUniswapV2.sol";
import "IERC2612.sol";

contract CLPUniswapV2 is CLPBase, ICLPUniswapV2 {
    function _getContractName() internal pure override returns (string memory) {
        return "CLPUniswapV2";
    }

    /**
        @notice Deposits tokens into an LP pool
        @dev The user calling this function must take necessary precautions to ensure that
            the address of the router is a valid and trusted implementation of UniswapV2Router
        @param amountA The desired amount of `tokenA` to deposit
        @param tokenA The first token to be supplied
        @param amountB The desired amount of `tokenB` to deposit
        @param tokenB The second token to be supplied
        @param params Additional parameters to pass to this function
     */
    function deposit(
        uint256 amountA,
        IERC20 tokenA,
        uint256 amountB,
        IERC20 tokenB,
        UniswapV2LPDepositParams calldata params
    ) external payable {
        address receiver = params.receiver == address(0) ? address(this) : params.receiver;
        //solhint-disable-next-line not-rely-on-time
        uint256 deadline = params.deadline == 0 ? block.timestamp + 1 : params.deadline;

        address factory = IUniswapV2Router02(params.router).factory();
        address desiredLP = IUniswapV2Factory(factory).getPair(address(tokenA), address(tokenB));
        uint256 balanceBefore = IERC20(desiredLP).balanceOf(receiver);

        _approveToken(tokenA, address(params.router), amountA);
        _approveToken(tokenB, address(params.router), amountB);
        IUniswapV2Router02(params.router).addLiquidity(
            address(tokenA),
            address(tokenB),
            amountA,
            amountB,
            params.amountAMin,
            params.amountBMin,
            receiver,
            deadline
        );
        uint256 balanceAfter = IERC20(desiredLP).balanceOf(receiver);
        require(balanceAfter > balanceBefore, "CLPUniswapV2: error receiving LP token");
    }

    function withdraw(
        IUniswapV2Pair pool,
        uint256 liquidity,
        UniswapV2LPWithdrawParams calldata params
    ) external payable {
        address receiver = params.receiver == address(0) ? address(this) : params.receiver;
        if (params.deadline > 0) {
            //solhint-disable-next-line not-rely-on-time
            require(params.deadline >= block.timestamp, "CLPUniswapV2: EXPIRED");
        }

        address token0 = pool.token0();
        address token1 = pool.token1();

        uint256 balanceBefore0 = IERC20(token0).balanceOf(receiver);
        uint256 balanceBefore1 = IERC20(token1).balanceOf(receiver);

        pool.transfer(address(pool), liquidity);
        pool.burn(receiver);

        uint256 balanceAfter0 = IERC20(token0).balanceOf(receiver);
        uint256 balanceAfter1 = IERC20(token1).balanceOf(receiver);

        // token0 corresponds to tokenA, token1 corresponds to tokenB
        require(
            balanceAfter0 >= balanceBefore0 + params.amountAMin,
            "CLPUniswapV2: insufficient A received"
        );
        require(
            balanceAfter1 >= balanceBefore1 + params.amountBMin,
            "CLPUniswapV2: insufficient B received"
        );
    }

    // https://github.com/Uniswap/v2-core/blob/master/contracts/UniswapV2ERC20.sol#L81
    function eip2612Permit(
        IERC2612 token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        token.permit(owner, spender, value, deadline, v, r, s);
    }
}