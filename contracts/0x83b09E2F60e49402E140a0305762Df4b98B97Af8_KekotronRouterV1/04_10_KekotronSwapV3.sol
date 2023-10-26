// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./interfaces/IWETH.sol";
import "./interfaces/IPoolV3.sol";
import "./KekotronLib.sol";
import "./KekotronErrors.sol";

contract KekotronSwapV3 {
    address private immutable WETH;

    address private constant FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    bytes32 private constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    constructor(address weth) {
        WETH = weth;
    }

    struct SwapV3 {
        address pool;
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 amountOut;
    }

    function _computePool(address tokenIn, address tokenOut, uint24 fee) private pure returns(address) {
        address tokenA;
        address tokenB;

        if (tokenIn < tokenOut) {
            tokenA = tokenIn;
            tokenB = tokenOut;
        } else {
            tokenA = tokenOut;
            tokenB = tokenIn;
        }

        address pool = address(uint160(uint256(
            keccak256(
                abi.encodePacked(
                    hex'ff',
                    FACTORY,
                    keccak256(abi.encode(tokenA, tokenB, fee)),
                    POOL_INIT_CODE_HASH
                )
            )
        )));

        return pool;
    }

    function _deriveData(SwapV3 memory param, address payer) private view returns(bool, int256, uint160, bytes memory) {
        bool zeroForOne = param.tokenIn < param.tokenOut;

        int256 amountSpecified = int256(param.amountIn);
        uint160 sqrtPriceLimitX96 = (zeroForOne ? 4295128749 : 1461446703485210103287273052203988822378723970341);
        bytes memory data = abi.encode(param.tokenIn, param.tokenOut, IPoolV3(param.pool).fee(), param.amountOut, payer);

        return (zeroForOne, amountSpecified, sqrtPriceLimitX96, data);
    }

    function _swapV3(SwapV3 memory param, address to, address payer) private returns(uint256) {
        (
            bool zeroForOne, 
            int256 amountSpecified, 
            uint160 sqrtPriceLimitX96, 
            bytes memory data
        ) = _deriveData(param, payer);

        (int256 amount0, int256 amount1) = IPoolV3(param.pool).swap(to, zeroForOne, amountSpecified, sqrtPriceLimitX96, data);
        uint256 amountOut = uint256(-(zeroForOne ? amount1 : amount0));

        return amountOut;
    }

    function _swapExactEthForTokensV3(
        SwapV3 memory param,
        address feeReceiver,
        uint8 fee,
        uint8 feeOn
    ) private {   
        (bool feeIn, bool feeOut) = fee > 0 ? (feeOn == 0, feeOn == 1) : (false, false);
        uint256 amountFee;

        if (feeIn) {
            amountFee = param.amountIn * fee / 10_000;
            KekotronLib.safeTransferETH(feeReceiver, amountFee);
            param.amountIn -= amountFee;
            amountFee = 0;
        }

        KekotronLib.depositWETH(WETH, param.amountIn);

        uint256 amountOut = _swapV3(param, feeOut ? address(this) : msg.sender, address(this));

        if (feeOut) {
            amountFee = amountOut * fee / 10_000;
            amountOut = amountOut - amountFee;
        }

        if (amountOut < param.amountOut) { 
            revert("KekotronErrors.TooLittleReceived"); 
        }

        if (amountFee > 0) {
            KekotronLib.safeTransfer(param.tokenOut, feeReceiver, amountFee);
        }

        if (feeOut) {
            KekotronLib.safeTransfer(param.tokenOut, msg.sender, amountOut);
        }
    }

    function _swapExactTokensForEthV3(
        SwapV3 memory param,
        address feeReceiver,
        uint8 fee,
        uint8 feeOn
    ) private {
        (bool feeIn, bool feeOut) = fee > 0 ? (feeOn == 0, feeOn == 1) : (false, false);
        uint256 amountFee;

        if (feeIn) {
            amountFee= param.amountIn * fee / 10_000;
            KekotronLib.safeTransferFrom(param.tokenIn, msg.sender, feeReceiver, amountFee);
            param.amountIn -= amountFee;
            amountFee = 0;
        } 
 
        uint256 amountOut = _swapV3(param, address(this), msg.sender);
        
        KekotronLib.withdrawWETH(WETH, amountOut);
        
        if (feeOut) {
            amountFee = amountOut * fee / 10_000;
            amountOut = amountOut - amountFee;
        }

        if (amountOut < param.amountOut) { 
            revert("KekotronErrors.TooLittleReceived"); 
        }

        if (amountFee > 0) {
            KekotronLib.safeTransferETH(feeReceiver, amountFee);
        }

        KekotronLib.safeTransferETH(msg.sender, amountOut);
    }

    function _swapExactTokensForTokensV3(
        SwapV3 memory param,
        address feeReceiver,
        uint8 fee,
        uint8 feeOn
    ) private {
        (bool feeIn, bool feeOut) = fee > 0 ? (feeOn == 0, feeOn == 1) : (false, false);
        uint256 amountFee;

        if (feeIn) {
            amountFee = param.amountIn * fee / 10_000;
            KekotronLib.safeTransferFrom(param.tokenIn, msg.sender, feeReceiver, amountFee);
            param.amountIn -= amountFee;
            amountFee = 0;
        } 

        uint256 amountOut = _swapV3(param, feeOut ? address(this) : msg.sender, msg.sender);

        if (feeOut) {
            amountFee = amountOut * fee / 10_000;
            amountOut = amountOut - amountFee;
        }

        if (amountOut < param.amountOut) { 
            revert("KekotronErrors.TooLittleReceived"); 
        }

        if (amountFee > 0) {
            KekotronLib.safeTransfer(param.tokenOut, feeReceiver, amountFee);
        }

        if (feeOut) {
            KekotronLib.safeTransfer(param.tokenOut, msg.sender, amountOut);
        }
    }

    function _swapExactInputV3(
        SwapV3 memory param,
        address feeReceiver,
        uint8 fee,
        uint8 feeOn
    ) internal {
        if (param.tokenIn == address(0)) {
            param.tokenIn = WETH;
            return _swapExactEthForTokensV3(param, feeReceiver, fee, feeOn);
        }

        if (param.tokenOut == address(0)) {
            param.tokenOut = WETH;
            return _swapExactTokensForEthV3(param, feeReceiver, fee, feeOn);
        }

        return _swapExactTokensForTokensV3(param, feeReceiver, fee, feeOn);
    }

    function _callbackV3(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes memory data
    ) internal {
        if (amount0Delta == 0 && amount1Delta == 0) {
            revert("KekotronErrors.InsufficientLiquidity");
        }

        (
            address tokenIn,
            address tokenOut,
            uint24 fee,
            uint256 limit,
            address payer
        ) = abi.decode(data, (address, address, uint24, uint256, address));

        if (msg.sender != _computePool(tokenIn, tokenOut, fee)) {
            revert("KekotronErrors.InvalidCallbackPool");
        }

        bool zeroForOne = tokenIn < tokenOut;

        if(uint256(-(zeroForOne ? amount1Delta : amount0Delta)) < limit) {
            revert("KekotronErrors.TooLittleReceived");
        }

        if (payer == address(this)) {
            KekotronLib.safeTransfer(tokenIn, msg.sender, uint256(zeroForOne ? amount0Delta : amount1Delta));
        } else {
            KekotronLib.safeTransferFrom(tokenIn, payer, msg.sender, uint256(zeroForOne ? amount0Delta : amount1Delta));
        }
    }
}