// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {L1GatewayRouter} from "../interfaces/arbitrum.sol";
import {BridgeImplBase} from "../../BridgeImplBase.sol";
import {NATIVE_ARBITRUM} from "../../../static/RouteIdentifiers.sol";

/**
 * @title Native Arbitrum-Route Implementation
 * @notice Route implementation with functions to bridge ERC20 via NativeArbitrum-Bridge
 * @notice Called via SocketGateway if the routeId in the request maps to the routeId of NativeArbitrum-Implementation
 * @notice This is used when transferring from ethereum chain to arbitrum via their native bridge.
 * @notice Contains function to handle bridging as post-step i.e linked to a preceeding step for swap
 * @notice RequestData is different to just bride and bridging chained with swap
 * @author Socket dot tech.
 */
contract NativeArbitrumImpl is BridgeImplBase {
    /// @notice SafeTransferLib - library for safe and optimised operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    bytes32 public immutable NativeArbitrumIdentifier = NATIVE_ARBITRUM;

    uint256 public constant DESTINATION_CHAIN_ID = 42161;

    /// @notice Function-selector for ERC20-token bridging on NativeArbitrum
    /// @dev This function selector is to be used while buidling transaction-data to bridge ERC20 tokens
    bytes4
        public immutable NATIVE_ARBITRUM_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "bridgeERC20To(uint256,uint256,uint256,uint256,bytes32,address,address,address,bytes)"
            )
        );

    bytes4 public immutable NATIVE_ARBITRUM_SWAP_BRIDGE_SELECTOR =
        bytes4(
            keccak256(
                "swapAndBridge(uint32,bytes,(uint256,uint256,uint256,address,address,bytes32,bytes))"
            )
        );

    /// @notice router address of NativeArbitrum Bridge
    /// @notice GatewayRouter looks up ERC20Token's gateway, and finding that it's Standard ERC20 gateway (the L1ERC20Gateway contract).
    address public immutable router;

    /// @notice socketGatewayAddress to be initialised via storage variable BridgeImplBase
    /// @dev ensure router-address are set properly for the chainId in which the contract is being deployed
    constructor(
        address _router,
        address _socketGateway,
        address _socketDeployFactory
    ) BridgeImplBase(_socketGateway, _socketDeployFactory) {
        router = _router;
    }

    /// @notice Struct to be used in decode step from input parameter - a specific case of bridging after swap.
    /// @dev the data being encoded in offchain or by caller should have values set in this sequence of properties in this struct
    struct NativeArbitrumBridgeDataNoToken {
        uint256 value;
        /// @notice maxGas is a depositParameter derived from erc20Bridger of nativeArbitrum
        uint256 maxGas;
        /// @notice gasPriceBid is a depositParameter derived from erc20Bridger of nativeArbitrum
        uint256 gasPriceBid;
        /// @notice address of receiver of bridged tokens
        address receiverAddress;
        /// @notice address of Gateway which handles the token bridging for the token
        /// @notice gatewayAddress is unique for each token
        address gatewayAddress;
        /// @notice socket offchain created hash
        bytes32 metadata;
        /// @notice data is a depositParameter derived from erc20Bridger of nativeArbitrum
        bytes data;
    }

    struct NativeArbitrumBridgeData {
        uint256 value;
        /// @notice maxGas is a depositParameter derived from erc20Bridger of nativeArbitrum
        uint256 maxGas;
        /// @notice gasPriceBid is a depositParameter derived from erc20Bridger of nativeArbitrum
        uint256 gasPriceBid;
        /// @notice address of receiver of bridged tokens
        address receiverAddress;
        /// @notice address of Gateway which handles the token bridging for the token
        /// @notice gatewayAddress is unique for each token
        address gatewayAddress;
        /// @notice address of token being bridged
        address token;
        /// @notice socket offchain created hash
        bytes32 metadata;
        /// @notice data is a depositParameter derived from erc20Bridger of nativeArbitrum
        bytes data;
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from swapAndBridge, this function is called when the swap has already happened at a different place.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in NativeArbitrumBridgeData struct
     * @param amount amount of tokens being bridged. this can be ERC20 or native
     * @param bridgeData encoded data for NativeArbitrumBridge
     */
    function bridgeAfterSwap(
        uint256 amount,
        bytes calldata bridgeData
    ) external payable override {
        NativeArbitrumBridgeData memory nativeArbitrumBridgeData = abi.decode(
            bridgeData,
            (NativeArbitrumBridgeData)
        );
        ERC20(nativeArbitrumBridgeData.token).safeApprove(
            nativeArbitrumBridgeData.gatewayAddress,
            amount
        );

        L1GatewayRouter(router).outboundTransfer{
            value: nativeArbitrumBridgeData.value
        }(
            nativeArbitrumBridgeData.token,
            nativeArbitrumBridgeData.receiverAddress,
            amount,
            nativeArbitrumBridgeData.maxGas,
            nativeArbitrumBridgeData.gasPriceBid,
            nativeArbitrumBridgeData.data
        );

        emit SocketBridge(
            amount,
            nativeArbitrumBridgeData.token,
            DESTINATION_CHAIN_ID,
            NativeArbitrumIdentifier,
            msg.sender,
            nativeArbitrumBridgeData.receiverAddress,
            nativeArbitrumBridgeData.metadata
        );
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from bridgeAfterSwap since this function holds the logic for swapping tokens too.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in NativeArbitrumBridgeData struct
     * @param swapId routeId for the swapImpl
     * @param swapData encoded data for swap
     * @param nativeArbitrumBridgeData encoded data for NativeArbitrumBridge
     */
    function swapAndBridge(
        uint32 swapId,
        bytes calldata swapData,
        NativeArbitrumBridgeDataNoToken calldata nativeArbitrumBridgeData
    ) external payable {
        (bool success, bytes memory result) = socketRoute
            .getRoute(swapId)
            .delegatecall(swapData);

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }

        (uint256 bridgeAmount, address token) = abi.decode(
            result,
            (uint256, address)
        );
        ERC20(token).safeApprove(
            nativeArbitrumBridgeData.gatewayAddress,
            bridgeAmount
        );

        L1GatewayRouter(router).outboundTransfer{
            value: nativeArbitrumBridgeData.value
        }(
            token,
            nativeArbitrumBridgeData.receiverAddress,
            bridgeAmount,
            nativeArbitrumBridgeData.maxGas,
            nativeArbitrumBridgeData.gasPriceBid,
            nativeArbitrumBridgeData.data
        );

        emit SocketBridge(
            bridgeAmount,
            token,
            DESTINATION_CHAIN_ID,
            NativeArbitrumIdentifier,
            msg.sender,
            nativeArbitrumBridgeData.receiverAddress,
            nativeArbitrumBridgeData.metadata
        );
    }

    /**
     * @notice function to handle ERC20 bridging to receipent via NativeArbitrum-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param amount amount being bridged
     * @param value value
     * @param maxGas maxGas is a depositParameter derived from erc20Bridger of nativeArbitrum
     * @param gasPriceBid gasPriceBid is a depositParameter derived from erc20Bridger of nativeArbitrum
     * @param receiverAddress address of receiver of bridged tokens
     * @param token address of token being bridged
     * @param gatewayAddress address of Gateway which handles the token bridging for the token, gatewayAddress is unique for each token
     * @param data data is a depositParameter derived from erc20Bridger of nativeArbitrum
     */
    function bridgeERC20To(
        uint256 amount,
        uint256 value,
        uint256 maxGas,
        uint256 gasPriceBid,
        bytes32 metadata,
        address receiverAddress,
        address token,
        address gatewayAddress,
        bytes memory data
    ) external payable {
        ERC20 tokenInstance = ERC20(token);
        tokenInstance.safeTransferFrom(msg.sender, socketGateway, amount);
        tokenInstance.safeApprove(gatewayAddress, amount);

        L1GatewayRouter(router).outboundTransfer{value: value}(
            token,
            receiverAddress,
            amount,
            maxGas,
            gasPriceBid,
            data
        );

        emit SocketBridge(
            amount,
            token,
            DESTINATION_CHAIN_ID,
            NativeArbitrumIdentifier,
            msg.sender,
            receiverAddress,
            metadata
        );
    }
}