// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {BridgeImplBase} from "../../BridgeImplBase.sol";
import {ANYSWAP} from "../../../static/RouteIdentifiers.sol";

/**
 * @title Anyswap-V4-Route L1 Implementation
 * @notice Route implementation with functions to bridge ERC20 via Anyswap-Bridge
 * Called via SocketGateway if the routeId in the request maps to the routeId of AnyswapImplementation
 * This is the L2 implementation, so this is used when transferring from l2.
 * Contains function to handle bridging as post-step i.e linked to a preceeding step for swap
 * RequestData is different to just bride and bridging chained with swap
 * @author Socket dot tech.
 */
interface AnyswapV4Router {
    function anySwapOutUnderlying(
        address token,
        address to,
        uint256 amount,
        uint256 toChainID
    ) external;
}

contract AnyswapL2Impl is BridgeImplBase {
    /// @notice SafeTransferLib - library for safe and optimised operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    bytes32 public immutable AnyswapIdentifier = ANYSWAP;

    /// @notice Function-selector for ERC20-token bridging on Anyswap-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge ERC20 tokens
    bytes4 public immutable ANYSWAP_L2_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "bridgeERC20To(uint256,uint256,bytes32,address,address,address)"
            )
        );

    bytes4 public immutable ANYSWAP_SWAP_BRIDGE_SELECTOR =
        bytes4(
            keccak256(
                "swapAndBridge(uint32,bytes,(uint256,address,address,bytes32))"
            )
        );

    // polygon router multichain router v4
    AnyswapV4Router public immutable router;

    /**
     * @notice Constructor sets the router address and socketGateway address.
     * @dev anyswap v4 router is immutable. so no setter function required.
     */
    constructor(
        address _router,
        address _socketGateway,
        address _socketDeployFactory
    ) BridgeImplBase(_socketGateway, _socketDeployFactory) {
        router = AnyswapV4Router(_router);
    }

    /// @notice Struct to be used in decode step from input parameter - a specific case of bridging after swap.
    /// @dev the data being encoded in offchain or by caller should have values set in this sequence of properties in this struct
    struct AnyswapBridgeDataNoToken {
        /// @notice destination ChainId
        uint256 toChainId;
        /// @notice address of receiver of bridged tokens
        address receiverAddress;
        /// @notice address of wrapperToken, WrappedVersion of the token being bridged
        address wrapperTokenAddress;
        /// @notice socket offchain created hash
        bytes32 metadata;
    }

    /// @notice Struct to be used in decode step from input parameter - a specific case of bridging after swap.
    /// @dev the data being encoded in offchain or by caller should have values set in this sequence of properties in this struct
    struct AnyswapBridgeData {
        /// @notice destination ChainId
        uint256 toChainId;
        /// @notice address of receiver of bridged tokens
        address receiverAddress;
        /// @notice address of wrapperToken, WrappedVersion of the token being bridged
        address wrapperTokenAddress;
        /// @notice address of token being bridged
        address token;
        /// @notice socket offchain created hash
        bytes32 metadata;
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from swapAndBridge, this function is called when the swap has already happened at a different place.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in AnyswapBridgeData struct
     * @param amount amount of tokens being bridged. this can be ERC20 or native
     * @param bridgeData encoded data for AnyswapBridge
     */
    function bridgeAfterSwap(
        uint256 amount,
        bytes calldata bridgeData
    ) external payable override {
        AnyswapBridgeData memory anyswapBridgeData = abi.decode(
            bridgeData,
            (AnyswapBridgeData)
        );
        ERC20(anyswapBridgeData.token).safeApprove(address(router), amount);
        router.anySwapOutUnderlying(
            anyswapBridgeData.wrapperTokenAddress,
            anyswapBridgeData.receiverAddress,
            amount,
            anyswapBridgeData.toChainId
        );

        emit SocketBridge(
            amount,
            anyswapBridgeData.token,
            anyswapBridgeData.toChainId,
            AnyswapIdentifier,
            msg.sender,
            anyswapBridgeData.receiverAddress,
            anyswapBridgeData.metadata
        );
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from bridgeAfterSwap since this function holds the logic for swapping tokens too.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in AnyswapBridgeData struct
     * @param swapId routeId for the swapImpl
     * @param swapData encoded data for swap
     * @param anyswapBridgeData encoded data for AnyswapBridge
     */
    function swapAndBridge(
        uint32 swapId,
        bytes calldata swapData,
        AnyswapBridgeDataNoToken calldata anyswapBridgeData
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

        ERC20(token).safeApprove(address(router), bridgeAmount);
        router.anySwapOutUnderlying(
            anyswapBridgeData.wrapperTokenAddress,
            anyswapBridgeData.receiverAddress,
            bridgeAmount,
            anyswapBridgeData.toChainId
        );

        emit SocketBridge(
            bridgeAmount,
            token,
            anyswapBridgeData.toChainId,
            AnyswapIdentifier,
            msg.sender,
            anyswapBridgeData.receiverAddress,
            anyswapBridgeData.metadata
        );
    }

    /**
     * @notice function to handle ERC20 bridging to receipent via Anyswap-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param amount amount being bridged
     * @param toChainId destination ChainId
     * @param receiverAddress address of receiver of bridged tokens
     * @param token address of token being bridged
     * @param wrapperTokenAddress address of wrapperToken, WrappedVersion of the token being bridged
     */
    function bridgeERC20To(
        uint256 amount,
        uint256 toChainId,
        bytes32 metadata,
        address receiverAddress,
        address token,
        address wrapperTokenAddress
    ) external payable {
        ERC20 tokenInstance = ERC20(token);
        tokenInstance.safeTransferFrom(msg.sender, socketGateway, amount);
        tokenInstance.safeApprove(address(router), amount);
        router.anySwapOutUnderlying(
            wrapperTokenAddress,
            receiverAddress,
            amount,
            toChainId
        );

        emit SocketBridge(
            amount,
            token,
            toChainId,
            AnyswapIdentifier,
            msg.sender,
            receiverAddress,
            metadata
        );
    }
}