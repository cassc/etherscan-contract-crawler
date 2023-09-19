// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {IErrors} from "../../interfaces/IErrors.sol";
import {ICurvePair} from "../../interfaces/dexes/ICurvePair.sol";

contract CurveSwapper is IErrors {
    using SafeTransferLib for ERC20;
    address payable immutable wethAddress;

    constructor(address _wethAddress) {
        if (_wethAddress == address(0)) revert InvalidInput();
        wethAddress = payable(_wethAddress);
    }

    function _swapWithCurve(
        bytes calldata payload
    ) internal returns (uint256 amountOut) {
        // TODO: Need to find most efficient way to get the bytes
        bytes1 swapType = abi.decode(payload, (bytes1));
        if (swapType == 0x01) {
            (
                ,
                address fromToken,
                address toToken,
                int128 i,
                int128 j,
                address pool,
                uint256 fromAmount,
                uint256 toAmountMin
            ) = abi.decode(
                    payload,
                    (
                        bytes1,
                        address,
                        address,
                        int128,
                        int128,
                        address,
                        uint256,
                        uint256
                    )
                );
            amountOut = _swap(
                fromToken,
                toToken,
                pool,
                i,
                j,
                fromAmount,
                toAmountMin
            );
            if (amountOut == 0) revert InvalidOutput();
        } else if (swapType == 0x02) {
            (
                ,
                address fromToken,
                address toToken,
                uint256 i,
                uint256 j,
                address pool,
                uint256 fromAmount,
                uint256 toAmountIn
            ) = abi.decode(
                    payload,
                    (
                        bytes1,
                        address,
                        address,
                        uint256,
                        uint256,
                        address,
                        uint256,
                        uint256
                    )
                );
            amountOut = _swapEth(
                fromToken,
                toToken,
                pool,
                i,
                j,
                fromAmount,
                toAmountIn
            );
            if (amountOut == 0) revert InvalidOutput();
        } else if (swapType == 0x03) {
            return zapInMulti(payload);
        } else revert InvalidInput();
    }

    // NOTE: Logic has to be abstract to avoid stack too deep errors
    function zapInMulti(bytes calldata payload) internal returns (uint256) {
        (
            ,
            address[] memory path,
            address[] memory pools,
            uint256[] memory iValues,
            uint256[] memory jValues,
            uint256 fromAmount,
            uint256 toAmountMin
        ) = abi.decode(
                payload,
                (
                    bytes1,
                    address[],
                    address[],
                    uint256[],
                    uint256[],
                    uint256,
                    uint256
                )
            );
        uint256 amountOut = _multiSwap(
            path,
            pools,
            iValues,
            jValues,
            fromAmount,
            toAmountMin
        );
        if (amountOut == 0) revert InvalidOutput();
        return amountOut;
    }

    function _multiSwap(
        address[] memory path,
        address[] memory pools,
        uint256[] memory iValues,
        uint256[] memory jValues,
        uint256 fromAmount,
        uint256 toAmountMin
    ) internal returns (uint256 amountOut) {
        amountOut = fromAmount;
        for (uint256 i = 0; i < pools.length; ) {
            if (path[i + 1] != address(0)) {
                amountOut = _swap(
                    path[i],
                    path[i + 1],
                    pools[i],
                    int128(int256(iValues[i])),
                    int128(int256(jValues[i])),
                    amountOut,
                    i == pools.length - 1 ? toAmountMin : 0
                );
            } else {
                amountOut = _swapEth(
                    path[i],
                    wethAddress,
                    pools[i],
                    iValues[i],
                    jValues[i],
                    amountOut,
                    i == pools.length - 1 ? toAmountMin : 0
                );
            }
            unchecked {
                i++;
            }
        }
    }

    function _swap(
        address fromToken,
        address toToken,
        address pool,
        int128 i,
        int128 j,
        uint256 fromAmount,
        uint256 toAmountMin
    ) private returns (uint256) {
        ERC20(fromToken).safeApprove(pool, fromAmount);
        uint256 cachedBalance = ERC20(toToken).balanceOf(address(this));

        ICurvePair(pool).exchange(i, j, fromAmount, toAmountMin);
        fromAmount = ERC20(toToken).balanceOf(address(this)) - cachedBalance;
        return fromAmount;
    }

    function _swapEth(
        address fromToken,
        address toToken,
        address pool,
        uint256 i,
        uint256 j,
        uint256 fromAmount,
        uint256 toAmountMin
    ) private returns (uint256) {
        ERC20(fromToken).safeApprove(pool, fromAmount);
        uint256 cachedBalance = ERC20(toToken).balanceOf(address(this));

        ICurvePair(pool).exchange(i, j, fromAmount, toAmountMin, false);
        fromAmount = ERC20(toToken).balanceOf(address(this)) - cachedBalance;
        return fromAmount;
    }
}