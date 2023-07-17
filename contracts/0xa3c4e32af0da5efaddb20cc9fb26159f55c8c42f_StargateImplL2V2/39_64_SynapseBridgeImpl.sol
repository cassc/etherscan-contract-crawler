// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/ISynapseRouter.sol";
import "../BridgeImplBase.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {SYNAPSE} from "../../static/RouteIdentifiers.sol";

/**
 * @title Synapse-Route Implementation
 * @notice Route implementation with functions to bridge ERC20 and Native via Synapse-Bridge
 * Called via SocketGateway if the routeId in the request maps to the routeId of SynapseImplementation
 * Contains function to handle bridging as post-step i.e linked to a preceeding step for swap
 * RequestData is different to just bride and bridging chained with swap
 * @author Socket dot tech.
 */
contract SynapseBridgeImpl is BridgeImplBase {
    /// @notice SafeTransferLib - library for safe and optimised operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    bytes32 public immutable SynapseIdentifier = SYNAPSE;

    /// @notice max value for uint256
    uint256 public constant UINT256_MAX = type(uint256).max;

    /// @notice Function-selector for ERC20-token bridging on Synapse-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge ERC20 tokens
    bytes4 public immutable SYNAPSE_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "bridgeERC20To(uint256,bytes32,address,address,uint256,(address,address,uint256,uint256,bytes),(address,address,uint256,uint256,bytes))"
            )
        );

    /// @notice Function-selector for Native bridging on Synapse-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge Native tokens
    bytes4 public immutable SYNAPSE_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "bridgeNativeTo(uint256,bytes32,address,uint256,(address,address,uint256,uint256,bytes),(address,address,uint256,uint256,bytes))"
            )
        );

    bytes4 public immutable SYNAPSE_SWAP_BRIDGE_SELECTOR =
        bytes4(
            keccak256(
                "swapAndBridge(uint32,bytes,(address,uint256,bytes32,(address,address,uint256,uint256,bytes),(address,address,uint256,uint256,bytes)))"
            )
        );

    ISynapseRouter public immutable synapseRouter;

    /// @notice socketGatewayAddress to be initialised via storage variable BridgeImplBase
    /// @dev ensure liquidityPoolManager-address are set properly for the chainId in which the contract is being deployed
    constructor(
        address _synapseRouter,
        address _socketGateway,
        address _socketDeployFactory
    ) BridgeImplBase(_socketGateway, _socketDeployFactory) {
        synapseRouter = ISynapseRouter(_synapseRouter);
    }

    /// @notice Struct to be used in decode step from input parameter - a specific case of bridging after swap.
    /// @dev the data being encoded in offchain or by caller should have values set in this sequence of properties in this struct
    struct SynapseData {
        /// @notice address of token being bridged
        address token;
        /// @notice address of receiver
        address receiverAddress;
        /// @notice chainId of destination
        uint256 toChainId;
        /// @notice socket offchain created hash
        bytes32 metadata;
        /// @notice Struct representing a origin request for SynapseRouter
        ISynapseRouter.SwapQuery originQuery;
        /// @notice Struct representing a destination request for SynapseRouter
        ISynapseRouter.SwapQuery destinationQuery;
    }

    struct SynapseDataNoToken {
        /// @notice address of receiver
        address receiverAddress;
        /// @notice chainId of destination
        uint256 toChainId;
        /// @notice chainId of destination
        bytes32 metadata;
        /// @notice Struct representing a origin request for SynapseRouter
        ISynapseRouter.SwapQuery originQuery;
        /// @notice Struct representing a destination request for SynapseRouter
        ISynapseRouter.SwapQuery destinationQuery;
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from swapAndBridge, this function is called when the swap has already happened at a different place.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in SynapseData struct
     * @param amount amount of tokens being bridged. this can be ERC20 or native
     * @param bridgeData encoded data for SynapseBridge
     */
    function bridgeAfterSwap(
        uint256 amount,
        bytes calldata bridgeData
    ) external payable override {
        SynapseData memory synapseData = abi.decode(bridgeData, (SynapseData));

        if (synapseData.token == NATIVE_TOKEN_ADDRESS) {
            synapseRouter.bridge{value: amount}(
                synapseData.receiverAddress,
                synapseData.toChainId,
                NATIVE_TOKEN_ADDRESS,
                amount,
                synapseData.originQuery,
                synapseData.destinationQuery
            );
        } else {
            if (
                amount >
                ERC20(synapseData.token).allowance(
                    address(this),
                    address(synapseRouter)
                )
            ) {
                ERC20(synapseData.token).safeApprove(
                    address(synapseRouter),
                    UINT256_MAX
                );
            }
            synapseRouter.bridge(
                synapseData.receiverAddress,
                synapseData.toChainId,
                synapseData.token,
                amount,
                synapseData.originQuery,
                synapseData.destinationQuery
            );
        }

        emit SocketBridge(
            amount,
            synapseData.token,
            synapseData.toChainId,
            SynapseIdentifier,
            msg.sender,
            synapseData.receiverAddress,
            synapseData.metadata
        );
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from bridgeAfterSwap since this function holds the logic for swapping tokens too.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in SynapseBridgeData struct
     * @param swapId routeId for the swapImpl
     * @param swapData encoded data for swap
     * @param synapseData encoded data for SynapseData
     */
    function swapAndBridge(
        uint32 swapId,
        bytes calldata swapData,
        SynapseDataNoToken calldata synapseData
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
        if (token == NATIVE_TOKEN_ADDRESS) {
            synapseRouter.bridge{value: bridgeAmount}(
                synapseData.receiverAddress,
                synapseData.toChainId,
                token,
                bridgeAmount,
                synapseData.originQuery,
                synapseData.destinationQuery
            );
        } else {
            if (
                bridgeAmount >
                ERC20(token).allowance(address(this), address(synapseRouter))
            ) {
                ERC20(token).safeApprove(address(synapseRouter), UINT256_MAX);
            }
            synapseRouter.bridge(
                synapseData.receiverAddress,
                synapseData.toChainId,
                token,
                bridgeAmount,
                synapseData.originQuery,
                synapseData.destinationQuery
            );
        }

        emit SocketBridge(
            bridgeAmount,
            token,
            synapseData.toChainId,
            SynapseIdentifier,
            msg.sender,
            synapseData.receiverAddress,
            synapseData.metadata
        );
    }

    /**
     * @notice function to handle ERC20 bridging to receipent via Synapse-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param amount amount to be sent
     * @param receiverAddress address of the token to bridged to the destination chain.
     * @param token address of token being bridged
     * @param toChainId chainId of destination
     */
    function bridgeERC20To(
        uint256 amount,
        bytes32 metadata,
        address receiverAddress,
        address token,
        uint256 toChainId,
        ISynapseRouter.SwapQuery calldata originQuery,
        ISynapseRouter.SwapQuery calldata destinationQuery
    ) external payable {
        ERC20(token).safeTransferFrom(msg.sender, socketGateway, amount);
        if (
            amount >
            ERC20(token).allowance(address(this), address(synapseRouter))
        ) {
            ERC20(token).safeApprove(address(synapseRouter), UINT256_MAX);
        }
        synapseRouter.bridge(
            receiverAddress,
            toChainId,
            token,
            amount,
            originQuery,
            destinationQuery
        );

        emit SocketBridge(
            amount,
            token,
            toChainId,
            SynapseIdentifier,
            msg.sender,
            receiverAddress,
            metadata
        );
    }

    /**
     * @notice function to handle Native bridging to receipent via Synapse-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param amount amount to be sent
     * @param receiverAddress address of the token to bridged to the destination chain.
     * @param toChainId chainId of destination
     */
    function bridgeNativeTo(
        uint256 amount,
        bytes32 metadata,
        address receiverAddress,
        uint256 toChainId,
        ISynapseRouter.SwapQuery calldata originQuery,
        ISynapseRouter.SwapQuery calldata destinationQuery
    ) external payable {
        synapseRouter.bridge{value: amount}(
            receiverAddress,
            toChainId,
            NATIVE_TOKEN_ADDRESS,
            amount,
            originQuery,
            destinationQuery
        );

        emit SocketBridge(
            amount,
            NATIVE_TOKEN_ADDRESS,
            toChainId,
            SynapseIdentifier,
            msg.sender,
            receiverAddress,
            metadata
        );
    }
}