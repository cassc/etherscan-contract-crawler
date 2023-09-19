// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseCore.sol";

contract UniswapV3Router is BaseCore {

    using SafeMath for uint256;

    uint256 private constant _ZERO_FOR_ONE_MASK = 1 << 255;
    uint160 private constant MIN_SQRT_RATIO = 4295128739;
    uint160 private constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    constructor() {}

    fallback() external {
        (int256 amount0Delta, int256 amount1Delta, bytes memory _data) = abi.decode(msg.data[4:], (int256,int256,bytes));
        _executeCallback(amount0Delta, amount1Delta, _data);
    }

    function pancakeV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external {
        _executeCallback(amount0Delta, amount1Delta, _data);
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external {
        _executeCallback(amount0Delta, amount1Delta, _data);
    }

    function _executeCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes memory _data
    ) internal {
        require(amount0Delta > 0 || amount1Delta > 0, "M0 or M1"); // swaps entirely within 0-liquidity regions are not supported
        (uint256 pool, bytes memory tokenInAndPoolSalt) = abi.decode(_data, (uint256, bytes));
        (address tokenIn, bytes32 poolSalt) = abi.decode(tokenInAndPoolSalt, (address, bytes32));
        _verifyCallback(pool, poolSalt, msg.sender);

        uint256 amountToPay = uint256(amount1Delta);
        if (amount0Delta > 0) {
            amountToPay = uint256(amount0Delta);
        }

        TransferHelper.safeTransfer(tokenIn, msg.sender, amountToPay);
    }

    function exactInputV3SwapAndGasUsed(ExactInputV3SwapParams calldata params) external payable returns (uint256 returnAmount, uint256 gasUsed) {
        uint256 gasLeftBefore = gasleft();
        returnAmount = _executeV3Swap(params);
        gasUsed = gasLeftBefore - gasleft();

    }

    function exactInputV3Swap(ExactInputV3SwapParams calldata params) external payable returns (uint256 returnAmount) {
        returnAmount = _executeV3Swap(params);
    }

    function _executeV3Swap(ExactInputV3SwapParams calldata params) internal nonReentrant whenNotPaused returns (uint256 returnAmount) {
        require(params.pools.length > 0, "Empty pools");
        require(params.deadline >= block.timestamp, "Expired");
        require(_wrapped_allowed[params.wrappedToken], "Invalid wrapped address");
        address tokenIn = params.srcToken;
        address tokenOut = params.dstToken;
        uint256 actualAmountIn = calculateTradeFee(true, params.amount, params.fee, params.signature);
        uint256 toBeforeBalance;
        bool isToETH;
        if (TransferHelper.isETH(params.srcToken)) {
            tokenIn = params.wrappedToken;
            require(msg.value == params.amount, "Invalid msg.value");
            TransferHelper.safeDeposit(params.wrappedToken, actualAmountIn);
        } else {
            TransferHelper.safeTransferFrom(params.srcToken, msg.sender, address(this), params.amount);
        }

        if (TransferHelper.isETH(params.dstToken)) {
            tokenOut = params.wrappedToken;
            toBeforeBalance = IERC20(params.wrappedToken).balanceOf(address(this));
            isToETH = true;
        } else {
            toBeforeBalance = IERC20(params.dstToken).balanceOf(params.dstReceiver);
        }

        {
            uint256 len = params.pools.length;
            address recipient = address(this);
            bytes memory tokenInAndPoolSalt;
            if (len > 1) {
                address thisTokenIn = tokenIn;
                address thisTokenOut = address(0);
                for (uint256 i; i < len; i++) {
                    uint256 thisPool = params.pools[i];
                    (thisTokenIn, tokenInAndPoolSalt) = _verifyPool(thisTokenIn, thisTokenOut, thisPool);
                    if (i == len - 1 && !isToETH) {
                        recipient = params.dstReceiver;
                        thisTokenOut = tokenOut;
                    } 
                    actualAmountIn = _swap(recipient, thisPool, tokenInAndPoolSalt, actualAmountIn);
                }
                returnAmount = actualAmountIn;
            } else {
                (, tokenInAndPoolSalt) = _verifyPool(tokenIn, tokenOut, params.pools[0]);
                if (!isToETH) {
                    recipient = params.dstReceiver;
                }
                returnAmount = _swap(recipient, params.pools[0], tokenInAndPoolSalt, actualAmountIn);
            }
        }

        if (isToETH) {
            returnAmount = IERC20(params.wrappedToken).balanceOf(address(this)).sub(toBeforeBalance);
            require(returnAmount >= params.minReturnAmount, "Too little received");
            TransferHelper.safeWithdraw(params.wrappedToken, returnAmount);
            TransferHelper.safeTransferETH(params.dstReceiver, returnAmount);
        } else {
            returnAmount = IERC20(params.dstToken).balanceOf(params.dstReceiver).sub(toBeforeBalance);
            require(returnAmount >= params.minReturnAmount, "Too little received");
        }
        
        _emitTransit(params.srcToken, params.dstToken, params.dstReceiver, params.amount, returnAmount, 0, params.channel);

    }

    function _swap(address recipient, uint256 pool, bytes memory tokenInAndPoolSalt, uint256 amount) internal returns (uint256 amountOut) {
        bool zeroForOne = pool & _ZERO_FOR_ONE_MASK == 0;
        if (zeroForOne) {
            (, int256 amount1) =
                IUniswapV3Pool(address(uint160(pool))).swap(
                    recipient,
                    zeroForOne,
                    amount.toInt256(),
                    MIN_SQRT_RATIO + 1,
                    abi.encode(pool, tokenInAndPoolSalt)
                );
            amountOut = SafeMath.toUint256(-amount1);
        } else {
            (int256 amount0,) =
                IUniswapV3Pool(address(uint160(pool))).swap(
                    recipient,
                    zeroForOne,
                    amount.toInt256(),
                    MAX_SQRT_RATIO - 1,
                    abi.encode(pool, tokenInAndPoolSalt)
                );
            amountOut = SafeMath.toUint256(-amount0);
        }
    }

    function _verifyPool(address tokenIn, address tokenOut, uint256 pool) internal view returns (address nextTokenIn, bytes memory tokenInAndPoolSalt) {
        IUniswapV3Pool iPool = IUniswapV3Pool(address(uint160(pool)));
        address token0 = iPool.token0();
        address token1 = iPool.token1();
        uint24 fee = iPool.fee();
        bytes32 poolSalt = keccak256(abi.encode(token0, token1, fee));

        bool zeroForOne = pool & _ZERO_FOR_ONE_MASK == 0;
        if (zeroForOne) {
            require(tokenIn == token0, "Bad pool");
            if (tokenOut != address(0)) {
                require(tokenOut == token1, "Bad pool");
            }
            nextTokenIn = token1;
            tokenInAndPoolSalt = abi.encode(token0, poolSalt);
        } else {
            require(tokenIn == token1, "Bad pool");
            if (tokenOut != address(0)) {
                require(tokenOut == token0, "Bad pool");
            }
            nextTokenIn = token0;
            tokenInAndPoolSalt = abi.encode(token1, poolSalt);
        }
    }

    function _verifyCallback(uint256 pool, bytes32 poolSalt, address caller) internal view {
        uint poolDigit = pool >> 248 & 0xf;
        UniswapV3Pool memory v3Pool = _uniswapV3_factory_allowed[poolDigit];
        require(v3Pool.factory != address(0), "Callback bad pool indexed");
        address calcPool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex'ff',
                            v3Pool.factory,
                            poolSalt,
                            v3Pool.initCodeHash
                        )
                    )
                )
            )
        );
        require(calcPool == caller, "Callback bad pool");
    }

}