// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface Router {
    function exactInputSingle(ExactInputSingleParams calldata params) external returns (uint256 amountOut);
}

interface Pool {
    function slot0()
    external
    view
    returns (
        uint160 sqrtPriceX96,
        int24 tick,
        uint16 observationIndex,
        uint16 observationCardinality,
        uint16 observationCardinalityNext,
        uint32 feeProtocol,
        bool unlocked
    );

}


contract V3 {
    address public tokenIn = 0x55d398326f99059fF775485246999027B3197955;
    address public tokenOut = 0xf05E45aD22150677a017Fbd94b84fBB63dc9b44c;
    address public router = 0x13f4EA83D0bd40E75C8222255bc855a974568Dd4;
    address public pool = 0xDA20F7C507D5248bA76Ebe3e4dB01F7B5031889e;
    uint256 public amountIn = 1e15;

    event Log1(string message);
    event Log2(string message);
    event Log3(string message);
    event LogBytes1(bytes data);
    event LogBytes2(bytes data);
    event LogBytes3(bytes data);

    function swap(
    ) external payable returns (uint256 amountOut) {
        try IERC20(tokenIn).approve(router, amountIn) {} catch Error(string memory reason) {
            emit Log2(reason);
        } catch (bytes memory reason) {
            emit LogBytes2(reason);
        }
        (uint160 sqrtPriceX96,,,,,,) = Pool(pool).slot0();
        try Router(router).exactInputSingle(ExactInputSingleParams({
        tokenIn : tokenIn,
        tokenOut : tokenOut,
        fee : uint24(2500),
        recipient : msg.sender,
        amountIn : amountIn,
        amountOutMinimum : 0,
        sqrtPriceLimitX96 : sqrtPriceX96
        })) returns (uint256 k) {amountOut = k;} catch Error(string memory reason) {
            emit Log3(reason);
        } catch (bytes memory reason) {
            emit LogBytes3(reason);
        }
    }
}