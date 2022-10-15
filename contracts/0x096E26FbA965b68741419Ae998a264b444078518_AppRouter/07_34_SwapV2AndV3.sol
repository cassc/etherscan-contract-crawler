//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "../libs//TickMath.sol";
import "../libs/UniswapV2Library.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/WETH.sol";
import "../libs/CommonLibrary.sol";
import "../constants/Constants.sol";
import "../libs/UniswapV3Library.sol";

contract SwapV2AndV3Router {
    function swapV2ToV3ByOwner(
        uint256 amountIn,
        address token,
        uint24 fee,
        uint256 payETHToCoinbase
    ) public payable {
        // token address < ETHAddress
        bool zeroForOne = token < Constants.WETH;
        (uint256 reserveToken, uint256 reserveETH) = UniswapV2Library
            .getReserves(Constants.UNISWAP_V2_FACTORY, Constants.WETH, token);
        uint256 amountOut = UniswapV2Library.getAmountOut(
            amountIn,
            reserveToken,
            reserveETH
        );
        useFlashSwapExactTokenByV2(
            amountOut,
            amountIn,
            zeroForOne,
            token,
            fee,
            payETHToCoinbase
        );
    }

    function useFlashSwapExactTokenByV2(
        uint256 amountToken,
        uint256 amountOutMin,
        bool zeroForOne, // token address > ETHAddress
        address token,
        uint24 fee,
        uint256 payETHToCoinbase
    ) internal {
        // 表示v2和v3的swap router
        uint8 swapType = 4;
        bytes memory data = abi.encode(
            amountOutMin,
            swapType,
            fee,
            payETHToCoinbase
        );
        if (zeroForOne) {
            IUniswapV2Pair(
                UniswapV2Library.pairFor(
                    Constants.UNISWAP_V2_FACTORY,
                    token,
                    Constants.WETH
                )
            ).swap(amountToken, 0, address(this), data);
        } else {
            IUniswapV2Pair(
                UniswapV2Library.pairFor(
                    Constants.UNISWAP_V2_FACTORY,
                    Constants.WETH,
                    token
                )
            ).swap(0, amountToken, address(this), data);
        }
    }

    function uniswapV2ForUniswapV3Callback(
        uint256 amountOutMin,
        uint256 amount0,
        uint256 amount1,
        uint256 payETHToCoinbase,
        uint24 fee
    ) internal {
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
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
            require(
                amountOut - payETHToCoinbase >= amountOutMin,
                "amount less min"
            );
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
            require(
                amountOut - payETHToCoinbase >= amountOutMin,
                "amount less min"
            );
            // WETH.deposit{value: amountOutMin}();
            WETH.transfer(msg.sender, amountOutMin);
        }
        // 贿赂矿工
        block.coinbase.transfer(payETHToCoinbase);
    }

    function swapV3ToV2ByOwner(
        uint256 amountIn,
        address token,
        uint24 fee,
        uint256 payETHToCoinbase
    ) public payable {
        // true的时候，买大的，false的时候，买小的
        // 这个地方是要买token
        bool zeroForOne = Constants.WETH < token;
        uint8 swapType = 6;

        UniswapV3Library.getPool(Constants.WETH, token, fee).swap(
            address(this), // address(0) might cause issues with some tokens
            zeroForOne,
            int256(amountIn),
            zeroForOne
                ? TickMath.MIN_SQRT_RATIO + 1
                : TickMath.MAX_SQRT_RATIO - 1,
            abi.encode(amountIn, token, swapType, payETHToCoinbase)
        );
    }

    function uniswapV3ForV2Callback(
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
        token20.approve(Constants.UNISWAP_V2_ROUTER, amountTokenOut);

        uint256 amountEth = CommonLibrary.swapExactTokenByV2(
            amountTokenOut,
            token,
            Constants.WETH
        );
        require(
            amountEth - payETHToCoinbase > amountOutMin,
            "amount eth overflow"
        );
        require(amountEth > amountPay, "amount eth overflow");
        // WETH.deposit{value: amountPay}();
        WETH.transfer(msg.sender, amountPay);
        block.coinbase.transfer(payETHToCoinbase);
    }
}