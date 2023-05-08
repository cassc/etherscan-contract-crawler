// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.19;

import {IERC20} from "./interfaces/IERC20.sol";
import {SafeTransfer} from "./lib/SafeTransfer.sol";
import {IWETH} from "./interfaces/IWETH.sol";

interface IUniswapV2Pair {
    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;
}

// &&&&&&&&&%%%&%#(((/,,,**,,,**,,,*******/*,,/%%%%%%#.,%%%%%%%%%%%%%%%% ./(#%%%%/. #%%/***,,*,*,,,,**,
// %&&&&&&&&&%%%/((((*,,,,,,,**/.,,,*****/%%#.      ,**,,%%%%%%%%%%%%%%%%%%#.     #%%%%%#*,,,,,,*,,,,,*
// ,.,,*(%&&%%/*/((((,,,,,,,,**((%%,,**,  .#%%/*%%%%%%%,*%%%%%%%%%%%%%%%%#%    ..  #%%%%%,*,*,,**,*,**,
// ..,.,,.,,.,.*((((,,,,,,,****(#%%%%%,*%%%%%. .(%%%%%#,#%%%%%%%%%%%%%%%%,  &@# . * (%%%%***,*,,*,*,,,,
// .,.,,..,.,.,/(((,,,,,*****/#%%%%%%%%%%%%%,         ,%%%%%%%%%%%%%%%%%% .    .  / *#%%#***,*,*,**,,**
// ,,.,,,,.,,.,/((,,,****/#%%%%%%%%%%%%%%,     , ....   #%%%%%%%%&&%%%%%, /  ...  ,(%%%%/****,****,*#%#
// .,,.,.,.,.,,/(##%%%%%%%%%%%%%%%%%%%%% , /, .......    %%%%%%%%&&%%%%%% /*  .  , @%%%%/*******/(##%##
// ,..,,..,.,,%%%%%%%%%%%%%%%%%%%%%%%%%(#@..(/ .....  /, %%%%%%%%&&&%%%%%(.*////  @%%%%%/****(#%%%%%%#/
// ,,,..,.,,,.%%%%%%%%%%%%%%%%%%%%%%%%%%%%@../(*     @ .,%%%%%%%%%%%%%%%%%%%%/ ./(%%%%%/*/(#%%%%%%%#**/
// .,,,,,,,,,,*,#%%%%%%%%%%%%%%%%%%%%%%%%%%&@, ,*/(/,. #%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#(#%%%%%%%#//*///
// ,,.,,.,,,,,,,,,,#%%%%%%%%%%%%%%%%%%%%%%%%%%(    .#%%%%%%%%%%%%#%&&&%%%%%%%%%%%%%%%*%%%#%%%#(**(**//*
// .,,,,..,*..,.,,,,...*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%,(%#%%%(*/*///*//#%

contract MatisseRouter {
    using SafeTransfer for IERC20;
    using SafeTransfer for IWETH;

    address internal immutable feeAddress;

    address internal constant WETH9 =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    uint32 internal constant FEE_NUMERATOR = 875;
    uint32 internal constant FEE_DENOMINATOR = 100000;

    constructor() {
        feeAddress = msg.sender;
    }

    receive() external payable {}

    // *** Receive profits from contract *** //
    function recover(address token) public {
        require(msg.sender == feeAddress, "shoo");
        if (token == address(0)) {
            SafeTransfer.safeTransferETH(msg.sender, address(this).balance);
            return;
        } else {
            IERC20(token).safeTransfer(
                msg.sender,
                IERC20(token).balanceOf(address(this))
            );
        }
    }

    /*
        Payload structure

        - tokenIn: address      - Address of the token you're swapping
        - tokenOut: address     - Address of the token you want
        - pair: address         - Univ2 pair
        - amountIn?: uint128     - Amount you're giving via swap

        If you use this contract and use a public mempool, you are getting an expensive footlong.

    */

    fallback() external payable {
        address tokenIn;
        address tokenOut;
        address pair;
        uint amountIn;
        address receiver;

        assembly {
            // bytes20
            tokenIn := shr(96, calldataload(0))
            // bytes20
            tokenOut := shr(96, calldataload(20))
            // bytes20
            pair := shr(96, calldataload(40))
        }

        if (address(tokenIn) == WETH9 && msg.value > 0) {
            uint feeAmount = (msg.value * FEE_NUMERATOR) / FEE_DENOMINATOR;
            amountIn = msg.value - feeAmount;
            IWETH weth = IWETH(WETH9);

            weth.deposit{value: amountIn}();
            weth.safeTransfer(pair, amountIn);
            receiver = msg.sender;
        } else {
            assembly {
                // uint128
                amountIn := shr(128, calldataload(60))
            }
            IERC20(tokenIn).safeTransferFrom(msg.sender, pair, amountIn);
            receiver = address(this);
        }

        // Prepare variables for calculating expected amount out
        uint reserveIn;
        uint reserveOut;

        {
            (uint reserve0, uint reserve1, ) = IUniswapV2Pair(pair)
                .getReserves();

            // sort reserves
            if (tokenIn < tokenOut) {
                // Token0 is equal to inputToken
                // Token1 is equal to outputToken
                reserveIn = reserve0;
                reserveOut = reserve1;
            } else {
                // Token0 is equal to outputToken
                // Token1 is equal to inputToken
                reserveIn = reserve1;
                reserveOut = reserve0;
            }
        }

        // Find the actual amountIn sent to pair (accounts for tax if any) and amountOut
        uint actualAmountIn = IERC20(tokenIn).balanceOf(address(pair)) -
            reserveIn;
        uint amountOut = _getAmountOut(actualAmountIn, reserveIn, reserveOut);

        // Prepare swap variables and call pair.swap()
        (uint amount0Out, uint amount1Out) = tokenIn < tokenOut
            ? (uint(0), amountOut)
            : (amountOut, uint(0));

        IUniswapV2Pair(pair).swap(
            amount0Out,
            amount1Out,
            receiver,
            new bytes(0)
        );

        if (receiver == address(this)) {
            // Only support native ETH out because we can't differentiate
            if (tokenOut == WETH9) {
                IWETH(WETH9).withdraw(amountOut);

                uint feeAmount = (amountOut * FEE_NUMERATOR) / FEE_DENOMINATOR;

                SafeTransfer.safeTransferETH(msg.sender, amountOut - feeAmount);
            } else {
                uint feeAmount = (amountOut * FEE_NUMERATOR) / FEE_DENOMINATOR;

                IERC20(tokenOut).safeTransfer(
                    msg.sender,
                    amountOut - feeAmount
                );
            }
        }
    }

    function _getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) internal pure returns (uint amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint amountInWithFee = amountIn * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }
}