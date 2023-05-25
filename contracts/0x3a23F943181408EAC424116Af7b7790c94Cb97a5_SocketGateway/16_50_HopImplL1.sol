// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../interfaces/IHopL1Bridge.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {BridgeImplBase} from "../../BridgeImplBase.sol";
import {HOP} from "../../../static/RouteIdentifiers.sol";

/**
 * @title Hop-L1 Route Implementation
 * @notice Route implementation with functions to bridge ERC20 and Native via Hop-Bridge from L1 to Supported L2s
 * Called via SocketGateway if the routeId in the request maps to the routeId of HopImplementation
 * Contains function to handle bridging as post-step i.e linked to a preceeding step for swap
 * RequestData is different to just bride and bridging chained with swap
 * @author Socket dot tech.
 */
contract HopImplL1 is BridgeImplBase {
    /// @notice SafeTransferLib - library for safe and optimised operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    bytes32 public immutable HopIdentifier = HOP;

    /// @notice Function-selector for ERC20-token bridging on Hop-L1-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge ERC20 tokens
    bytes4 public immutable HOP_L1_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "bridgeERC20To(address,address,address,address,uint256,uint256,uint256,uint256,(uint256,bytes32))"
            )
        );

    /// @notice Function-selector for Native bridging on Hop-L1-Route
    /// @dev This function selector is to be used while building transaction-data to bridge Native tokens
    bytes4 public immutable HOP_L1_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "bridgeNativeTo(address,address,address,uint256,uint256,uint256,uint256,uint256,bytes32)"
            )
        );

    bytes4 public immutable HOP_L1_SWAP_BRIDGE_SELECTOR =
        bytes4(
            keccak256(
                "swapAndBridge(uint32,bytes,(address,address,address,uint256,uint256,uint256,uint256,bytes32))"
            )
        );

    /// @notice socketGatewayAddress to be initialised via storage variable BridgeImplBase
    constructor(
        address _socketGateway,
        address _socketDeployFactory
    ) BridgeImplBase(_socketGateway, _socketDeployFactory) {}

    /// @notice Struct to be used in decode step from input parameter - a specific case of bridging after swap.
    /// @dev the data being encoded in offchain or by caller should have values set in this sequence of properties in this struct
    struct HopDataNoToken {
        // The address receiving funds at the destination
        address receiverAddress;
        // address of the Hop-L1-Bridge to handle bridging the tokens
        address l1bridgeAddr;
        // relayerFee The amount distributed to the relayer at the destination. This is subtracted from the `_amount`.
        address relayer;
        // The chainId of the destination chain
        uint256 toChainId;
        // The minimum amount received after attempting to swap in the destination AMM market. 0 if no swap is intended.
        uint256 amountOutMin;
        // The amount distributed to the relayer at the destination. This is subtracted from the `amount`.
        uint256 relayerFee;
        // The deadline for swapping in the destination AMM market. 0 if no swap is intended.
        uint256 deadline;
        // socket offchain created hash
        bytes32 metadata;
    }

    struct HopData {
        /// @notice address of token being bridged
        address token;
        // The address receiving funds at the destination
        address receiverAddress;
        // address of the Hop-L1-Bridge to handle bridging the tokens
        address l1bridgeAddr;
        // relayerFee The amount distributed to the relayer at the destination. This is subtracted from the `_amount`.
        address relayer;
        // The chainId of the destination chain
        uint256 toChainId;
        // The minimum amount received after attempting to swap in the destination AMM market. 0 if no swap is intended.
        uint256 amountOutMin;
        // The amount distributed to the relayer at the destination. This is subtracted from the `amount`.
        uint256 relayerFee;
        // The deadline for swapping in the destination AMM market. 0 if no swap is intended.
        uint256 deadline;
        // socket offchain created hash
        bytes32 metadata;
    }

    struct HopERC20Data {
        uint256 deadline;
        bytes32 metadata;
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from swapAndBridge, this function is called when the swap has already happened at a different place.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in HopBridgeData struct
     * @param amount amount of tokens being bridged. this can be ERC20 or native
     * @param bridgeData encoded data for Hop-L1-Bridge
     */
    function bridgeAfterSwap(
        uint256 amount,
        bytes calldata bridgeData
    ) external payable override {
        HopData memory hopData = abi.decode(bridgeData, (HopData));

        if (hopData.token == NATIVE_TOKEN_ADDRESS) {
            IHopL1Bridge(hopData.l1bridgeAddr).sendToL2{value: amount}(
                hopData.toChainId,
                hopData.receiverAddress,
                amount,
                hopData.amountOutMin,
                hopData.deadline,
                hopData.relayer,
                hopData.relayerFee
            );
        } else {
            ERC20(hopData.token).safeApprove(hopData.l1bridgeAddr, amount);

            // perform bridging
            IHopL1Bridge(hopData.l1bridgeAddr).sendToL2(
                hopData.toChainId,
                hopData.receiverAddress,
                amount,
                hopData.amountOutMin,
                hopData.deadline,
                hopData.relayer,
                hopData.relayerFee
            );
        }

        emit SocketBridge(
            amount,
            hopData.token,
            hopData.toChainId,
            HopIdentifier,
            msg.sender,
            hopData.receiverAddress,
            hopData.metadata
        );
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from bridgeAfterSwap since this function holds the logic for swapping tokens too.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in HopBridgeData struct
     * @param swapId routeId for the swapImpl
     * @param swapData encoded data for swap
     * @param hopData encoded data for HopData
     */
    function swapAndBridge(
        uint32 swapId,
        bytes calldata swapData,
        HopDataNoToken calldata hopData
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
            IHopL1Bridge(hopData.l1bridgeAddr).sendToL2{value: bridgeAmount}(
                hopData.toChainId,
                hopData.receiverAddress,
                bridgeAmount,
                hopData.amountOutMin,
                hopData.deadline,
                hopData.relayer,
                hopData.relayerFee
            );
        } else {
            ERC20(token).safeApprove(hopData.l1bridgeAddr, bridgeAmount);

            // perform bridging
            IHopL1Bridge(hopData.l1bridgeAddr).sendToL2(
                hopData.toChainId,
                hopData.receiverAddress,
                bridgeAmount,
                hopData.amountOutMin,
                hopData.deadline,
                hopData.relayer,
                hopData.relayerFee
            );
        }

        emit SocketBridge(
            bridgeAmount,
            token,
            hopData.toChainId,
            HopIdentifier,
            msg.sender,
            hopData.receiverAddress,
            hopData.metadata
        );
    }

    /**
     * @notice function to handle ERC20 bridging to receipent via Hop-L1-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param receiverAddress The address receiving funds at the destination
     * @param token token being bridged
     * @param l1bridgeAddr address of the Hop-L1-Bridge to handle bridging the tokens
     * @param relayer The amount distributed to the relayer at the destination. This is subtracted from the `_amount`.
     * @param toChainId The chainId of the destination chain
     * @param amount The amount being sent
     * @param amountOutMin The minimum amount received after attempting to swap in the destination AMM market. 0 if no swap is intended.
     * @param relayerFee The amount distributed to the relayer at the destination. This is subtracted from the `amount`.
     * @param hopData extra data needed to build the tx
     */
    function bridgeERC20To(
        address receiverAddress,
        address token,
        address l1bridgeAddr,
        address relayer,
        uint256 toChainId,
        uint256 amount,
        uint256 amountOutMin,
        uint256 relayerFee,
        HopERC20Data calldata hopData
    ) external payable {
        ERC20 tokenInstance = ERC20(token);
        tokenInstance.safeTransferFrom(msg.sender, socketGateway, amount);
        tokenInstance.safeApprove(l1bridgeAddr, amount);

        // perform bridging
        IHopL1Bridge(l1bridgeAddr).sendToL2(
            toChainId,
            receiverAddress,
            amount,
            amountOutMin,
            hopData.deadline,
            relayer,
            relayerFee
        );

        emit SocketBridge(
            amount,
            token,
            toChainId,
            HopIdentifier,
            msg.sender,
            receiverAddress,
            hopData.metadata
        );
    }

    /**
     * @notice function to handle Native bridging to receipent via Hop-L1-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param receiverAddress The address receiving funds at the destination
     * @param l1bridgeAddr address of the Hop-L1-Bridge to handle bridging the tokens
     * @param relayer The amount distributed to the relayer at the destination. This is subtracted from the `_amount`.
     * @param toChainId The chainId of the destination chain
     * @param amount The amount being sent
     * @param amountOutMin The minimum amount received after attempting to swap in the destination AMM market. 0 if no swap is intended.
     * @param relayerFee The amount distributed to the relayer at the destination. This is subtracted from the `amount`.
     * @param deadline The deadline for swapping in the destination AMM market. 0 if no swap is intended.
     */
    function bridgeNativeTo(
        address receiverAddress,
        address l1bridgeAddr,
        address relayer,
        uint256 toChainId,
        uint256 amount,
        uint256 amountOutMin,
        uint256 relayerFee,
        uint256 deadline,
        bytes32 metadata
    ) external payable {
        IHopL1Bridge(l1bridgeAddr).sendToL2{value: amount}(
            toChainId,
            receiverAddress,
            amount,
            amountOutMin,
            deadline,
            relayer,
            relayerFee
        );

        emit SocketBridge(
            amount,
            NATIVE_TOKEN_ADDRESS,
            toChainId,
            HopIdentifier,
            msg.sender,
            receiverAddress,
            metadata
        );
    }
}