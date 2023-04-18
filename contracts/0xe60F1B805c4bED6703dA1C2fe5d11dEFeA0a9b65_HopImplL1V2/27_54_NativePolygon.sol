// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import "./interfaces/polygon.sol";
import {BridgeImplBase} from "../BridgeImplBase.sol";
import {NATIVE_POLYGON} from "../../static/RouteIdentifiers.sol";

/**
 * @title NativePolygon-Route Implementation
 * @notice This is the L1 implementation, so this is used when transferring from ethereum to polygon via their native bridge.
 * @author Socket dot tech.
 */
contract NativePolygonImpl is BridgeImplBase {
    /// @notice SafeTransferLib - library for safe and optimised operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    bytes32 public immutable NativePolyonIdentifier = NATIVE_POLYGON;

    /// @notice destination-chain-Id for this router is always arbitrum
    uint256 public constant DESTINATION_CHAIN_ID = 137;

    /// @notice max value for uint256
    uint256 public constant UINT256_MAX = type(uint256).max;

    /// @notice Function-selector for ERC20-token bridging on NativePolygon-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge ERC20 tokens
    bytes4
        public immutable NATIVE_POLYGON_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(keccak256("bridgeERC20To(uint256,bytes32,address,address)"));

    /// @notice Function-selector for Native bridging on NativePolygon-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge Native tokens
    bytes4
        public immutable NATIVE_POLYGON_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(keccak256("bridgeNativeTo(uint256,bytes32,address)"));

    bytes4 public immutable NATIVE_POLYGON_SWAP_BRIDGE_SELECTOR =
        bytes4(keccak256("swapAndBridge(uint32,address,bytes32,bytes)"));

    /// @notice root chain manager proxy on the ethereum chain
    /// @dev to be initialised in the constructor
    IRootChainManager public immutable rootChainManagerProxy;

    /// @notice ERC20 Predicate proxy on the ethereum chain
    /// @dev to be initialised in the constructor
    address public immutable erc20PredicateProxy;

    /**
     * // @notice We set all the required addresses in the constructor while deploying the contract.
     * // These will be constant addresses.
     * // @dev Please use the Proxy addresses and not the implementation addresses while setting these
     * // @param _rootChainManagerProxy address of the root chain manager proxy on the ethereum chain
     * // @param _erc20PredicateProxy address of the ERC20 Predicate proxy on the ethereum chain.
     * // @param _socketGateway address of the socketGateway contract that calls this contract
     */
    constructor(
        address _rootChainManagerProxy,
        address _erc20PredicateProxy,
        address _socketGateway,
        address _socketDeployFactory
    ) BridgeImplBase(_socketGateway, _socketDeployFactory) {
        rootChainManagerProxy = IRootChainManager(_rootChainManagerProxy);
        erc20PredicateProxy = _erc20PredicateProxy;
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from swapAndBridge, this function is called when the swap has already happened at a different place.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in NativePolygon-BridgeData struct
     * @param amount amount of tokens being bridged. this can be ERC20 or native
     * @param bridgeData encoded data for NativePolygon-Bridge
     */
    function bridgeAfterSwap(
        uint256 amount,
        bytes calldata bridgeData
    ) external payable override {
        (address token, address receiverAddress, bytes32 metadata) = abi.decode(
            bridgeData,
            (address, address, bytes32)
        );

        if (token == NATIVE_TOKEN_ADDRESS) {
            IRootChainManager(rootChainManagerProxy).depositEtherFor{
                value: amount
            }(receiverAddress);
        } else {
            if (
                amount >
                ERC20(token).allowance(address(this), erc20PredicateProxy)
            ) {
                ERC20(token).safeApprove(erc20PredicateProxy, UINT256_MAX);
            }

            // deposit into rootchain manager
            IRootChainManager(rootChainManagerProxy).depositFor(
                receiverAddress,
                token,
                abi.encodePacked(amount)
            );
        }

        emit SocketBridge(
            amount,
            token,
            DESTINATION_CHAIN_ID,
            NativePolyonIdentifier,
            msg.sender,
            receiverAddress,
            metadata
        );
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from bridgeAfterSwap since this function holds the logic for swapping tokens too.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in NativePolygon-BridgeData struct
     * @param swapId routeId for the swapImpl
     * @param receiverAddress address of the receiver
     * @param swapData encoded data for swap
     */
    function swapAndBridge(
        uint32 swapId,
        address receiverAddress,
        bytes32 metadata,
        bytes calldata swapData
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
            IRootChainManager(rootChainManagerProxy).depositEtherFor{
                value: bridgeAmount
            }(receiverAddress);
        } else {
            if (
                bridgeAmount >
                ERC20(token).allowance(address(this), erc20PredicateProxy)
            ) {
                ERC20(token).safeApprove(erc20PredicateProxy, UINT256_MAX);
            }

            // deposit into rootchain manager
            IRootChainManager(rootChainManagerProxy).depositFor(
                receiverAddress,
                token,
                abi.encodePacked(bridgeAmount)
            );
        }

        emit SocketBridge(
            bridgeAmount,
            token,
            DESTINATION_CHAIN_ID,
            NativePolyonIdentifier,
            msg.sender,
            receiverAddress,
            metadata
        );
    }

    /**
     * @notice function to handle ERC20 bridging to receipent via NativePolygon-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param amount amount of tokens being bridged
     * @param receiverAddress recipient address
     * @param token address of token being bridged
     */
    function bridgeERC20To(
        uint256 amount,
        bytes32 metadata,
        address receiverAddress,
        address token
    ) external payable {
        ERC20 tokenInstance = ERC20(token);

        // set allowance for erc20 predicate
        tokenInstance.safeTransferFrom(msg.sender, socketGateway, amount);
        if (
            amount > ERC20(token).allowance(address(this), erc20PredicateProxy)
        ) {
            ERC20(token).safeApprove(erc20PredicateProxy, UINT256_MAX);
        }

        // deposit into rootchain manager
        rootChainManagerProxy.depositFor(
            receiverAddress,
            token,
            abi.encodePacked(amount)
        );

        emit SocketBridge(
            amount,
            token,
            DESTINATION_CHAIN_ID,
            NativePolyonIdentifier,
            msg.sender,
            receiverAddress,
            metadata
        );
    }

    /**
     * @notice function to handle Native bridging to receipent via NativePolygon-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param amount amount of tokens being bridged
     * @param receiverAddress recipient address
     */
    function bridgeNativeTo(
        uint256 amount,
        bytes32 metadata,
        address receiverAddress
    ) external payable {
        rootChainManagerProxy.depositEtherFor{value: amount}(receiverAddress);

        emit SocketBridge(
            amount,
            NATIVE_TOKEN_ADDRESS,
            DESTINATION_CHAIN_ID,
            NativePolyonIdentifier,
            msg.sender,
            receiverAddress,
            metadata
        );
    }

    function setApprovalForRouters(
        address[] memory routeAddresses,
        address[] memory tokenAddresses,
        bool isMax
    ) external isSocketGatewayOwner {
        for (uint32 index = 0; index < routeAddresses.length; ) {
            ERC20(tokenAddresses[index]).safeApprove(
                routeAddresses[index],
                isMax ? type(uint256).max : 0
            );
            unchecked {
                ++index;
            }
        }
    }
}