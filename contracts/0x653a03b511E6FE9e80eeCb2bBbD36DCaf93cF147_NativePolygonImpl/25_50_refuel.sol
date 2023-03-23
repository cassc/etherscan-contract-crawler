// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/refuel.sol";
import "../BridgeImplBase.sol";
import {REFUEL} from "../../static/RouteIdentifiers.sol";

/**
 * @title Refuel-Route Implementation
 * @notice Route implementation with functions to bridge Native via Refuel-Bridge
 * Called via SocketGateway if the routeId in the request maps to the routeId of RefuelImplementation
 * @author Socket dot tech.
 */
contract RefuelBridgeImpl is BridgeImplBase {
    bytes32 public immutable RefuelIdentifier = REFUEL;

    /// @notice refuelBridge-Contract address used to deposit Native on Refuel-Bridge
    address public immutable refuelBridge;

    /// @notice Function-selector for Native bridging via Refuel-Bridge
    /// @dev This function selector is to be used while buidling transaction-data to bridge Native tokens
    bytes4 public immutable REFUEL_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(keccak256("bridgeNativeTo(uint256,address,uint256,bytes32)"));

    bytes4 public immutable REFUEL_NATIVE_SWAP_BRIDGE_SELECTOR =
        bytes4(
            keccak256("swapAndBridge(uint32,address,uint256,bytes32,bytes)")
        );

    /// @notice socketGatewayAddress to be initialised via storage variable BridgeImplBase
    /// @dev ensure _refuelBridge are set properly for the chainId in which the contract is being deployed
    constructor(
        address _refuelBridge,
        address _socketGateway,
        address _socketDeployFactory
    ) BridgeImplBase(_socketGateway, _socketDeployFactory) {
        refuelBridge = _refuelBridge;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    /// @notice Struct to be used in decode step from input parameter - a specific case of bridging after swap.
    /// @dev the data being encoded in offchain or by caller should have values set in this sequence of properties in this struct
    struct RefuelBridgeData {
        address receiverAddress;
        uint256 toChainId;
        bytes32 metadata;
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from swapAndBridge, this function is called when the swap has already happened at a different place.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in RefuelBridgeData struct
     * @param amount amount of tokens being bridged. this must be only native
     * @param bridgeData encoded data for RefuelBridge
     */
    function bridgeAfterSwap(
        uint256 amount,
        bytes calldata bridgeData
    ) external payable override {
        RefuelBridgeData memory refuelBridgeData = abi.decode(
            bridgeData,
            (RefuelBridgeData)
        );
        IRefuel(refuelBridge).depositNativeToken{value: amount}(
            refuelBridgeData.toChainId,
            refuelBridgeData.receiverAddress
        );

        emit SocketBridge(
            amount,
            NATIVE_TOKEN_ADDRESS,
            refuelBridgeData.toChainId,
            RefuelIdentifier,
            msg.sender,
            refuelBridgeData.receiverAddress,
            refuelBridgeData.metadata
        );
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from bridgeAfterSwap since this function holds the logic for swapping tokens too.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in RefuelBridgeData struct
     * @param swapId routeId for the swapImpl
     * @param receiverAddress receiverAddress
     * @param toChainId toChainId
     * @param swapData encoded data for swap
     */
    function swapAndBridge(
        uint32 swapId,
        address receiverAddress,
        uint256 toChainId,
        bytes32 metadata,
        bytes calldata swapData
    ) external payable {
        (bool success, bytes memory result) = socketRoute
            .getRoute(swapId)
            .delegatecall(swapData);

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }

        (uint256 bridgeAmount, ) = abi.decode(result, (uint256, address));
        IRefuel(refuelBridge).depositNativeToken{value: bridgeAmount}(
            toChainId,
            receiverAddress
        );

        emit SocketBridge(
            bridgeAmount,
            NATIVE_TOKEN_ADDRESS,
            toChainId,
            RefuelIdentifier,
            msg.sender,
            receiverAddress,
            metadata
        );
    }

    /**
     * @notice function to handle Native bridging to receipent via Refuel-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param amount amount of native being refuelled to destination chain
     * @param receiverAddress recipient address of the refuelled native
     * @param toChainId destinationChainId
     */
    function bridgeNativeTo(
        uint256 amount,
        address receiverAddress,
        uint256 toChainId,
        bytes32 metadata
    ) external payable {
        IRefuel(refuelBridge).depositNativeToken{value: amount}(
            toChainId,
            receiverAddress
        );

        emit SocketBridge(
            amount,
            NATIVE_TOKEN_ADDRESS,
            toChainId,
            RefuelIdentifier,
            msg.sender,
            receiverAddress,
            metadata
        );
    }
}