//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "../libs/PoolAddress.sol";
import "../constants/Constants.sol";
import "../libs/TickMath.sol";
import "../libs/SushiSwapLibrary.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/WETH.sol";
import "../libs/CommonLibrary.sol";

contract SwapSushiAndV3Router {
    function swapSushiToV3(
        uint256 amountIn,
        address token,
        uint24 fee,
        uint256 payETHToCoinbase
    ) public {
        // token address < ETHAddress
        bool zeroForOne = token < Constants.WETH;
        (uint256 reserveIn, uint256 reserveOut) = SushiSwapLibrary.getReserves(
            Constants.SUSHI_FACTORY,
            Constants.WETH,
            token
        );
        uint256 amountOut = SushiSwapLibrary.getAmountOut(
            amountIn,
            reserveIn,
            reserveOut
        );
        useFlashSwapExactTokenBySushi(
            amountOut,
            amountIn,
            zeroForOne,
            token,
            fee,
            payETHToCoinbase
        );
    }

    function useFlashSwapExactTokenBySushi(
        uint256 amountToken,
        uint256 amountOutMin,
        bool zeroForOne, // token address > ETHAddress
        address token,
        uint24 fee,
        uint256 payETHToCoinbase
    ) internal {
        // 表示sushi和v3的swap router
        uint8 swapType = 3;
        bytes memory data = abi.encode(
            amountOutMin,
            swapType,
            fee,
            payETHToCoinbase
        );
        if (zeroForOne) {
            ISushiSwapPair(
                SushiSwapLibrary.pairFor(
                    Constants.SUSHI_FACTORY,
                    token,
                    Constants.WETH
                )
            ).swap(amountToken, 0, address(this), data);
        } else {
            ISushiSwapPair(
                SushiSwapLibrary.pairFor(
                    Constants.SUSHI_FACTORY,
                    Constants.WETH,
                    token
                )
            ).swap(0, amountToken, address(this), data);
        }
    }

    function sushiForUniswapV3Callback(
        uint256 amountOutMin,
        uint256 amount0,
        uint256 amount1,
        uint256 payETHToCoinbase,
        uint24 fee
    ) internal {
        address token0 = ISushiSwapPair(msg.sender).token0();
        address token1 = ISushiSwapPair(msg.sender).token1();

        if (amount0 > 0) {
            IWETH WETH = IWETH(token1);
            IERC20 token = IERC20(token0);
            token.approve(Constants.UNISWAP_V3_ROUTER, amount0);
            uint256 amountOut = CommonLibrary.swapExactTokenByV3(
                token0,
                token1,
                amount0,
                amountOutMin,
                fee
            );
            require(amountOut >= amountOutMin, "amount less min");
            // WETH.deposit{value: amountOutMin}();
            WETH.transfer(msg.sender, amountOutMin);
        } else {
            IWETH WETH = IWETH(token0);
            IERC20 token = IERC20(token1);
            token.approve(Constants.UNISWAP_V3_ROUTER, amount1);
            uint256 amountOut = CommonLibrary.swapExactTokenByV3(
                token1,
                token0,
                amount1,
                amountOutMin,
                fee
            );
            require(amountOut >= amountOutMin, "amount less min");
            // WETH.deposit{value: amountOutMin}();
            WETH.transfer(msg.sender, amountOutMin);
        }
        block.coinbase.transfer(payETHToCoinbase);
    }

    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (IUniswapV3Pool) {
        return
            IUniswapV3Pool(
                PoolAddress.computeAddress(
                    Constants.UNISWAP_V3_FACTORY,
                    PoolAddress.getPoolKey(tokenA, tokenB, fee)
                )
            );
    }

    function swapV3ToSushi(
        uint256 amountIn,
        address token,
        uint24 fee,
        uint256 payETHToCoinbase
    ) public {
        // true的时候，买大的，false的时候，买小的
        // 这个地方是要买token
        bool zeroForOne = Constants.WETH < token;
        uint8 swapType = 5;
        getPool(Constants.WETH, token, fee).swap(
            address(this), // address(0) might cause issues with some tokens
            zeroForOne,
            int256(amountIn),
            zeroForOne
                ? TickMath.MIN_SQRT_RATIO + 1
                : TickMath.MAX_SQRT_RATIO - 1,
            abi.encode(amountIn, token, swapType, payETHToCoinbase)
        );
    }

    function uniswapV3ForSushiCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        address token,
        uint256 amountOutMin,
        uint256 payETHToCoinbase
    ) internal {
        IWETH WETH = IWETH(Constants.WETH);
        IERC20 token20 = IERC20(token);
        uint256 amountPay = amount0Delta > 0
            ? uint256(amount0Delta)
            : uint256(amount1Delta);
        uint256 amountTokenOut = amount0Delta > 0
            ? uint256(-amount1Delta)
            : uint256(-amount0Delta);
        token20.approve(Constants.SUSHI_ROUTER, amountTokenOut);
        uint256 amountEth = CommonLibrary.swapExactTokenBySushi(
            amountTokenOut,
            token,
            Constants.WETH
        );
        require(amountEth > amountOutMin, "amount eth overflow");
        require(amountEth > amountPay, "amount eth overflow");
        // WETH.deposit{value: amountPay}();
        WETH.transfer(msg.sender, amountPay);
        block.coinbase.transfer(payETHToCoinbase);
    }
}