// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {SafeTransferLib} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";
import {BytesLib} from "../libraries/BytesLib.sol";
import {ICurvePool, ICryptoPool} from "../interfaces/ICurvePool.sol";
import {IErrors} from "../interfaces/IErrors.sol";

abstract contract CurveRouter is IErrors {
    /// @notice Swaps tokens on Curve
    /// @param input The input bytes
    /// @param fromToken The first token to swap from
    /// @param amountIn The first amountIn to swap
    function swapCurve(
        bytes memory input,
        address fromToken,
        uint256 amountIn
    ) internal returns (bytes memory output) {
        uint256 swapLength = BytesLib.toUint8(input, input.length - 2);
        address recipient = BytesLib.toUint8(input, input.length - 1) == 0
            ? msg.sender
            : BytesLib.toAddress(input, input.length - 22);
        uint256 skipToInfo = (0x54 + (swapLength * 0x28));
        uint256 balanceBefore;

        for (uint256 i; i < swapLength; ) {
            address pool = BytesLib.toAddress(input, 0x54 + (i * 0x28));
            address toToken = BytesLib.toAddress(input, 0x68 + (i * 0x28));
            bool toEth = toToken == address(0);

            /**
            Location is: 
            - Pushing past pool info and fromToken (20 + (i * 40 bytes)) = (0x54 + (swapLength * 0x28)) 
            - Pushing past each grouping of info (6 bytes * 1) + 0x40 for amountIn and out = (i * 0x06) 
            --> BytesLib.sliceBytes(input, (0x54 + (swapLength * 0x28)) + (i * 0x06), 0x40);

            Step 1 - Encodes: selector, i, j, amountIn
            Step 2 - Appends empty 32 bytes or amountOutMin

             */
            output = BytesLib.concat(
                BytesLib.sliceBytes(input, skipToInfo + (i * 0x6), 0x04),
                abi.encode(
                    BytesLib.toUint8(input, skipToInfo + (i * 0x6) + 0x04),
                    BytesLib.toUint8(input, skipToInfo + (i * 0x6) + 0x05),
                    amountIn
                )
            );

            if (fromToken != address(0) && !toEth) {
                SafeTransferLib.safeApprove(ERC20(fromToken), pool, amountIn);
                output = BytesLib.concat(
                    output,
                    i == swapLength - 1
                        ? BytesLib.sliceBytes(input, 0x34, 0x20)
                        : abi.encode(0)
                );
                balanceBefore = ERC20(toToken).balanceOf(address(this));
            } else {
                if (fromToken != address(0)) {
                    SafeTransferLib.safeApprove(
                        ERC20(fromToken),
                        pool,
                        amountIn
                    );
                }

                output = BytesLib.concat(
                    output,
                    BytesLib.concat(
                        i == swapLength - 1
                            ? BytesLib.sliceBytes(input, 0x34, 0x20)
                            : abi.encode(0),
                        abi.encode(true)
                    )
                );

                balanceBefore = toEth
                    ? address(this).balance
                    : ERC20(toToken).balanceOf(address(this));
            }

            (bool success, bytes memory message) = pool.call{
                value: fromToken == address(0) ? amountIn : 0
            }(output);
            if (!success) revert ThrowingError(message);

            amountIn = toEth
                ? address(this).balance - balanceBefore
                : ERC20(toToken).balanceOf(address(this)) - balanceBefore;
            fromToken = toToken;

            unchecked {
                i++;
            }
        }

        // NOTE: Re-using fromToken for toToken as declared outside of loop
        if (recipient != address(this)) {
            if (fromToken != address(0)) {
                SafeTransferLib.safeTransfer(
                    ERC20(fromToken),
                    recipient,
                    amountIn
                );
            } else {
                SafeTransferLib.safeTransferETH(recipient, amountIn);
            }
        }
        output = abi.encode(amountIn);
    }
}