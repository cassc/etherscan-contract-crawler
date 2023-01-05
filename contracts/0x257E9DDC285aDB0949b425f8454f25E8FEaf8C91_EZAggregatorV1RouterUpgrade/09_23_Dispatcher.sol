// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {HandleReservoir} from "../modules/HandleReservoir.sol";
import {HandleLSSVM} from "../modules/HandleLSSVM.sol";

import {Payments} from "../modules/Payments.sol";
import {RouterImmutables} from "../base/RouterImmutables.sol";
import {Callbacks} from "../base/Callbacks.sol";
import {Commands} from "../libraries/Commands.sol";
import {Recipient} from "../libraries/Recipient.sol";
import {ERC721} from "solmate/src/tokens/ERC721.sol";
import {ERC1155} from "solmate/src/tokens/ERC1155.sol";

/// @title Decodes and Executes Commands
/// @notice Called by the UniversalRouter contract to efficiently decode and execute a singular command
abstract contract Dispatcher is
    Payments,
    HandleReservoir,
    HandleLSSVM,
    Callbacks
{
    using Recipient for address;

    error InvalidCommandType(uint256 commandType);
    error InvalidOwnerERC721();
    error InvalidOwnerERC1155();

    /// @notice Decodes and executes the given command with the given inputs
    /// @param commandType The command type to execute
    /// @param inputs The inputs to execute the command with
    /// @dev 2 masks are used to enable use of a nested-if statement in execution for efficiency reasons
    /// @return success True on success of the command, false on failure
    /// @return output The outputs or error messages, if any, from the command
    function dispatch(
        bytes1 commandType,
        bytes memory inputs
    ) internal returns (bool success, bytes memory output) {
        uint256 command = uint8(commandType & Commands.COMMAND_TYPE_MASK);

        success = true;

        if (command < 0x10) {
            // 0x00 <= command < 0x08
            if (command < 0x08) {
                if (command == Commands.RESERVOIR_Buy) {
                    (uint256 value, bytes memory data) = abi.decode(
                        inputs,
                        (uint256, bytes)
                    );

                    (success, output) = RESERVOIR.call{value: value}(data);

                } else if (command == Commands.RESERVOIR_Sell) {
                    ReservoirOfferStruct[] memory reservoirOffers = abi.decode(
                        inputs,
                        (ReservoirOfferStruct[])
                    );

                    HandleReservoir.handleReservoirSell(reservoirOffers);
                } else if (command == Commands.WRAP_ETH) {
                    (address recipient, uint256 amountMin) = abi.decode(
                        inputs,
                        (address, uint256)
                    );
                    Payments.wrapETH(recipient.map(), amountMin);
                } else if (command == Commands.UNWRAP_WETH) {
                    (address recipient, uint256 amountMin) = abi.decode(
                        inputs,
                        (address, uint256)
                    );
                    Payments.unwrapWETH9(recipient.map(), amountMin);
                } else if (command == Commands.SWEEP) {
                    (address token, address recipient, uint256 amountMin) = abi
                        .decode(inputs, (address, address, uint256));
                    Payments.sweep(token, recipient.map(), amountMin);
                } else if (command == Commands.TRANSFER) {
                    (address token, address recipient, uint256 value) = abi
                        .decode(inputs, (address, address, uint256));
                    Payments.pay(token, recipient.map(), value);
                } else if (command == Commands.PAY_PORTION) {
                    (address token, address recipient, uint256 bips) = abi
                        .decode(inputs, (address, address, uint256));
                    Payments.payPortion(token, recipient.map(), bips);
                } else if (command == Commands.COMMAND_PLACEHOLDER_0x07) {
                    // placeholder for a future command
                    revert InvalidCommandType(command);
                }
                // 0x08 <= command < 0x10
            } else {
                if (command == Commands.SUDOSWAP_Buy) {
                    (uint256 value, bytes memory data) = abi.decode(
                        inputs,
                        (uint256, bytes)
                    );
                    (success, output) = SUDOSWAP.call{value: value}(data);
                } else if (command == Commands.SUDOSWAP_Sell) {
                    (
                        bytes memory data,
                        address nftOwner,
                        LSSVMSellNftStruct[] memory sellNfts
                    ) = abi.decode(
                            inputs,
                            (bytes, address, LSSVMSellNftStruct[])
                        );

                    (success, output) = HandleLSSVM.handleLSSVMSell(
                        SUDOSWAP,
                        data,
                        nftOwner,
                        sellNfts
                    );
                } else if (command == Commands.EZSWAP_Buy) {
                    (uint256 value, bytes memory data) = abi.decode(
                        inputs,
                        (uint256, bytes)
                    );
                    (success, output) = EZSWAP.call{value: value}(data);
                } else if (command == Commands.EZSWAP_Sell) {
                    (
                        bytes memory data,
                        address nftOwner,
                        LSSVMSellNftStruct[] memory sellNfts
                    ) = abi.decode(
                            inputs,
                            (bytes, address, LSSVMSellNftStruct[])
                        );

                    (success, output) = HandleLSSVM.handleLSSVMSell(
                        EZSWAP,
                        data,
                        nftOwner,
                        sellNfts
                    );
                } else if (command == Commands.SWEEP_ERC721) {
                    (address token, address recipient, uint256 id) = abi.decode(
                        inputs,
                        (address, address, uint256)
                    );
                    Payments.sweepERC721(token, recipient.map(), id);
                } else if (command == Commands.SWEEP_ERC1155) {
                    (
                        address token,
                        address recipient,
                        uint256 id,
                        uint256 amount
                    ) = abi.decode(
                            inputs,
                            (address, address, uint256, uint256)
                        );
                    Payments.sweepERC1155(token, recipient.map(), id, amount);
                } else if (command == Commands.COMMAND_PLACEHOLDER_0x0e) {
                    // placeholder for a future command
                    revert InvalidCommandType(command);
                } else if (command == Commands.COMMAND_PLACEHOLDER_0x0f) {
                    // placeholder for a future command
                    revert InvalidCommandType(command);
                }
            }
            // 0x10 <= command
        } else {
            // 0x10 <= command < 0x18
            // 0x18 <= command < 0x1f
            // placeholder for a future command
            revert InvalidCommandType(command);
        }
    }
}