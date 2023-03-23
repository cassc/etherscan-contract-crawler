// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/across.sol";
import "../BridgeImplBase.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {ACROSS} from "../../static/RouteIdentifiers.sol";

/**
 * @title Across-Route Implementation
 * @notice Route implementation with functions to bridge ERC20 and Native via Across-Bridge
 * Called via SocketGateway if the routeId in the request maps to the routeId of AcrossImplementation
 * Contains function to handle bridging as post-step i.e linked to a preceeding step for swap
 * RequestData is different to just bride and bridging chained with swap
 * @author Socket dot tech.
 */
contract AcrossImpl is BridgeImplBase {
    /// @notice SafeTransferLib - library for safe and optimised operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    bytes32 public immutable AcrossIdentifier = ACROSS;

    /// @notice Function-selector for ERC20-token bridging on Across-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge ERC20 tokens
    bytes4 public immutable ACROSS_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "bridgeERC20To(uint256,uint256,bytes32,address,address,uint32,uint64)"
            )
        );

    /// @notice Function-selector for Native bridging on Across-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge Native tokens
    bytes4 public immutable ACROSS_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "bridgeNativeTo(uint256,uint256,bytes32,address,uint32,uint64)"
            )
        );

    bytes4 public immutable ACROSS_SWAP_BRIDGE_SELECTOR =
        bytes4(
            keccak256(
                "swapAndBridge(uint32,bytes,(uint256,address,uint32,uint64,bytes32))"
            )
        );

    /// @notice spokePool Contract instance used to deposit ERC20 and Native on to Across-Bridge
    /// @dev contract instance is to be initialized in the constructor using the spokePoolAddress passed as constructor argument
    SpokePool public immutable spokePool;
    address public immutable spokePoolAddress;

    /// @notice address of WETH token to be initialised in constructor
    address public immutable WETH;

    /// @notice Struct to be used in decode step from input parameter - a specific case of bridging after swap.
    /// @dev the data being encoded in offchain or by caller should have values set in this sequence of properties in this struct
    struct AcrossBridgeDataNoToken {
        uint256 toChainId;
        address receiverAddress;
        uint32 quoteTimestamp;
        uint64 relayerFeePct;
        bytes32 metadata;
    }

    struct AcrossBridgeData {
        uint256 toChainId;
        address receiverAddress;
        address token;
        uint32 quoteTimestamp;
        uint64 relayerFeePct;
        bytes32 metadata;
    }

    /// @notice socketGatewayAddress to be initialised via storage variable BridgeImplBase
    /// @dev ensure spokepool, weth-address are set properly for the chainId in which the contract is being deployed
    constructor(
        address _spokePool,
        address _wethAddress,
        address _socketGateway,
        address _socketDeployFactory
    ) BridgeImplBase(_socketGateway, _socketDeployFactory) {
        spokePool = SpokePool(_spokePool);
        spokePoolAddress = _spokePool;
        WETH = _wethAddress;
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from swapAndBridge, this function is called when the swap has already happened at a different place.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in AcrossBridgeData struct
     * @param amount amount of tokens being bridged. this can be ERC20 or native
     * @param bridgeData encoded data for AcrossBridge
     */
    function bridgeAfterSwap(
        uint256 amount,
        bytes calldata bridgeData
    ) external payable override {
        AcrossBridgeData memory acrossBridgeData = abi.decode(
            bridgeData,
            (AcrossBridgeData)
        );

        if (acrossBridgeData.token == NATIVE_TOKEN_ADDRESS) {
            spokePool.deposit{value: amount}(
                acrossBridgeData.receiverAddress,
                WETH,
                amount,
                acrossBridgeData.toChainId,
                acrossBridgeData.relayerFeePct,
                acrossBridgeData.quoteTimestamp
            );
        } else {
            spokePool.deposit(
                acrossBridgeData.receiverAddress,
                acrossBridgeData.token,
                amount,
                acrossBridgeData.toChainId,
                acrossBridgeData.relayerFeePct,
                acrossBridgeData.quoteTimestamp
            );
        }

        emit SocketBridge(
            amount,
            acrossBridgeData.token,
            acrossBridgeData.toChainId,
            AcrossIdentifier,
            msg.sender,
            acrossBridgeData.receiverAddress,
            acrossBridgeData.metadata
        );
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from bridgeAfterSwap since this function holds the logic for swapping tokens too.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in AcrossBridgeData struct
     * @param swapId routeId for the swapImpl
     * @param swapData encoded data for swap
     * @param acrossBridgeData encoded data for AcrossBridge
     */
    function swapAndBridge(
        uint32 swapId,
        bytes calldata swapData,
        AcrossBridgeDataNoToken calldata acrossBridgeData
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
            spokePool.deposit{value: bridgeAmount}(
                acrossBridgeData.receiverAddress,
                WETH,
                bridgeAmount,
                acrossBridgeData.toChainId,
                acrossBridgeData.relayerFeePct,
                acrossBridgeData.quoteTimestamp
            );
        } else {
            spokePool.deposit(
                acrossBridgeData.receiverAddress,
                token,
                bridgeAmount,
                acrossBridgeData.toChainId,
                acrossBridgeData.relayerFeePct,
                acrossBridgeData.quoteTimestamp
            );
        }

        emit SocketBridge(
            bridgeAmount,
            token,
            acrossBridgeData.toChainId,
            AcrossIdentifier,
            msg.sender,
            acrossBridgeData.receiverAddress,
            acrossBridgeData.metadata
        );
    }

    /**
     * @notice function to handle ERC20 bridging to receipent via Across-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param amount amount being bridged
     * @param toChainId destination ChainId
     * @param receiverAddress address of receiver of bridged tokens
     * @param token address of token being bridged
     * @param quoteTimestamp timestamp for quote and this is to be used by Across-Bridge contract
     * @param relayerFeePct feePct that will be relayed by the Bridge to the relayer
     */
    function bridgeERC20To(
        uint256 amount,
        uint256 toChainId,
        bytes32 metadata,
        address receiverAddress,
        address token,
        uint32 quoteTimestamp,
        uint64 relayerFeePct
    ) external payable {
        ERC20 tokenInstance = ERC20(token);
        tokenInstance.safeTransferFrom(msg.sender, socketGateway, amount);
        spokePool.deposit(
            receiverAddress,
            address(token),
            amount,
            toChainId,
            relayerFeePct,
            quoteTimestamp
        );

        emit SocketBridge(
            amount,
            token,
            toChainId,
            AcrossIdentifier,
            msg.sender,
            receiverAddress,
            metadata
        );
    }

    /**
     * @notice function to handle Native bridging to receipent via Across-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param amount amount being bridged
     * @param toChainId destination ChainId
     * @param receiverAddress address of receiver of bridged tokens
     * @param quoteTimestamp timestamp for quote and this is to be used by Across-Bridge contract
     * @param relayerFeePct feePct that will be relayed by the Bridge to the relayer
     */
    function bridgeNativeTo(
        uint256 amount,
        uint256 toChainId,
        bytes32 metadata,
        address receiverAddress,
        uint32 quoteTimestamp,
        uint64 relayerFeePct
    ) external payable {
        spokePool.deposit{value: amount}(
            receiverAddress,
            WETH,
            amount,
            toChainId,
            relayerFeePct,
            quoteTimestamp
        );

        emit SocketBridge(
            amount,
            NATIVE_TOKEN_ADDRESS,
            toChainId,
            AcrossIdentifier,
            msg.sender,
            receiverAddress,
            metadata
        );
    }
}