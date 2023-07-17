// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/IZkSyncL1ERC20Bridge.sol";
import "./interfaces/IZkSyncL1Mailbox.sol";
import "../BridgeImplBase.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {ZKSYNC} from "../../static/RouteIdentifiers.sol";

/**
 * @title ZkSync-Route Implementation
 * @notice Route implementation with functions to bridge ERC20 and Native from Mainnet to ZkSync via ZkSync-Bridge
 * Called via SocketGateway if the routeId in the request maps to the routeId of ZkSyncImplementation
 * @author Socket dot tech.
 */
contract ZkSyncBridgeImpl is BridgeImplBase {
    /// @notice SafeTransferLib - library for safe and optimised operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    bytes32 public immutable ZkSyncIdentifier = ZKSYNC;

    /// @notice max value for uint256
    uint256 public constant UINT256_MAX = type(uint256).max;

    /// @notice Function-selector for ERC20-token bridging on ZkSync-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge ERC20 tokens
    bytes4 public immutable ZKSYNC_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "bridgeERC20To(uint256,uint256,bytes32,address,address,uint256,uint256,uint256)"
            )
        );

    /// @notice Function-selector for Native bridging on ZkSync-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge Native tokens
    bytes4 public immutable ZKSYNC_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "bridgeNativeTo(uint256,uint256,bytes32,address,uint256,uint256,uint256)"
            )
        );

    struct ZkSyncBridgeData {
        uint256 amount;
        uint256 fees;
        bytes32 metadata;
        address receiverAddress;
        address token;
        uint256 toChainId;
        uint256 l2TxGasLimit;
        uint256 l2TxGasPerPubdataByte;
    }

    /****************************************
     *               EVENTS                 *
     ****************************************/

    IZkSyncL1ERC20Bridge public immutable zkSyncL1ERC20Bridge;
    IZkSyncL1Mailbox public immutable zkSyncL1Mailbox;

    /// @notice socketGatewayAddress to be initialised via storage variable BridgeImplBase
    /// @dev ensure zkSync-L1ERC20Bridge and mailboxFacetProxy addresses are set properly for the chain in which the contract is being deployed
    constructor(
        address _zkSyncL1ERC20Bridge,
        address _mailboxFacetProxy,
        address _socketGateway,
        address _socketDeployFactory
    ) BridgeImplBase(_socketGateway, _socketDeployFactory) {
        zkSyncL1ERC20Bridge = IZkSyncL1ERC20Bridge(_zkSyncL1ERC20Bridge);
        zkSyncL1Mailbox = IZkSyncL1Mailbox(_mailboxFacetProxy);
    }

    /**
     * @notice function to handle ERC20 bridging to receipent via ZkSync-L1ERC20Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param amount amount to be sent
     * @param fees fees for l2 execution
     * @param metadata metadata of bridging to be emitted in the event
     * @param receiverAddress address of the token to bridged to the destination chain.
     * @param token address of erc20 token being bridged
     * @param toChainId chainId of destination
     * @param l2TxGasLimit transaction gasLimit for execution on L2 (ZkSync)
     * @param l2TxGasPerPubdataByte TxGas PerByte for L2
     */
    function bridgeERC20To(
        uint256 amount,
        uint256 fees,
        bytes32 metadata,
        address receiverAddress,
        address token,
        uint256 toChainId,
        uint256 l2TxGasLimit,
        uint256 l2TxGasPerPubdataByte
    ) external payable {
        ERC20(token).safeTransferFrom(msg.sender, socketGateway, amount);
        if (
            amount >
            ERC20(token).allowance(address(this), address(zkSyncL1ERC20Bridge))
        ) {
            ERC20(token).safeApprove(address(zkSyncL1ERC20Bridge), UINT256_MAX);
        }

        zkSyncL1ERC20Bridge.deposit{value: fees}(
            receiverAddress,
            token,
            amount,
            l2TxGasLimit,
            l2TxGasPerPubdataByte,
            receiverAddress
        );

        emit SocketBridge(
            amount,
            token,
            toChainId,
            ZkSyncIdentifier,
            msg.sender,
            receiverAddress,
            metadata
        );
    }

    /**
     * @notice function to handle Native bridging to receipent via ZKSync-DiamondProxy
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param amount amount to be sent
     * @param fees fees for l2 execution
     * @param metadata metadata of bridging to be emitted in the event
     * @param receiverAddress address of the token to bridged to the destination chain.
     * @param toChainId chainId of destination
     * @param l2TxGasLimit transaction gasLimit for execution on L2 (ZkSync)
     * @param l2TxGasPerPubdataByte TxGas PerByte for L2
     */
    function bridgeNativeTo(
        uint256 amount,
        uint256 fees,
        bytes32 metadata,
        address receiverAddress,
        uint256 toChainId,
        uint256 l2TxGasLimit,
        uint256 l2TxGasPerPubdataByte
    ) external payable {
        bytes[] memory emptyDeps; // Default value for _factoryDeps

        zkSyncL1Mailbox.requestL2Transaction{value: amount + fees}(
            receiverAddress,
            amount,
            "0x",
            l2TxGasLimit,
            l2TxGasPerPubdataByte,
            emptyDeps,
            receiverAddress
        );

        emit SocketBridge(
            amount,
            NATIVE_TOKEN_ADDRESS,
            toChainId,
            ZkSyncIdentifier,
            msg.sender,
            receiverAddress,
            metadata
        );
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from swapAndBridge, this function is called when the swap has already happened at a different place.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in ZkSyncBridgeData struct
     * @param amount amount of tokens being bridged. this can be ERC20 or native
     * @param bridgeData encoded data for ZkSyncBridge
     */
    function bridgeAfterSwap(
        uint256 amount,
        bytes calldata bridgeData
    ) external payable override {
        ZkSyncBridgeData memory zkSyncBridgeData = abi.decode(
            bridgeData,
            (ZkSyncBridgeData)
        );
        bytes[] memory emptyDeps; // Default value for _factoryDeps

        if (zkSyncBridgeData.token == NATIVE_TOKEN_ADDRESS) {
            zkSyncL1Mailbox.requestL2Transaction{
                value: amount + zkSyncBridgeData.fees
            }(
                zkSyncBridgeData.receiverAddress,
                amount,
                "0x",
                zkSyncBridgeData.l2TxGasLimit,
                zkSyncBridgeData.l2TxGasPerPubdataByte,
                emptyDeps,
                zkSyncBridgeData.receiverAddress
            );
        } else {
            ERC20(zkSyncBridgeData.token).safeTransferFrom(
                msg.sender,
                socketGateway,
                amount
            );
            if (
                amount >
                ERC20(zkSyncBridgeData.token).allowance(
                    address(this),
                    address(zkSyncL1ERC20Bridge)
                )
            ) {
                ERC20(zkSyncBridgeData.token).safeApprove(
                    address(zkSyncL1ERC20Bridge),
                    UINT256_MAX
                );
            }

            zkSyncL1ERC20Bridge.deposit{value: zkSyncBridgeData.fees}(
                zkSyncBridgeData.receiverAddress,
                zkSyncBridgeData.token,
                amount,
                zkSyncBridgeData.l2TxGasLimit,
                zkSyncBridgeData.l2TxGasPerPubdataByte,
                zkSyncBridgeData.receiverAddress
            );
        }

        emit SocketBridge(
            amount,
            zkSyncBridgeData.token,
            zkSyncBridgeData.toChainId,
            ZkSyncIdentifier,
            msg.sender,
            zkSyncBridgeData.receiverAddress,
            zkSyncBridgeData.metadata
        );
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from bridgeAfterSwap since this function holds the logic for swapping tokens too.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in ZkSyncBridgeData struct
     * @param swapId routeId for the swapImpl
     * @param swapData encoded data for swap
     * @param zkSyncBridgeData encoded data for ZkSyncBridgeData
     */
    function swapAndBridge(
        uint32 swapId,
        bytes calldata swapData,
        ZkSyncBridgeData calldata zkSyncBridgeData
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

        bytes[] memory emptyDeps; // Default value for _factoryDeps

        if (zkSyncBridgeData.token == NATIVE_TOKEN_ADDRESS) {
            zkSyncL1Mailbox.requestL2Transaction{
                value: bridgeAmount + zkSyncBridgeData.fees
            }(
                zkSyncBridgeData.receiverAddress,
                bridgeAmount,
                "0x",
                zkSyncBridgeData.l2TxGasLimit,
                zkSyncBridgeData.l2TxGasPerPubdataByte,
                emptyDeps,
                zkSyncBridgeData.receiverAddress
            );
        } else {
            ERC20(zkSyncBridgeData.token).safeTransferFrom(
                msg.sender,
                socketGateway,
                bridgeAmount
            );
            if (
                bridgeAmount >
                ERC20(zkSyncBridgeData.token).allowance(
                    address(this),
                    address(zkSyncL1ERC20Bridge)
                )
            ) {
                ERC20(zkSyncBridgeData.token).safeApprove(
                    address(zkSyncL1ERC20Bridge),
                    UINT256_MAX
                );
            }

            zkSyncL1ERC20Bridge.deposit{value: zkSyncBridgeData.fees}(
                zkSyncBridgeData.receiverAddress,
                zkSyncBridgeData.token,
                bridgeAmount,
                zkSyncBridgeData.l2TxGasLimit,
                zkSyncBridgeData.l2TxGasPerPubdataByte,
                zkSyncBridgeData.receiverAddress
            );
        }

        emit SocketBridge(
            bridgeAmount,
            zkSyncBridgeData.token,
            zkSyncBridgeData.toChainId,
            ZkSyncIdentifier,
            msg.sender,
            zkSyncBridgeData.receiverAddress,
            zkSyncBridgeData.metadata
        );
    }
}