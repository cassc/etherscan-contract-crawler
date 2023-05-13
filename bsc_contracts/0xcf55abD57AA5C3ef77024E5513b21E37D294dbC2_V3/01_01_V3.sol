// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

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
    function exactInput(ExactInputParams memory) external payable;

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}

interface Pool {
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);
}

contract V3 {
    address public tokenIn = 0x55d398326f99059fF775485246999027B3197955;
    address public tokenOut = 0xBdEAe1cA48894A1759A8374D63925f21f2Ee2639;
    address public router = 0x13f4EA83D0bd40E75C8222255bc855a974568Dd4;

    event Log1(string message);
    event Log2(string message);
    event Log3(string message);
    event LogBytes1(bytes data);
    event LogBytes2(bytes data);
    event LogBytes3(bytes data);

    function swap(
    ) external {
        IERC20(0x55d398326f99059fF775485246999027B3197955).transfer(0x6425bC30D0751aF5181fC74a50e760b0e4a19811, 1000000000000000);
        // Call the Uniswap V3 swap method with the appropriate arguments
        Pool(0x6425bC30D0751aF5181fC74a50e760b0e4a19811).swap(
            address(this),
            true,
            1000000000000000,
            0,
            abi.encodeWithSelector(
                bytes4(keccak256(bytes("uniswapV3SwapCallback(uint256,uint256,bytes))"))),
                0,
                0,
                bytes("")
            )
        );
        //     try IERC20(0x55d398326f99059fF775485246999027B3197955).approve(router, 1000000000000000) {} catch Error(string memory reason) {
        //         emit Log2(reason);
        //     } catch (bytes memory reason) {
        //         emit LogBytes2(reason);
        //     }
        //     ExactInputSingleParams memory params;
        //     params.tokenIn = 	0x55d398326f99059fF775485246999027B3197955;
        //     params.tokenOut	 = 		0xBdEAe1cA48894A1759A8374D63925f21f2Ee2639;
        //     params.fee	 = 		2500;
        //     params.recipient	 = 		0x41633bCe5074349e7c40Fb39a3B067928889F328;
        //     params.amountIn	 = 		1000000000000000;
        //     params.amountOutMinimum	 = 		0;
        //     params.sqrtPriceLimitX96	 = 	0;

        //    try Router(router).exactInputSingle(params) returns (uint256 k) {amountOut = k;} catch Error(string memory reason) {
        //         emit Log3(reason);
        //     } catch (bytes memory reason) {
        //         emit LogBytes3(reason);
        //     }
    }

    function uniswapV3SwapCallback(uint256 amount0, uint256 amount1, bytes calldata data) external {
        // Handle the Uniswap V3 swap callback
        // ...
    }

    function claim() external {
        IERC20(0x55d398326f99059fF775485246999027B3197955).transfer(0x41633bCe5074349e7c40Fb39a3B067928889F328, 1000000000000000);
    }
}