// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Commands} from "../libraries/Commands.sol";
import {RouterImmutables} from "./RouterImmutables.sol";
import {RouterManagement} from "./RouterManagement.sol";

import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import {BytesLib} from "../libraries/BytesLib.sol";

import {UniswapRouter} from "../modules/UniswapRouter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {CurveRouter} from "../modules/CurveRouter.sol";

abstract contract Dispatcher is RouterManagement, UniswapRouter, CurveRouter {
    error NothingReceived();

    /// @notice Dispatch the call to the right DEX or Bridge
    /// @param commandType The command for the transaction
    /// @param addrLocation The location of the address in the inputs bytes
    /// @param amountLocation The location of the amount in the inputs bytes
    /// @param inputs The inputs bytes for the command
    /// @param valueAfterFee The amount of ETH to (fees have been applied to this)
    /// @return success Whether the call was successful
    /// @return output The output bytes from the call
    function dispatch(
        bytes1 commandType,
        uint256 addrLocation,
        uint256 amountLocation,
        bytes memory inputs,
        uint256 valueAfterFee
    ) internal returns (bool success, bytes memory output) {
        uint256 command = uint8(commandType & Commands.COMMAND_TYPE_MASK);
        if (command < 0x06) {
            if (command < 0x03) {
                if (command == Commands.UNISWAP_V2) {
                    (output) = swapV2(
                        inputs,
                        BytesLib.toAddress(inputs, addrLocation),
                        BytesLib.toUint256(inputs, amountLocation)
                    );
                    success = true;
                } else if (command == Commands.UNISWAP_V3) {
                    (output) = swapV3(
                        inputs,
                        BytesLib.toAddress(inputs, addrLocation),
                        BytesLib.toUint256(inputs, amountLocation)
                    );
                    success = true;
                } else if (command == Commands.V2_FORK) {
                    uint256 destinationCode = BytesLib.toUint8(
                        inputs,
                        inputs.length - 0x01
                    );
                    (success, output) = sendCall(
                        destinationCode == 0
                            ? SUSHISWAP_ROUTER
                            : destinationCode == 1
                            ? PANCAKESWAP_ROUTER
                            : SHIBASWAP_ROUTER,
                        addrLocation,
                        amountLocation,
                        valueAfterFee,
                        BytesLib.sliceBytes(inputs, 0x0, inputs.length - 0x01)
                    );
                }
            } else {
                if (command == Commands.CURVE) {
                    (output) = swapCurve(
                        inputs,
                        BytesLib.toAddress(inputs, addrLocation),
                        BytesLib.toUint256(inputs, amountLocation)
                    );
                    success = true;
                } else if (command == Commands.BALANCER) {
                    if (valueAfterFee == 0)
                        SafeTransferLib.safeApprove(
                            ERC20(BytesLib.toAddress(inputs, addrLocation)),
                            BALANCER_ROUTER,
                            BytesLib.toUint256(inputs, amountLocation)
                        );
                    if (commandType & Commands.FLAG_MULTI_SWAP != 0x00) {
                        inputs = BytesLib.sliceBytes(
                            inputs,
                            0x0,
                            inputs.length - 0x14
                        );
                    }
                    (success, output) = BALANCER_ROUTER.call{
                        value: valueAfterFee
                    }(inputs);
                } else if (command == Commands.BANCOR) {
                    (success, output) = sendCall(
                        BANCOR_ROUTER,
                        addrLocation,
                        amountLocation,
                        valueAfterFee,
                        inputs
                    );
                }
            }
        } else if (command < 0x0f) {
            if (command < 0x0a) {
                if (command == Commands.HOP_BRIDGE) {
                    uint256 destinationCode = BytesLib.toUint8(
                        inputs,
                        inputs.length - 0x01
                    );
                    address destination = destinationCode < 3
                        ? destinationCode == 0
                            ? HOP_ETH_BRIDGE
                            : destinationCode == 1
                            ? HOP_USDC_BRIDGE
                            : HOP_WBTC_BRIDGE
                        : destinationCode == 3
                        ? HOP_USDT_BRIDGE
                        : destinationCode == 4
                        ? HOP_DAI_BRIDGE
                        : HOP_MATIC_BRIDGE;
                    if (valueAfterFee == 0)
                        SafeTransferLib.safeApprove(
                            ERC20(BytesLib.toAddress(inputs, addrLocation)),
                            destination,
                            BytesLib.toUint256(inputs, amountLocation)
                        );
                    (success, output) = destination.call{value: valueAfterFee}(
                        BytesLib.sliceBytes(inputs, 0x0, 0xF8)
                    );
                } else if (command == Commands.ACROSS_BRIDGE) {
                    (success, output) = sendCall(
                        ACROSS_BRIDGE,
                        addrLocation,
                        amountLocation,
                        valueAfterFee,
                        inputs
                    );
                } else if (command == Commands.CELER_BRIDGE) {
                    (success, output) = sendCall(
                        CELER_BRIDGE,
                        addrLocation,
                        amountLocation,
                        valueAfterFee,
                        inputs
                    );
                } else if (command == Commands.SYNAPSE_BRIDGE) {
                    (success, output) = sendCall(
                        SYNAPSE_BRIDGE,
                        addrLocation,
                        amountLocation,
                        valueAfterFee,
                        inputs
                    );
                }
            } else {
                if (command == Commands.MULTICHAIN_BRIDGE) {
                    if (valueAfterFee == 0) {
                        SafeTransferLib.safeApprove(
                            ERC20(BytesLib.toAddress(inputs, addrLocation)),
                            MULTICHAIN_ERC20_BRIDGE,
                            BytesLib.toUint256(inputs, amountLocation)
                        );
                        (success, output) = MULTICHAIN_ERC20_BRIDGE.call(
                            BytesLib.sliceBytes(inputs, 0x0, 0x90)
                        );
                    } else {
                        (success, output) = MULTICHAIN_ETH_BRIDGE.call{
                            value: valueAfterFee
                        }(inputs);
                    }
                } else if (command == Commands.HYPHEN_BRIDGE) {
                    (success, output) = sendCall(
                        HYPHEN_BRIDGE,
                        addrLocation,
                        amountLocation,
                        valueAfterFee,
                        inputs
                    );
                } else if (command == Commands.PORTAL_BRIDGE) {
                    if (valueAfterFee == 0)
                        SafeTransferLib.safeApprove(
                            ERC20(BytesLib.toAddress(inputs, addrLocation)),
                            PORTAL_BRIDGE,
                            BytesLib.toUint256(inputs, amountLocation)
                        );
                    bytes memory adjustedInputs = abi.encode(
                        bytes32(
                            uint256(uint160(BytesLib.toAddress(inputs, 0x70)))
                        ),
                        BytesLib.toUint256(inputs, 0x84),
                        block.timestamp
                    );
                    (success, output) = PORTAL_BRIDGE.call{
                        value: valueAfterFee
                    }(
                        BytesLib.concat(
                            BytesLib.sliceBytes(inputs, 0x0, 0x64),
                            adjustedInputs
                        )
                    );
                } else if (command == Commands.ALL_BRIDGE) {
                    (success, output) = sendCall(
                        ALL_BRIDGE,
                        addrLocation,
                        amountLocation,
                        valueAfterFee,
                        inputs
                    );
                }
            }
        } else {
            if (command == Commands.OPTIMISM_BRIDGE) {
                (success, output) = sendCall(
                    OPTIMISM_BRIDGE,
                    addrLocation,
                    amountLocation,
                    valueAfterFee,
                    inputs
                );
            } else if (command == Commands.POLYGON_POS_BRIDGE) {
                if (valueAfterFee == 0)
                    SafeTransferLib.safeApprove(
                        ERC20(BytesLib.toAddress(inputs, addrLocation)),
                        POLYGON_APPROVE_ADDR,
                        BytesLib.toUint256(inputs, amountLocation)
                    );
                (success, output) = POLYGON_POS_BRIDGE.call{
                    value: valueAfterFee
                }(inputs);
            } else if (command == Commands.OMNI_BRIDGE) {
                (success, output) = sendCall(
                    OMNI_BRIDGE,
                    addrLocation,
                    amountLocation,
                    0,
                    inputs
                );
            }
        }
    }

    /// @notice Sends a call to the destination contract
    /// @param destination The destination contract address
    /// @param addrLocation The location of the token address in the input
    /// @param amountLocation The location of the amount in the input
    /// @param valueAfterFee The amount of ETH to send with the call
    /// @param input The input data to send to the destination contract
    /// @return success The success of the call
    /// @return output The output of the call
    function sendCall(
        address destination,
        uint256 addrLocation,
        uint256 amountLocation,
        uint256 valueAfterFee,
        bytes memory input
    ) internal returns (bool success, bytes memory output) {
        if (valueAfterFee == 0)
            SafeTransferLib.safeApprove(
                ERC20(BytesLib.toAddress(input, addrLocation)),
                destination,
                BytesLib.toUint256(input, amountLocation)
            );
        (success, output) = destination.call{value: valueAfterFee}(input);
    }
}