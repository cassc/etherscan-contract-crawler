// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./AbstractPayments.sol";
import "./interfaces/ICurvePool.sol";
import "./libraries/SwapPath.sol";
import "./libraries/Protocols.sol";

abstract contract CurveRouter is AbstractPayments {
    using SwapPath for bytes;

    struct CurvePayload {
        /// @dev The address of the Curve pool contract that the quote is being requested for
        address poolAddress;
        /// @dev The address of the swap contract that will be used to execute the token swap.
        address swapAddress;
        /// @dev The index of the input token in the Curve pool
        uint8 tokenInIndex;
        /// @dev The index of the output token in the Curve pool
        uint8 tokenOutIndex;
    }

    mapping(address => mapping(address => bool)) private approved;
    uint256 private constant DEFAULT_APPROVED = type(uint256).max;

    function _decodePath(
        bytes memory path
    ) internal pure returns (address tokenIn, address tokenOut, CurvePayload memory payload) {
        (
            tokenIn,
            tokenOut,
            payload.poolAddress,
            payload.swapAddress,
            payload.tokenInIndex,
            payload.tokenOutIndex
        ) = path.decodeFirstCurvePool();
    }

    function curveExactInputInternal(
        uint256 amountIn,
        bytes memory path,
        uint8 protocol,
        address recipient
    ) internal returns (uint256 amountOut) {
        (address tokenIn, address tokenOut, CurvePayload memory payload) = _decodePath(path);
        if (!approved[tokenIn][payload.poolAddress]) {
            IERC20(tokenIn).approve(payload.poolAddress, DEFAULT_APPROVED);
            approved[tokenIn][payload.poolAddress] = true;
        }

        if (protocol == Protocols.CURVE1) {
            ICurvePool(payload.poolAddress).exchange(
                int128(int8(payload.tokenInIndex)),
                int128(int8(payload.tokenOutIndex)),
                amountIn,
                0
            );
        } else if (protocol == Protocols.CURVE2) {
            ICurvePool(payload.poolAddress).exchange_underlying(
                int128(int8(payload.tokenInIndex)),
                int128(int8(payload.tokenOutIndex)),
                amountIn,
                0
            );
        } else if (protocol == Protocols.CURVE3) {
            ICurveCryptoPool(payload.poolAddress).exchange(
                uint256(payload.tokenInIndex),
                uint256(payload.tokenOutIndex),
                amountIn,
                0
            );
        } else if (protocol == Protocols.CURVE4) {
            ICurveCryptoPool(payload.poolAddress).exchange_underlying(
                uint256(payload.tokenInIndex),
                uint256(payload.tokenOutIndex),
                amountIn,
                0
            );
        } else if (protocol == Protocols.CURVE7) {
            uint256[2] memory _amounts;
            _amounts[payload.tokenInIndex] = amountIn;
            ICurveBasePool2Coins(payload.poolAddress).add_liquidity(_amounts, 0);
        } else if (protocol == Protocols.CURVE8) {
            uint256[3] memory _amounts;
            _amounts[payload.tokenInIndex] = amountIn;
            ICurveBasePool3Coins(payload.poolAddress).add_liquidity(_amounts, 0);
        } else if (protocol == Protocols.CURVE9) {
            uint256[3] memory _amounts;
            _amounts[payload.tokenInIndex] = amountIn;
            ICurveLendingBasePool3Coins(payload.poolAddress).add_liquidity(_amounts, 0, true);
        } else if (protocol == Protocols.CURVE10) {
            ICurveBasePool3Coins(payload.poolAddress).remove_liquidity_one_coin(
                amountIn,
                int128(int8(payload.tokenOutIndex)),
                0
            );
        } else if (protocol == Protocols.CURVE11) {
            ICurveLendingBasePool3Coins(payload.poolAddress).remove_liquidity_one_coin(
                amountIn,
                int128(int8(payload.tokenOutIndex)),
                0,
                true
            );
        } else if (protocol == Protocols.CURVE5) {
            ICurveLendingBasePoolMetaZap(payload.poolAddress).exchange_underlying(
                payload.swapAddress,
                int128(int8(payload.tokenInIndex)),
                int128(int8(payload.tokenOutIndex)),
                amountIn,
                0
            );
        } else if (protocol == Protocols.CURVE6) {
            ICurveCryptoMetaZap(payload.poolAddress).exchange(
                payload.swapAddress,
                uint256(payload.tokenInIndex),
                uint256(payload.tokenOutIndex),
                amountIn,
                0,
                false
            );
        } else {
            // CRQ_IP: invalid protocol
            revert("CRQ_IP");
        }
        amountOut = IERC20(tokenOut).balanceOf(address(this));
        if (recipient != address(this)) pay(tokenOut, address(this), recipient, amountOut);
    }

    function approveToCurvePool(address token, address poolAddress) external {
        IERC20(token).approve(poolAddress, DEFAULT_APPROVED);
        approved[token][poolAddress] = true;
    }
}