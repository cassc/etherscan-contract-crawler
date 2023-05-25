// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/hyphen.sol";
import "../BridgeImplBase.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {HYPHEN} from "../../static/RouteIdentifiers.sol";

/**
 * @title Hyphen-Route Implementation
 * @notice Route implementation with functions to bridge ERC20 and Native via Hyphen-Bridge
 * Called via SocketGateway if the routeId in the request maps to the routeId of HyphenImplementation
 * Contains function to handle bridging as post-step i.e linked to a preceeding step for swap
 * RequestData is different to just bride and bridging chained with swap
 * @author Socket dot tech.
 */
contract HyphenImpl is BridgeImplBase {
    /// @notice SafeTransferLib - library for safe and optimised operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    bytes32 public immutable HyphenIdentifier = HYPHEN;

    /// @notice Function-selector for ERC20-token bridging on Hyphen-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge ERC20 tokens
    bytes4 public immutable HYPHEN_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256("bridgeERC20To(uint256,bytes32,address,address,uint256)")
        );

    /// @notice Function-selector for Native bridging on Hyphen-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge Native tokens
    bytes4 public immutable HYPHEN_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(keccak256("bridgeNativeTo(uint256,bytes32,address,uint256)"));

    bytes4 public immutable HYPHEN_SWAP_BRIDGE_SELECTOR =
        bytes4(
            keccak256("swapAndBridge(uint32,bytes,(address,uint256,bytes32))")
        );

    /// @notice liquidityPoolManager - liquidityPool Manager of Hyphen used to bridge ERC20 and native
    /// @dev this is to be initialized in constructor with a valid deployed address of hyphen-liquidityPoolManager
    HyphenLiquidityPoolManager public immutable liquidityPoolManager;

    /// @notice socketGatewayAddress to be initialised via storage variable BridgeImplBase
    /// @dev ensure liquidityPoolManager-address are set properly for the chainId in which the contract is being deployed
    constructor(
        address _liquidityPoolManager,
        address _socketGateway,
        address _socketDeployFactory
    ) BridgeImplBase(_socketGateway, _socketDeployFactory) {
        liquidityPoolManager = HyphenLiquidityPoolManager(
            _liquidityPoolManager
        );
    }

    /// @notice Struct to be used in decode step from input parameter - a specific case of bridging after swap.
    /// @dev the data being encoded in offchain or by caller should have values set in this sequence of properties in this struct
    struct HyphenData {
        /// @notice address of token being bridged
        address token;
        /// @notice address of receiver
        address receiverAddress;
        /// @notice chainId of destination
        uint256 toChainId;
        /// @notice socket offchain created hash
        bytes32 metadata;
    }

    struct HyphenDataNoToken {
        /// @notice address of receiver
        address receiverAddress;
        /// @notice chainId of destination
        uint256 toChainId;
        /// @notice chainId of destination
        bytes32 metadata;
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from swapAndBridge, this function is called when the swap has already happened at a different place.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in HyphenBridgeData struct
     * @param amount amount of tokens being bridged. this can be ERC20 or native
     * @param bridgeData encoded data for HyphenBridge
     */
    function bridgeAfterSwap(
        uint256 amount,
        bytes calldata bridgeData
    ) external payable override {
        HyphenData memory hyphenData = abi.decode(bridgeData, (HyphenData));

        if (hyphenData.token == NATIVE_TOKEN_ADDRESS) {
            liquidityPoolManager.depositNative{value: amount}(
                hyphenData.receiverAddress,
                hyphenData.toChainId,
                "SOCKET"
            );
        } else {
            ERC20(hyphenData.token).safeApprove(
                address(liquidityPoolManager),
                amount
            );
            liquidityPoolManager.depositErc20(
                hyphenData.toChainId,
                hyphenData.token,
                hyphenData.receiverAddress,
                amount,
                "SOCKET"
            );
        }

        emit SocketBridge(
            amount,
            hyphenData.token,
            hyphenData.toChainId,
            HyphenIdentifier,
            msg.sender,
            hyphenData.receiverAddress,
            hyphenData.metadata
        );
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from bridgeAfterSwap since this function holds the logic for swapping tokens too.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in HyphenBridgeData struct
     * @param swapId routeId for the swapImpl
     * @param swapData encoded data for swap
     * @param hyphenData encoded data for hyphenData
     */
    function swapAndBridge(
        uint32 swapId,
        bytes calldata swapData,
        HyphenDataNoToken calldata hyphenData
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
            liquidityPoolManager.depositNative{value: bridgeAmount}(
                hyphenData.receiverAddress,
                hyphenData.toChainId,
                "SOCKET"
            );
        } else {
            ERC20(token).safeApprove(
                address(liquidityPoolManager),
                bridgeAmount
            );
            liquidityPoolManager.depositErc20(
                hyphenData.toChainId,
                token,
                hyphenData.receiverAddress,
                bridgeAmount,
                "SOCKET"
            );
        }

        emit SocketBridge(
            bridgeAmount,
            token,
            hyphenData.toChainId,
            HyphenIdentifier,
            msg.sender,
            hyphenData.receiverAddress,
            hyphenData.metadata
        );
    }

    /**
     * @notice function to handle ERC20 bridging to receipent via Hyphen-Bridge
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
        uint256 toChainId
    ) external payable {
        ERC20 tokenInstance = ERC20(token);
        tokenInstance.safeTransferFrom(msg.sender, socketGateway, amount);
        tokenInstance.safeApprove(address(liquidityPoolManager), amount);
        liquidityPoolManager.depositErc20(
            toChainId,
            token,
            receiverAddress,
            amount,
            "SOCKET"
        );

        emit SocketBridge(
            amount,
            token,
            toChainId,
            HyphenIdentifier,
            msg.sender,
            receiverAddress,
            metadata
        );
    }

    /**
     * @notice function to handle Native bridging to receipent via Hyphen-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param amount amount to be sent
     * @param receiverAddress address of the token to bridged to the destination chain.
     * @param toChainId chainId of destination
     */
    function bridgeNativeTo(
        uint256 amount,
        bytes32 metadata,
        address receiverAddress,
        uint256 toChainId
    ) external payable {
        liquidityPoolManager.depositNative{value: amount}(
            receiverAddress,
            toChainId,
            "SOCKET"
        );

        emit SocketBridge(
            amount,
            NATIVE_TOKEN_ADDRESS,
            toChainId,
            HyphenIdentifier,
            msg.sender,
            receiverAddress,
            metadata
        );
    }
}