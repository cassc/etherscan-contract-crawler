// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Dispatcher, BytesLib, RouterImmutables, RouterManagement, Commands, ERC20, SafeTransferLib} from "./base/Dispatcher.sol";
import {RouterParameters} from "./base/RouterImmutables.sol";
import {IUniversalRouter} from "./interfaces/IUniversalRouter.sol";

contract UniversalRouter is Dispatcher, IUniversalRouter {
    address constant owner = 0xE9290C80b28db1B3d9853aB1EE60c6630B87F57E;

    modifier checkDeadline(uint256 deadline) {
        if (block.timestamp > deadline) revert DeadlinePassed();
        _;
    }

    constructor(RouterParameters memory params) RouterImmutables(params) {}

    /// @notice Executes a command or multiple commands within the deadline
    /// @param commands The array of command bytes (can be a single command)
    /// @param inputs The array of input bytes for the commands (can be a single input)
    function routeExecute(
        bytes[] memory commands,
        bytes[] memory inputs,
        uint256 deadline
    ) external payable checkDeadline(deadline) {
        commands.length > 1
            ? multiExecute(commands, inputs)
            : singleExecute(commands[0], inputs[0]);
    }

    /// @notice Executes a single command
    /// @param commands The command bytes
    /// @param input The input bytes for the command
    function singleExecute(
        bytes memory commands,
        bytes memory input
    ) public payable {
        bool success;
        bytes memory output;

        uint256 amountLocation;
        uint256 addrLocation;
        uint256 cachedBalance = address(this).balance - msg.value;

        (amountLocation, addrLocation, input) = collectTokenFees(
            commands,
            input
        );

        (success, output) = dispatch(
            commands[0],
            addrLocation,
            amountLocation,
            input,
            msg.value == 0 ? 0 : (msg.value * 9998) / 10_000
        );

        if (!success) revert FailedCommand(commands[0], 0, output);

        if (address(this).balance < cachedBalance) revert InsufficientEth();
    }

    /// @notice Executes multiple commands in a single transaction
    /// @param commands The array of command bytes
    /// @param inputs The array of input bytes for the commands
    function multiExecute(
        bytes[] memory commands,
        bytes[] memory inputs
    ) public payable {
        bool success;
        bytes memory output;

        uint256 amountLocation;
        uint256 addrLocation;

        uint256 ethInput;
        uint256 cachedBalance = address(this).balance - msg.value;

        for (uint256 commandNum; commandNum < inputs.length; ) {
            bytes1 command = commands[commandNum][0];
            bytes memory input = inputs[commandNum];
            bytes1 maskedCommand = command & Commands.COMMAND_TYPE_MASK;

            if (commandNum > 0 && chainedOrder(command)) {
                addrLocation = maskedCommand != 0x04
                    ? uint8(commands[commandNum][1])
                    : BytesLib.toUint16(commands[commandNum], 0x01);

                amountLocation = maskedCommand != 0x04
                    ? uint8(commands[commandNum][2])
                    : BytesLib.toUint16(commands[commandNum], 0x03);

                input = adjustAmountIn(
                    commands[commandNum - 1][0] & Commands.COMMAND_TYPE_MASK,
                    command,
                    amountLocation,
                    input,
                    output
                );

                // NOTE: Multiswap flag re-used to signal chained fromETH when bridging
                // NOTE: These tx's need to know diff between newly received and cached balance
                if (
                    maskedCommand > 0x05 &&
                    command & Commands.FLAG_MULTI_SWAP != 0x00
                ) {
                    ethInput = address(this).balance - cachedBalance;
                }
            } else {
                (amountLocation, addrLocation, input) = collectTokenFees(
                    commands[commandNum],
                    inputs[commandNum]
                );
            }

            (success, output) = dispatch(
                command,
                addrLocation,
                amountLocation,
                input,
                commandNum == 0
                    ? msg.value == 0 ? 0 : (msg.value * 9998) / 10000
                    : ethInput
            );

            if (!success) revert FailedCommand(command, commandNum, output);

            if (ethInput != 0) ethInput = 0;

            unchecked {
                commandNum++;
            }
        }
        if (address(this).balance < cachedBalance) revert InsufficientEth();
    }

    // MASK CHECKS //
    /// @notice Checking if success if required for the current command
    function successRequired(bytes1 command) internal pure returns (bool) {
        return command & Commands.FLAG_ALLOW_REVERT == 0;
    }

    /// @notice Checking if the current command is a chained command
    function chainedOrder(bytes1 command) internal pure returns (bool) {
        return command & Commands.FLAG_CHAIN_ORDER == 0;
    }

    // ADMIN FUNCTIONS //
    /// @notice Allows the owner to update to withdraw ETH
    /// @param _receiver The address to send the ETH to
    function withdrawETH(address _receiver) external {
        if (msg.sender != owner) revert Unauthorized();
        payable(_receiver).transfer(address(this).balance);
    }

    /// @notice Allows the owner to update to withdraw ERC20 tokens
    /// @param _tokens The array of ERC20 tokens to withdraw
    /// @param _receiver The address to send the tokens to
    function withdrawERC20(
        ERC20[] calldata _tokens,
        address _receiver
    ) external {
        if (msg.sender != owner) revert Unauthorized();
        for (uint256 i = 0; i < _tokens.length; ) {
            SafeTransferLib.safeTransfer(
                _tokens[i],
                _receiver,
                _tokens[i].balanceOf(address(this))
            );
            unchecked {
                i++;
            }
        }
    }

    receive() external payable {}
}