// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import "../interfaces/stargate.sol";
import {BridgeImplBase} from "../../BridgeImplBase.sol";
import {STARGATE} from "../../../static/RouteIdentifiers.sol";

/**
 * @title Stargate-L1-Route Implementation
 * @notice Route implementation with functions to bridge ERC20 and Native via Stargate-L1-Bridge
 * Called via SocketGateway if the routeId in the request maps to the routeId of Stargate-L1-Implementation
 * Contains function to handle bridging as post-step i.e linked to a preceeding step for swap
 * RequestData is different to just bride and bridging chained with swap
 * @author Socket dot tech.
 */
contract StargateImplL1 is BridgeImplBase {
    /// @notice SafeTransferLib - library for safe and optimised operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    bytes32 public immutable StargateIdentifier = STARGATE;

    /// @notice Function-selector for ERC20-token bridging on Stargate-L1-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge ERC20 tokens
    bytes4
        public immutable STARGATE_L1_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "bridgeERC20To(address,address,address,uint256,uint256,(uint256,uint256,uint256,uint256,bytes32,bytes,uint16))"
            )
        );

    /// @notice Function-selector for Native bridging on Stargate-L1-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge Native tokens
    bytes4
        public immutable STARGATE_L1_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "bridgeNativeTo(address,address,uint16,uint256,uint256,uint256,bytes32)"
            )
        );

    bytes4 public immutable STARGATE_L1_SWAP_BRIDGE_SELECTOR =
        bytes4(
            keccak256(
                "swapAndBridge(uint32,bytes,(address,address,uint16,uint256,uint256,uint256,uint256,uint256,uint256,bytes32,bytes))"
            )
        );

    /// @notice Stargate Router to bridge ERC20 tokens
    IBridgeStargate public immutable router;

    /// @notice Stargate Router to bridge native tokens
    IBridgeStargate public immutable routerETH;

    /// @notice socketGatewayAddress to be initialised via storage variable BridgeImplBase
    /// @dev ensure router, routerEth are set properly for the chainId in which the contract is being deployed
    constructor(
        address _router,
        address _routerEth,
        address _socketGateway,
        address _socketDeployFactory
    ) BridgeImplBase(_socketGateway, _socketDeployFactory) {
        router = IBridgeStargate(_router);
        routerETH = IBridgeStargate(_routerEth);
    }

    struct StargateBridgeExtraData {
        uint256 srcPoolId;
        uint256 dstPoolId;
        uint256 destinationGasLimit;
        uint256 minReceivedAmt;
        bytes32 metadata;
        bytes destinationPayload;
        uint16 stargateDstChainId; // stargate defines chain id in its way
    }

    /// @notice Struct to be used in decode step from input parameter - a specific case of bridging after swap.
    /// @dev the data being encoded in offchain or by caller should have values set in this sequence of properties in this struct
    struct StargateBridgeDataNoToken {
        address receiverAddress;
        address senderAddress;
        uint16 stargateDstChainId; // stargate defines chain id in its way
        uint256 value;
        // a unique identifier that is uses to dedup transfers
        // this value is the a timestamp sent from frontend, but in theory can be any unique number
        uint256 srcPoolId;
        uint256 dstPoolId;
        uint256 minReceivedAmt; // defines the slippage, the min qty you would accept on the destination
        uint256 optionalValue;
        uint256 destinationGasLimit;
        bytes32 metadata;
        bytes destinationPayload;
    }

    struct StargateBridgeData {
        address token;
        address receiverAddress;
        address senderAddress;
        uint16 stargateDstChainId; // stargate defines chain id in its way
        uint256 value;
        // a unique identifier that is uses to dedup transfers
        // this value is the a timestamp sent from frontend, but in theory can be any unique number
        uint256 srcPoolId;
        uint256 dstPoolId;
        uint256 minReceivedAmt; // defines the slippage, the min qty you would accept on the destination
        uint256 optionalValue;
        uint256 destinationGasLimit;
        bytes32 metadata;
        bytes destinationPayload;
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from swapAndBridge, this function is called when the swap has already happened at a different place.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in Stargate-BridgeData struct
     * @param amount amount of tokens being bridged. this can be ERC20 or native
     * @param bridgeData encoded data for Stargate-L1-Bridge
     */
    function bridgeAfterSwap(
        uint256 amount,
        bytes calldata bridgeData
    ) external payable override {
        StargateBridgeData memory stargateBridgeData = abi.decode(
            bridgeData,
            (StargateBridgeData)
        );

        if (stargateBridgeData.token == NATIVE_TOKEN_ADDRESS) {
            // perform bridging
            routerETH.swapETH{value: amount + stargateBridgeData.optionalValue}(
                stargateBridgeData.stargateDstChainId,
                payable(stargateBridgeData.senderAddress),
                abi.encodePacked(stargateBridgeData.receiverAddress),
                amount,
                stargateBridgeData.minReceivedAmt
            );
        } else {
            ERC20(stargateBridgeData.token).safeApprove(
                address(router),
                amount
            );
            {
                router.swap{value: stargateBridgeData.value}(
                    stargateBridgeData.stargateDstChainId,
                    stargateBridgeData.srcPoolId,
                    stargateBridgeData.dstPoolId,
                    payable(stargateBridgeData.senderAddress), // default to refund to main contract
                    amount,
                    stargateBridgeData.minReceivedAmt,
                    IBridgeStargate.lzTxObj(
                        stargateBridgeData.destinationGasLimit,
                        0, // zero amount since this is a ERC20 bridging
                        "0x" //empty data since this is for only ERC20
                    ),
                    abi.encodePacked(stargateBridgeData.receiverAddress),
                    stargateBridgeData.destinationPayload
                );
            }
        }

        emit SocketBridge(
            amount,
            stargateBridgeData.token,
            stargateBridgeData.stargateDstChainId,
            StargateIdentifier,
            msg.sender,
            stargateBridgeData.receiverAddress,
            stargateBridgeData.metadata
        );
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from bridgeAfterSwap since this function holds the logic for swapping tokens too.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in Stargate-BridgeData struct
     * @param swapId routeId for the swapImpl
     * @param swapData encoded data for swap
     * @param stargateBridgeData encoded data for StargateBridgeData
     */
    function swapAndBridge(
        uint32 swapId,
        bytes calldata swapData,
        StargateBridgeDataNoToken calldata stargateBridgeData
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
            // perform bridging
            routerETH.swapETH{
                value: bridgeAmount + stargateBridgeData.optionalValue
            }(
                stargateBridgeData.stargateDstChainId,
                payable(stargateBridgeData.senderAddress),
                abi.encodePacked(stargateBridgeData.receiverAddress),
                bridgeAmount,
                stargateBridgeData.minReceivedAmt
            );
        } else {
            ERC20(token).safeApprove(address(router), bridgeAmount);
            {
                router.swap{value: stargateBridgeData.value}(
                    stargateBridgeData.stargateDstChainId,
                    stargateBridgeData.srcPoolId,
                    stargateBridgeData.dstPoolId,
                    payable(stargateBridgeData.senderAddress), // default to refund to main contract
                    bridgeAmount,
                    stargateBridgeData.minReceivedAmt,
                    IBridgeStargate.lzTxObj(
                        stargateBridgeData.destinationGasLimit,
                        0, // zero amount since this is a ERC20 bridging
                        "0x" //empty data since this is for only ERC20
                    ),
                    abi.encodePacked(stargateBridgeData.receiverAddress),
                    stargateBridgeData.destinationPayload
                );
            }
        }

        emit SocketBridge(
            bridgeAmount,
            token,
            stargateBridgeData.stargateDstChainId,
            StargateIdentifier,
            msg.sender,
            stargateBridgeData.receiverAddress,
            stargateBridgeData.metadata
        );
    }

    /**
     * @notice function to handle ERC20 bridging to receipent via Stargate-L1-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param token address of token being bridged
     * @param senderAddress address of sender
     * @param receiverAddress address of recipient
     * @param amount amount of token being bridge
     * @param value value
     * @param stargateBridgeExtraData stargate bridge extradata
     */
    function bridgeERC20To(
        address token,
        address senderAddress,
        address receiverAddress,
        uint256 amount,
        uint256 value,
        StargateBridgeExtraData calldata stargateBridgeExtraData
    ) external payable {
        ERC20 tokenInstance = ERC20(token);
        tokenInstance.safeTransferFrom(msg.sender, socketGateway, amount);
        tokenInstance.safeApprove(address(router), amount);
        {
            router.swap{value: value}(
                stargateBridgeExtraData.stargateDstChainId,
                stargateBridgeExtraData.srcPoolId,
                stargateBridgeExtraData.dstPoolId,
                payable(senderAddress), // default to refund to main contract
                amount,
                stargateBridgeExtraData.minReceivedAmt,
                IBridgeStargate.lzTxObj(
                    stargateBridgeExtraData.destinationGasLimit,
                    0, // zero amount since this is a ERC20 bridging
                    "0x" //empty data since this is for only ERC20
                ),
                abi.encodePacked(receiverAddress),
                stargateBridgeExtraData.destinationPayload
            );
        }

        emit SocketBridge(
            amount,
            token,
            stargateBridgeExtraData.stargateDstChainId,
            StargateIdentifier,
            msg.sender,
            receiverAddress,
            stargateBridgeExtraData.metadata
        );
    }

    /**
     * @notice function to handle Native bridging to receipent via Stargate-L1-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param receiverAddress address of receipient
     * @param senderAddress address of sender
     * @param stargateDstChainId stargate defines chain id in its way
     * @param amount amount of token being bridge
     * @param minReceivedAmt defines the slippage, the min qty you would accept on the destination
     * @param optionalValue optionalValue Native amount
     */
    function bridgeNativeTo(
        address receiverAddress,
        address senderAddress,
        uint16 stargateDstChainId,
        uint256 amount,
        uint256 minReceivedAmt,
        uint256 optionalValue,
        bytes32 metadata
    ) external payable {
        // perform bridging
        routerETH.swapETH{value: amount + optionalValue}(
            stargateDstChainId,
            payable(senderAddress),
            abi.encodePacked(receiverAddress),
            amount,
            minReceivedAmt
        );

        emit SocketBridge(
            amount,
            NATIVE_TOKEN_ADDRESS,
            stargateDstChainId,
            StargateIdentifier,
            msg.sender,
            receiverAddress,
            metadata
        );
    }
}