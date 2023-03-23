// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import {RouterImmutables} from "./RouterImmutables.sol";
import {BytesLib} from "../libraries/BytesLib.sol";
import {Commands} from "../libraries/Commands.sol";

abstract contract RouterManagement is RouterImmutables {
    error InvalidCommand();

    /// @notice Collects token fees from user and adjusts input bytes
    /// @param commands The commands bytes
    /// @param inputs The inputs bytes for the command
    /// @return amountLocation The location of the amount in the inputs bytes
    /// @return addrLocation The location of the address in the inputs bytes
    /// @return inputs The adjusted input bytes after fees deducted
    function collectTokenFees(
        bytes memory commands,
        bytes memory inputs
    )
        internal
        returns (uint256 amountLocation, uint256 addrLocation, bytes memory)
    {
        uint256 command = uint8(
            bytes1(commands[0]) & Commands.COMMAND_TYPE_MASK
        );

        if (command != 0x04) {
            addrLocation = uint8(commands[1]);
            amountLocation = uint8(commands[2]);
        } else {
            if (bytes1(commands[0]) & Commands.FLAG_MULTI_SWAP == 0x00) {
                addrLocation = 0x130;
                amountLocation = 0x164;
            } else {
                addrLocation = inputs.length - 0x14;
                amountLocation =
                    0x60 +
                    0x144 +
                    BytesLib.toUint256(inputs, 0x144);
                uint256 limitLocation = BytesLib.toUint256(inputs, 0xE4) +
                    0x24 +
                    (0x20 * BytesLib.toUint256(inputs, amountLocation - 0x40));
                bytes memory appendedBytes = BytesLib.concat(
                    abi.encode(
                        (BytesLib.toUint256(inputs, limitLocation) * 9998) /
                            10_000
                    ),
                    BytesLib.sliceBytes(
                        inputs,
                        limitLocation + 32,
                        inputs.length - limitLocation - 32
                    )
                );
                inputs = BytesLib.concat(
                    BytesLib.sliceBytes(inputs, 0, limitLocation),
                    appendedBytes
                );
            }
        }

        if (command > 0x0a && msg.value > 0)
            return (amountLocation, addrLocation, inputs);

        uint256 amount = BytesLib.toUint256(inputs, amountLocation);

        if (msg.value == 0)
            SafeTransferLib.safeTransferFrom(
                ERC20(BytesLib.toAddress(inputs, addrLocation)),
                msg.sender,
                address(this),
                amount
            );
        bytes memory adjustedBytes = BytesLib.concat(
            abi.encode((amount * 9998) / 10_000),
            BytesLib.sliceBytes(
                inputs,
                amountLocation + 32,
                inputs.length - amountLocation - 32
            )
        );

        if (command == 0x01 || command == 0x02)
            return (amountLocation, addrLocation, adjustedBytes);

        inputs = BytesLib.concat(
            BytesLib.sliceBytes(inputs, 0, amountLocation),
            adjustedBytes
        );

        return (amountLocation, addrLocation, inputs);
    }

    /// @notice Adjusts the amountIn for the next command when chained
    /// @param _previousCommand The previous command bytes
    /// @param _nextCommand The next command bytes
    /// @param _amountInLocation The location of amountIn for next command
    /// @param _nextInputBytes The input bytes for the next command
    /// @param _amountOutBytes The amountOut output bytes for the previous command
    /// @return adjustedBytes The adjusted input bytes for the next command
    function adjustAmountIn(
        bytes1 _previousCommand,
        bytes1 _nextCommand,
        uint256 _amountInLocation,
        bytes memory _nextInputBytes,
        bytes memory _amountOutBytes
    ) internal pure returns (bytes memory adjustedBytes) {
        // NOTE: When command >0x0a and flag fromEth bridge we return as no amount input used
        if (
            _nextCommand & Commands.COMMAND_TYPE_MASK > 0x0a &&
            _nextCommand & Commands.FLAG_MULTI_SWAP != 0x00
        ) return _nextInputBytes;

        uint256 _startSlice;
        // NOTE: Balancer multiswap will have amountOutBytes > 32 bytes
        if (_previousCommand == 0x04 && _amountOutBytes.length > 0x20) {
            _amountOutBytes = abi.encode(
                uint256(
                    -(
                        abi.decode(
                            BytesLib.sliceBytes(_amountOutBytes, 64, 32),
                            (int256)
                        )
                    )
                )
            );
        } else {
            if (_previousCommand > 0x00 && _previousCommand < 0x05) {
                // NOTE: AmountOut starts at 0 bytes for V2, V3, Curve, and Balancer single
            } else if (_previousCommand == 0x00) {
                _startSlice = _amountOutBytes.length - 0x20;
            } else if (_previousCommand == 0x05) {
                _startSlice = 0x44;
            } else {
                revert InvalidCommand();
            }
        }

        if (
            _nextCommand & Commands.COMMAND_TYPE_MASK == 0x04 &&
            _nextCommand & Commands.FLAG_MULTI_SWAP != 0x00
        ) {
            // NOTE: 0xE4 used as 0xE0 + 4 bytes for funcSelector
            // NOTE: 0x24 skips first slot for length of limit + 4 bytes for func selector as bytes do not factor this in
            uint256 limitLocation = BytesLib.toUint256(_nextInputBytes, 0xE4) +
                0x24 +
                (0x20 *
                    BytesLib.toUint256(
                        _nextInputBytes,
                        _amountInLocation - 0x40
                    ));
            bytes memory appendedBytes = BytesLib.concat(
                BytesLib.sliceBytes(_amountOutBytes, _startSlice, 32),
                BytesLib.sliceBytes(
                    _nextInputBytes,
                    limitLocation + 32,
                    _nextInputBytes.length - limitLocation - 32
                )
            );
            _nextInputBytes = BytesLib.concat(
                BytesLib.sliceBytes(_nextInputBytes, 0, limitLocation),
                appendedBytes
            );
        }

        // NOTE: Slice bytes up to the amountInLocation
        adjustedBytes = BytesLib.sliceBytes(
            _nextInputBytes,
            0,
            _amountInLocation
        );

        // NOTE: Concatenate amountOut bytes and appending bytes to sliced bytes
        adjustedBytes = BytesLib.concat(
            adjustedBytes,
            BytesLib.concat(
                BytesLib.sliceBytes(_amountOutBytes, _startSlice, 32),
                BytesLib.sliceBytes(
                    _nextInputBytes,
                    _amountInLocation + 32,
                    _nextInputBytes.length - _amountInLocation - 32
                )
            )
        );
    }
}