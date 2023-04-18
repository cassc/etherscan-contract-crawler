// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/amm.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {BridgeImplBase} from "../../BridgeImplBase.sol";
import {HOP} from "../../../static/RouteIdentifiers.sol";

/**
 * @title Hop-L2 Route Implementation
 * @notice This is the L2 implementation, so this is used when transferring from l2 to supported l2s
 * Called via SocketGateway if the routeId in the request maps to the routeId of HopL2-Implementation
 * Contains function to handle bridging as post-step i.e linked to a preceeding step for swap
 * RequestData is different to just bride and bridging chained with swap
 * @author Socket dot tech.
 */
contract HopImplL2V2 is BridgeImplBase {
    /// @notice SafeTransferLib - library for safe and optimised operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    bytes32 public immutable HopIdentifier = HOP;

    /// @notice Function-selector for ERC20-token bridging on Hop-L2-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge ERC20 tokens
    bytes4 public immutable HOP_L2_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "bridgeERC20To(address,address,address,uint256,uint256,(uint256,uint256,uint256,uint256,uint256,bytes32))"
            )
        );

    /// @notice Function-selector for Native bridging on Hop-L2-Route
    /// @dev This function selector is to be used while building transaction-data to bridge Native tokens
    bytes4 public immutable HOP_L2_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "bridgeNativeTo(address,address,uint256,uint256,uint256,uint256,uint256,uint256,uint256,bytes32)"
            )
        );

    bytes4 public immutable HOP_L2_SWAP_BRIDGE_SELECTOR =
        bytes4(
            keccak256(
                "swapAndBridge(uint32,bytes,(address,address,uint256,uint256,uint256,uint256,uint256,uint256,bytes32))"
            )
        );

    /// @notice socketGatewayAddress to be initialised via storage variable BridgeImplBase
    constructor(
        address _socketGateway,
        address _socketDeployFactory
    ) BridgeImplBase(_socketGateway, _socketDeployFactory) {}

    /// @notice Struct to be used as a input parameter for Bridging tokens via Hop-L2-route
    /// @dev while building transactionData,values should be set in this sequence of properties in this struct
    struct HopBridgeRequestData {
        // fees passed to relayer
        uint256 bonderFee;
        // The minimum amount received after attempting to swap in the destination AMM market. 0 if no swap is intended.
        uint256 amountOutMin;
        // The deadline for swapping in the destination AMM market. 0 if no swap is intended.
        uint256 deadline;
        // Minimum amount expected to be received or bridged to destination
        uint256 amountOutMinDestination;
        // deadline for bridging to destination
        uint256 deadlineDestination;
        // socket offchain created hash
        bytes32 metadata;
    }

    /// @notice Struct to be used in decode step from input parameter - a specific case of bridging after swap.
    /// @dev the data being encoded in offchain or by caller should have values set in this sequence of properties in this struct
    struct HopBridgeDataNoToken {
        // The address receiving funds at the destination
        address receiverAddress;
        // AMM address of Hop on L2
        address hopAMM;
        // The chainId of the destination chain
        uint256 toChainId;
        // fees passed to relayer
        uint256 bonderFee;
        // The minimum amount received after attempting to swap in the destination AMM market. 0 if no swap is intended.
        uint256 amountOutMin;
        // The deadline for swapping in the destination AMM market. 0 if no swap is intended.
        uint256 deadline;
        // Minimum amount expected to be received or bridged to destination
        uint256 amountOutMinDestination;
        // deadline for bridging to destination
        uint256 deadlineDestination;
        // socket offchain created hash
        bytes32 metadata;
    }

    struct HopBridgeData {
        /// @notice address of token being bridged
        address token;
        // The address receiving funds at the destination
        address receiverAddress;
        // AMM address of Hop on L2
        address hopAMM;
        // The chainId of the destination chain
        uint256 toChainId;
        // fees passed to relayer
        uint256 bonderFee;
        // The minimum amount received after attempting to swap in the destination AMM market. 0 if no swap is intended.
        uint256 amountOutMin;
        // The deadline for swapping in the destination AMM market. 0 if no swap is intended.
        uint256 deadline;
        // Minimum amount expected to be received or bridged to destination
        uint256 amountOutMinDestination;
        // deadline for bridging to destination
        uint256 deadlineDestination;
        // socket offchain created hash
        bytes32 metadata;
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from swapAndBridge, this function is called when the swap has already happened at a different place.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in HopBridgeData struct
     * @param amount amount of tokens being bridged. this can be ERC20 or native
     * @param bridgeData encoded data for Hop-L2-Bridge
     */
    function bridgeAfterSwap(
        uint256 amount,
        bytes calldata bridgeData
    ) external payable override {
        HopBridgeData memory hopData = abi.decode(bridgeData, (HopBridgeData));

        if (hopData.token == NATIVE_TOKEN_ADDRESS) {
            HopAMM(hopData.hopAMM).swapAndSend{value: amount}(
                hopData.toChainId,
                hopData.receiverAddress,
                amount,
                hopData.bonderFee,
                hopData.amountOutMin,
                hopData.deadline,
                hopData.amountOutMinDestination,
                hopData.deadlineDestination
            );
        } else {
            // perform bridging
            HopAMM(hopData.hopAMM).swapAndSend(
                hopData.toChainId,
                hopData.receiverAddress,
                amount,
                hopData.bonderFee,
                hopData.amountOutMin,
                hopData.deadline,
                hopData.amountOutMinDestination,
                hopData.deadlineDestination
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
        HopBridgeDataNoToken calldata hopData
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
            HopAMM(hopData.hopAMM).swapAndSend{value: bridgeAmount}(
                hopData.toChainId,
                hopData.receiverAddress,
                bridgeAmount,
                hopData.bonderFee,
                hopData.amountOutMin,
                hopData.deadline,
                hopData.amountOutMinDestination,
                hopData.deadlineDestination
            );
        } else {
            // perform bridging
            HopAMM(hopData.hopAMM).swapAndSend(
                hopData.toChainId,
                hopData.receiverAddress,
                bridgeAmount,
                hopData.bonderFee,
                hopData.amountOutMin,
                hopData.deadline,
                hopData.amountOutMinDestination,
                hopData.deadlineDestination
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
     * @notice function to handle ERC20 bridging to receipent via Hop-L2-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param receiverAddress The address receiving funds at the destination
     * @param token token being bridged
     * @param hopAMM AMM address of Hop on L2
     * @param amount The amount being bridged
     * @param toChainId The chainId of the destination chain
     * @param hopBridgeRequestData extraData for Bridging across Hop-L2
     */
    function bridgeERC20To(
        address receiverAddress,
        address token,
        address hopAMM,
        uint256 amount,
        uint256 toChainId,
        HopBridgeRequestData calldata hopBridgeRequestData
    ) external payable {
        ERC20 tokenInstance = ERC20(token);
        tokenInstance.safeTransferFrom(msg.sender, socketGateway, amount);

        HopAMM(hopAMM).swapAndSend(
            toChainId,
            receiverAddress,
            amount,
            hopBridgeRequestData.bonderFee,
            hopBridgeRequestData.amountOutMin,
            hopBridgeRequestData.deadline,
            hopBridgeRequestData.amountOutMinDestination,
            hopBridgeRequestData.deadlineDestination
        );

        emit SocketBridge(
            amount,
            token,
            toChainId,
            HopIdentifier,
            msg.sender,
            receiverAddress,
            hopBridgeRequestData.metadata
        );
    }

    /**
     * @notice function to handle Native bridging to receipent via Hop-L2-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param receiverAddress The address receiving funds at the destination
     * @param hopAMM AMM address of Hop on L2
     * @param amount The amount being bridged
     * @param toChainId The chainId of the destination chain
     * @param bonderFee fees passed to relayer
     * @param amountOutMin The minimum amount received after attempting to swap in the destination AMM market. 0 if no swap is intended.
     * @param deadline The deadline for swapping in the destination AMM market. 0 if no swap is intended.
     * @param amountOutMinDestination Minimum amount expected to be received or bridged to destination
     * @param deadlineDestination deadline for bridging to destination
     */
    function bridgeNativeTo(
        address receiverAddress,
        address hopAMM,
        uint256 amount,
        uint256 toChainId,
        uint256 bonderFee,
        uint256 amountOutMin,
        uint256 deadline,
        uint256 amountOutMinDestination,
        uint256 deadlineDestination,
        bytes32 metadata
    ) external payable {
        // token address might not be indication thats why passed through extraData
        // perform bridging
        HopAMM(hopAMM).swapAndSend{value: amount}(
            toChainId,
            receiverAddress,
            amount,
            bonderFee,
            amountOutMin,
            deadline,
            amountOutMinDestination,
            deadlineDestination
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

    function bridgeERC20ToOptimised() external payable {
        ERC20(address(bytes20(msg.data[4:24]))).safeTransferFrom(
            msg.sender,
            socketGateway,
            uint256(uint128(bytes16(msg.data[64:80])))
        );
        uint256 deadline = block.timestamp + 60 * 20;
        HopAMM(address(bytes20(msg.data[24:44]))).swapAndSend(
            uint256(uint32(bytes4(msg.data[128:132]))),
            address(bytes20(msg.data[44:64])),
            uint256(uint128(bytes16(msg.data[64:80]))),
            uint256(uint128(bytes16(msg.data[80:96]))),
            uint256(uint128(bytes16(msg.data[96:112]))),
            deadline,
            uint256(uint128(bytes16(msg.data[112:128]))),
            deadline
        );

        emit SocketBridge(
            uint256(uint128(bytes16(msg.data[64:80]))),
            address(bytes20(msg.data[4:24])),
            uint256(uint32(bytes4(msg.data[128:132]))),
            HopIdentifier,
            msg.sender,
            address(bytes20(msg.data[44:64])),
            hex"01"
        );
    }

    function bridgeNativeToOptimised() external payable {
        uint256 deadline = block.timestamp + 60 * 20;
        HopAMM(address(bytes20(msg.data[4:24]))).swapAndSend{value: msg.value}( // hop amm
            uint256(uint32(bytes4(msg.data[24:28]))),
            address(bytes20(msg.data[28:48])),
            msg.value,
            uint256(uint128(bytes16(msg.data[48:64]))),
            uint256(uint128(bytes16(msg.data[64:80]))),
            deadline,
            uint256(uint128(bytes16(msg.data[80:96]))),
            deadline
        );

        emit SocketBridge(
            msg.value,
            NATIVE_TOKEN_ADDRESS,
            uint256(uint32(bytes4(msg.data[24:28]))),
            HopIdentifier,
            msg.sender,
            address(bytes20(msg.data[28:48])),
            hex"01"
        );
    }
}