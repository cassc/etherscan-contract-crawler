// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {SafeTransferLib} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";
import {BytesLib} from "../libraries/BytesLib.sol";
import {IErrors} from "../interfaces/IErrors.sol";
import {RouterImmutables} from "../base/RouterImmutables.sol";
import {IUniswapPair} from "../interfaces/IUniswapPair.sol";
import {IUniswapV3SwapCallback} from "../interfaces/IUniswapV3SwapCallback.sol";
import {IUniswapV3Pool} from "../interfaces/IUniswapV3Pool.sol";

abstract contract UniswapRouter is
    RouterImmutables,
    IErrors,
    IUniswapV3SwapCallback
{
    ///////////// UNISWAP_V2 LOGIC //////////////

    /// @notice Swaps tokens on Uniswap V2
    /// @param input The input bytes
    /// @param fromToken The first token to swap from
    /// @param amountIn The first amountIn to swap
    function swapV2(
        bytes memory input,
        address fromToken,
        uint256 amountIn
    ) internal returns (bytes memory output) {
        uint256 swapLength = BytesLib.toUint8(input, input.length - 2);
        address recipient = BytesLib.toUint8(input, input.length - 1) == 0
            ? msg.sender
            : BytesLib.toAddress(input, input.length - 22);

        (
            address[] memory pairs,
            address[] memory tokens,
            uint256[] memory amounts
        ) = V2Helper(input, fromToken, amountIn, swapLength);

        if (swapLength > 1) {
            bool zeroForOne = tokens[0] < tokens[1] ? true : false;
            IUniswapPair(pairs[0]).swap(
                zeroForOne ? 0 : amounts[0],
                zeroForOne ? amounts[0] : 0,
                pairs[1],
                ""
            );
            uint256 finalIndex = swapLength - 1;
            for (uint256 i = 1; i < finalIndex; ) {
                zeroForOne = tokens[i] < tokens[i + 1] ? true : false;
                IUniswapPair(pairs[i]).swap(
                    zeroForOne ? 0 : amounts[i],
                    zeroForOne ? amounts[i] : 0,
                    pairs[i + 1],
                    ""
                );

                unchecked {
                    i++;
                }
            }
            zeroForOne = tokens[finalIndex] < tokens[swapLength] ? true : false;
            IUniswapPair(pairs[finalIndex]).swap(
                zeroForOne ? 0 : amounts[finalIndex],
                zeroForOne ? amounts[finalIndex] : 0,
                recipient,
                ""
            );
        } else {
            bool zeroForOne = tokens[0] < tokens[1] ? true : false;
            IUniswapPair(pairs[0]).swap(
                zeroForOne ? 0 : amounts[0],
                zeroForOne ? amounts[0] : 0,
                recipient,
                ""
            );
        }
        uint256 amountOut = amounts[swapLength - 1];
        output = abi.encode(amountOut);

        if (recipient == address(this) && tokens[swapLength] == address(WETH)) {
            if (BytesLib.toAddress(input, input.length - 42) == address(this)) {
                if (BytesLib.toUint8(input, input.length - 43) == 1)
                    WETH.withdraw(amountOut);
                return output;
            }
            WETH.withdraw(amountOut);
            SafeTransferLib.safeTransferETH(
                BytesLib.toAddress(input, input.length - 42),
                amountOut
            );
        }
    }

    /// @notice Helper function to get values for swaps
    /// @param input The input bytes
    /// @param fromToken The first token to swap from
    /// @param amountIn The first amountIn to swap
    /// @param swapLength The number of swaps
    function V2Helper(
        bytes memory input,
        address fromToken,
        uint256 amountIn,
        uint256 swapLength
    )
        internal
        returns (
            address[] memory pairs,
            address[] memory tokens,
            uint256[] memory amounts
        )
    {
        pairs = new address[](swapLength);
        tokens = new address[](swapLength + 1);
        amounts = new uint256[](swapLength);

        address token0;
        address token1;
        uint256 cachedIn = amountIn;
        tokens[0] = fromToken == address(0) ? address(WETH) : fromToken;

        for (uint256 i; i < swapLength; ) {
            tokens[i + 1] = BytesLib.toAddress(input, 64 + ((i + 1) * 0x14));
            token0 = tokens[i];
            token1 = tokens[i + 1];
            pairs[i] = pairFor(token0, token1);

            (uint256 reserveIn, uint256 reserveOut, ) = IUniswapPair(pairs[i])
                .getReserves();

            if (token0 > token1)
                (reserveIn, reserveOut) = (reserveOut, reserveIn);

            amounts[i] =
                ((cachedIn * 997) * reserveOut) /
                ((reserveIn * 1000) + (cachedIn * 997));
            cachedIn = amounts[i];

            unchecked {
                i++;
            }
        }

        if (cachedIn < BytesLib.toUint256(input, 32))
            revert InsufficientOutput();

        if (fromToken == address(0)) WETH.deposit{value: amountIn}();

        SafeTransferLib.safeTransfer(ERC20(tokens[0]), pairs[0], amountIn);
    }

    /// @notice Gets the pair address for a given token pair using UniswapV2 Factory settings
    /// @param tokenA The first token
    /// @param tokenB The second token
    /// @return pair The pair address
    function pairFor(
        address tokenA,
        address tokenB
    ) internal view returns (address pair) {
        require(tokenA != tokenB, "V2:DUP_ADDRESS");
        (tokenA, tokenB) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(tokenA != address(0), "V2:ZERO_ADDRESS");
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            UNISWAP_V2_FACTORY,
                            keccak256(abi.encodePacked(tokenA, tokenB)),
                            hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
                        )
                    )
                )
            )
        );
    }

    ///////////// UNISWAP_V3 LOGIC //////////////

    /// @notice Swaps tokens using UniswapV3
    /// @param input The input bytes
    /// @param fromToken The first token to swap from
    /// @param amountIn The first amountIn to swap
    /// @return output The output bytes
    function swapV3(
        bytes memory input,
        address fromToken,
        uint256 amountIn
    ) internal returns (bytes memory output) {
        uint256 swapLength = BytesLib.toUint8(input, input.length - 2);
        address recipient = BytesLib.toUint8(input, input.length - 1) == 0
            ? msg.sender
            : BytesLib.toAddress(input, input.length - 22);

        if (fromToken == address(0)) WETH.deposit{value: amountIn}();

        if (swapLength > 1) {
            amountIn = _swap(
                address(this),
                amountIn,
                BytesLib.sliceBytes(input, 0x40, 43)
            );
            uint256 finalIndex = swapLength - 1;
            for (uint256 i = 1; i < finalIndex; ) {
                amountIn = _swap(
                    address(this),
                    amountIn,
                    BytesLib.sliceBytes(input, 0x40 + (i * 23), 43)
                );
                unchecked {
                    i++;
                }
            }
            amountIn = _swap(
                recipient,
                amountIn,
                BytesLib.sliceBytes(input, 0x40 + (finalIndex * 23), 43)
            );
        } else {
            amountIn = _swap(
                recipient,
                amountIn,
                BytesLib.sliceBytes(input, 0x40, 43)
            );
        }

        if (amountIn < BytesLib.toUint256(input, 32))
            revert InsufficientOutput();

        if (recipient == address(this)) {
            if (
                BytesLib.toAddress(input, 0x40 + (swapLength * 23)) ==
                address(WETH)
            ) {
                if (
                    BytesLib.toAddress(input, input.length - 42) ==
                    address(this)
                ) {
                    if (BytesLib.toUint8(input, input.length - 43) == 1)
                        WETH.withdraw(amountIn);
                } else {
                    WETH.withdraw(amountIn);
                    SafeTransferLib.safeTransferETH(
                        BytesLib.toAddress(input, input.length - 42),
                        amountIn
                    );
                }
            }
        }

        output = abi.encode(amountIn);
    }

    /// @notice Swaps tokens using UniswapV3
    /// @param recipient The recipient of the swap
    /// @param amount The amount to swap
    /// @param path The path to swap - used to tokenIn, tokenOut, and fee
    function _swap(
        address recipient,
        uint256 amount,
        bytes memory path
    ) internal returns (uint256) {
        address tokenIn = BytesLib.toAddress(path, 0);
        if (tokenIn == address(0)) tokenIn = address(WETH);
        uint24 fee = BytesLib.toUint24(path, 20);
        address tokenOut = BytesLib.toAddress(path, 23);
        bool zeroForOne = tokenIn < tokenOut;

        if (zeroForOne) {
            (, int256 amountOut) = IUniswapV3Pool(
                getPool(tokenIn, tokenOut, fee)
            ).swap(
                    recipient,
                    zeroForOne,
                    int256(amount),
                    _MIN_SQRT_RATIO,
                    path
                );
            return uint256(-amountOut);
        } else {
            (int256 amountOut, ) = IUniswapV3Pool(
                getPool(tokenIn, tokenOut, fee)
            ).swap(
                    recipient,
                    zeroForOne,
                    int256(amount),
                    _MAX_SQRT_RATIO,
                    path
                );
            return uint256(-amountOut);
        }
    }

    /// @notice Callback function executed from interaction with V3 pool - checks valid call and executes swap with pool
    /// @param amount0Delta The amount of token0 to swap
    /// @param amount1Delta The amount of token1 to swap
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external override {
        require(amount0Delta > 0 || amount1Delta > 0); // swaps entirely within 0-liquidity regions are not supported
        (address tokenIn, address tokenOut, uint24 fee) = decodePool(_data);
        tokenIn = tokenIn == address(0) ? address(WETH) : tokenIn;

        if (msg.sender != getPool(tokenIn, tokenOut, fee)) revert BadPool();

        SafeTransferLib.safeTransfer(
            ERC20(tokenIn),
            msg.sender,
            amount0Delta > 0 ? uint256(amount0Delta) : uint256(amount1Delta)
        );
    }

    /// @notice Gets the pool address for a given token pair and fee
    /// @param tokenA The first token
    /// @param tokenB The second token
    /// @param fee The fee
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal view returns (address pool) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            UNISWAP_V3_FACTORY,
                            keccak256(abi.encode(tokenA, tokenB, fee)),
                            POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }

    /// @notice Decodes the pool address from the path
    /// @param path The path to decode
    /// @return tokenA The first token
    /// @return tokenB The second token
    /// @return fee The fee
    function decodePool(
        bytes memory path
    ) internal pure returns (address tokenA, address tokenB, uint24 fee) {
        tokenA = BytesLib.toAddress(path, 0);
        fee = BytesLib.toUint24(path, 20);
        tokenB = BytesLib.toAddress(path, 23);
    }
}