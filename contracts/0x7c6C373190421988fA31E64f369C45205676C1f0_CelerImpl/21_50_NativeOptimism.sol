// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import "../interfaces/optimism.sol";
import {BridgeImplBase} from "../../BridgeImplBase.sol";
import {UnsupportedInterfaceId} from "../../../errors/SocketErrors.sol";
import {NATIVE_OPTIMISM} from "../../../static/RouteIdentifiers.sol";

/**
 * @title NativeOptimism-Route Implementation
 * @notice Route implementation with functions to bridge ERC20 and Native via NativeOptimism-Bridge
 * Tokens are bridged from Ethereum to Optimism Chain.
 * Called via SocketGateway if the routeId in the request maps to the routeId of NativeOptimism-Implementation
 * Contains function to handle bridging as post-step i.e linked to a preceeding step for swap
 * RequestData is different to just bride and bridging chained with swap
 * @author Socket dot tech.
 */
contract NativeOptimismImpl is BridgeImplBase {
    using SafeTransferLib for ERC20;

    bytes32 public immutable NativeOptimismIdentifier = NATIVE_OPTIMISM;

    uint256 public constant DESTINATION_CHAIN_ID = 10;

    /// @notice Function-selector for ERC20-token bridging on Native-Optimism-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge ERC20 tokens
    bytes4
        public immutable NATIVE_OPTIMISM_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "bridgeERC20To(address,address,address,uint32,(bytes32,bytes32),uint256,uint256,address,bytes)"
            )
        );

    /// @notice Function-selector for Native bridging on Native-Optimism-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge Native balance
    bytes4
        public immutable NATIVE_OPTIMISM_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "bridgeNativeTo(address,address,uint32,uint256,bytes32,bytes)"
            )
        );

    bytes4 public immutable NATIVE_OPTIMISM_SWAP_BRIDGE_SELECTOR =
        bytes4(
            keccak256(
                "swapAndBridge(uint32,bytes,(uint256,bytes32,bytes32,address,address,uint32,address,bytes))"
            )
        );

    /// @notice socketGatewayAddress to be initialised via storage variable BridgeImplBase
    constructor(
        address _socketGateway,
        address _socketDeployFactory
    ) BridgeImplBase(_socketGateway, _socketDeployFactory) {}

    /// @notice Struct to be used in decode step from input parameter - a specific case of bridging after swap.
    /// @dev the data being encoded in offchain or by caller should have values set in this sequence of properties in this struct
    struct OptimismBridgeDataNoToken {
        // interfaceId to be set offchain which is used to select one of the 3 kinds of bridging (standard bridge / old standard / synthetic)
        uint256 interfaceId;
        // currencyKey of the token beingBridged
        bytes32 currencyKey;
        // socket offchain created hash
        bytes32 metadata;
        // address of receiver of bridged tokens
        address receiverAddress;
        /**
         * OptimismBridge that Performs the logic for deposits by informing the L2 Deposited Token
         * contract of the deposit and calling a handler to lock the L1 funds. (e.g. transferFrom)
         */
        address customBridgeAddress;
        // Gas limit required to complete the deposit on L2.
        uint32 l2Gas;
        // Address of the L1 respective L2 ERC20
        address l2Token;
        // additional data , for ll contracts this will be 0x data or empty data
        bytes data;
    }

    struct OptimismBridgeData {
        // interfaceId to be set offchain which is used to select one of the 3 kinds of bridging (standard bridge / old standard / synthetic)
        uint256 interfaceId;
        // currencyKey of the token beingBridged
        bytes32 currencyKey;
        // socket offchain created hash
        bytes32 metadata;
        // address of receiver of bridged tokens
        address receiverAddress;
        /**
         * OptimismBridge that Performs the logic for deposits by informing the L2 Deposited Token
         * contract of the deposit and calling a handler to lock the L1 funds. (e.g. transferFrom)
         */
        address customBridgeAddress;
        /// @notice address of token being bridged
        address token;
        // Gas limit required to complete the deposit on L2.
        uint32 l2Gas;
        // Address of the L1 respective L2 ERC20
        address l2Token;
        // additional data , for ll contracts this will be 0x data or empty data
        bytes data;
    }

    struct OptimismERC20Data {
        bytes32 currencyKey;
        bytes32 metadata;
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from swapAndBridge, this function is called when the swap has already happened at a different place.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in OptimismBridgeData struct
     * @param amount amount of tokens being bridged. this can be ERC20 or native
     * @param bridgeData encoded data for Optimism-Bridge
     */
    function bridgeAfterSwap(
        uint256 amount,
        bytes calldata bridgeData
    ) external payable override {
        OptimismBridgeData memory optimismBridgeData = abi.decode(
            bridgeData,
            (OptimismBridgeData)
        );

        emit SocketBridge(
            amount,
            optimismBridgeData.token,
            DESTINATION_CHAIN_ID,
            NativeOptimismIdentifier,
            msg.sender,
            optimismBridgeData.receiverAddress,
            optimismBridgeData.metadata
        );
        if (optimismBridgeData.token == NATIVE_TOKEN_ADDRESS) {
            L1StandardBridge(optimismBridgeData.customBridgeAddress)
                .depositETHTo{value: amount}(
                optimismBridgeData.receiverAddress,
                optimismBridgeData.l2Gas,
                optimismBridgeData.data
            );
        } else {
            if (optimismBridgeData.interfaceId == 0) {
                revert UnsupportedInterfaceId();
            }

            ERC20(optimismBridgeData.token).safeApprove(
                optimismBridgeData.customBridgeAddress,
                amount
            );

            if (optimismBridgeData.interfaceId == 1) {
                // deposit into standard bridge
                L1StandardBridge(optimismBridgeData.customBridgeAddress)
                    .depositERC20To(
                        optimismBridgeData.token,
                        optimismBridgeData.l2Token,
                        optimismBridgeData.receiverAddress,
                        amount,
                        optimismBridgeData.l2Gas,
                        optimismBridgeData.data
                    );
                return;
            }

            // Deposit Using Old Standard - iOVM_L1TokenGateway(Example - SNX Token)
            if (optimismBridgeData.interfaceId == 2) {
                OldL1TokenGateway(optimismBridgeData.customBridgeAddress)
                    .depositTo(optimismBridgeData.receiverAddress, amount);
                return;
            }

            if (optimismBridgeData.interfaceId == 3) {
                OldL1TokenGateway(optimismBridgeData.customBridgeAddress)
                    .initiateSynthTransfer(
                        optimismBridgeData.currencyKey,
                        optimismBridgeData.receiverAddress,
                        amount
                    );
                return;
            }
        }
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from bridgeAfterSwap since this function holds the logic for swapping tokens too.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in OptimismBridgeData struct
     * @param swapId routeId for the swapImpl
     * @param swapData encoded data for swap
     * @param optimismBridgeData encoded data for OptimismBridgeData
     */
    function swapAndBridge(
        uint32 swapId,
        bytes calldata swapData,
        OptimismBridgeDataNoToken calldata optimismBridgeData
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

        emit SocketBridge(
            bridgeAmount,
            token,
            DESTINATION_CHAIN_ID,
            NativeOptimismIdentifier,
            msg.sender,
            optimismBridgeData.receiverAddress,
            optimismBridgeData.metadata
        );
        if (token == NATIVE_TOKEN_ADDRESS) {
            L1StandardBridge(optimismBridgeData.customBridgeAddress)
                .depositETHTo{value: bridgeAmount}(
                optimismBridgeData.receiverAddress,
                optimismBridgeData.l2Gas,
                optimismBridgeData.data
            );
        } else {
            if (optimismBridgeData.interfaceId == 0) {
                revert UnsupportedInterfaceId();
            }

            ERC20(token).safeApprove(
                optimismBridgeData.customBridgeAddress,
                bridgeAmount
            );

            if (optimismBridgeData.interfaceId == 1) {
                // deposit into standard bridge
                L1StandardBridge(optimismBridgeData.customBridgeAddress)
                    .depositERC20To(
                        token,
                        optimismBridgeData.l2Token,
                        optimismBridgeData.receiverAddress,
                        bridgeAmount,
                        optimismBridgeData.l2Gas,
                        optimismBridgeData.data
                    );
                return;
            }

            // Deposit Using Old Standard - iOVM_L1TokenGateway(Example - SNX Token)
            if (optimismBridgeData.interfaceId == 2) {
                OldL1TokenGateway(optimismBridgeData.customBridgeAddress)
                    .depositTo(
                        optimismBridgeData.receiverAddress,
                        bridgeAmount
                    );
                return;
            }

            if (optimismBridgeData.interfaceId == 3) {
                OldL1TokenGateway(optimismBridgeData.customBridgeAddress)
                    .initiateSynthTransfer(
                        optimismBridgeData.currencyKey,
                        optimismBridgeData.receiverAddress,
                        bridgeAmount
                    );
                return;
            }
        }
    }

    /**
     * @notice function to handle ERC20 bridging to receipent via NativeOptimism-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param token address of token being bridged
     * @param receiverAddress address of receiver of bridged tokens
     * @param customBridgeAddress OptimismBridge that Performs the logic for deposits by informing the L2 Deposited Token
     *                           contract of the deposit and calling a handler to lock the L1 funds. (e.g. transferFrom)
     * @param l2Gas Gas limit required to complete the deposit on L2.
     * @param optimismData extra data needed for optimism bridge
     * @param amount amount being bridged
     * @param interfaceId interfaceId to be set offchain which is used to select one of the 3 kinds of bridging (standard bridge / old standard / synthetic)
     * @param l2Token Address of the L1 respective L2 ERC20
     * @param data additional data , for ll contracts this will be 0x data or empty data
     */
    function bridgeERC20To(
        address token,
        address receiverAddress,
        address customBridgeAddress,
        uint32 l2Gas,
        OptimismERC20Data calldata optimismData,
        uint256 amount,
        uint256 interfaceId,
        address l2Token,
        bytes calldata data
    ) external payable {
        if (interfaceId == 0) {
            revert UnsupportedInterfaceId();
        }

        ERC20 tokenInstance = ERC20(token);
        tokenInstance.safeTransferFrom(msg.sender, socketGateway, amount);
        tokenInstance.safeApprove(customBridgeAddress, amount);

        emit SocketBridge(
            amount,
            token,
            DESTINATION_CHAIN_ID,
            NativeOptimismIdentifier,
            msg.sender,
            receiverAddress,
            optimismData.metadata
        );
        if (interfaceId == 1) {
            // deposit into standard bridge
            L1StandardBridge(customBridgeAddress).depositERC20To(
                token,
                l2Token,
                receiverAddress,
                amount,
                l2Gas,
                data
            );
            return;
        }

        // Deposit Using Old Standard - iOVM_L1TokenGateway(Example - SNX Token)
        if (interfaceId == 2) {
            OldL1TokenGateway(customBridgeAddress).depositTo(
                receiverAddress,
                amount
            );
            return;
        }

        if (interfaceId == 3) {
            OldL1TokenGateway(customBridgeAddress).initiateSynthTransfer(
                optimismData.currencyKey,
                receiverAddress,
                amount
            );
            return;
        }
    }

    /**
     * @notice function to handle native balance bridging to receipent via NativeOptimism-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param receiverAddress address of receiver of bridged tokens
     * @param customBridgeAddress OptimismBridge that Performs the logic for deposits by informing the L2 Deposited Token
     *                           contract of the deposit and calling a handler to lock the L1 funds. (e.g. transferFrom)
     * @param l2Gas Gas limit required to complete the deposit on L2.
     * @param amount amount being bridged
     * @param data additional data , for ll contracts this will be 0x data or empty data
     */
    function bridgeNativeTo(
        address receiverAddress,
        address customBridgeAddress,
        uint32 l2Gas,
        uint256 amount,
        bytes32 metadata,
        bytes calldata data
    ) external payable {
        L1StandardBridge(customBridgeAddress).depositETHTo{value: amount}(
            receiverAddress,
            l2Gas,
            data
        );

        emit SocketBridge(
            amount,
            NATIVE_TOKEN_ADDRESS,
            DESTINATION_CHAIN_ID,
            NativeOptimismIdentifier,
            msg.sender,
            receiverAddress,
            metadata
        );
    }
}