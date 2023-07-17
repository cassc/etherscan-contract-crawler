// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {BridgeImplBase} from "../BridgeImplBase.sol";
import {CONNEXT} from "../../static/RouteIdentifiers.sol";

interface IConnextHandler {
    function xcall(
        uint32 destination,
        address recipient,
        address tokenAddress,
        address delegate,
        uint256 amount,
        uint256 slippage,
        bytes memory callData
    ) external payable returns (bytes32);

    function xcall(
        uint32 _destination,
        address _to,
        address _asset,
        address _delegate,
        uint256 _amount,
        uint256 _slippage,
        bytes calldata _callData,
        uint256 _relayerFee
    ) external returns (bytes32);
}

interface WETH {
    function deposit() external payable;
}

contract ConnextImpl is BridgeImplBase {
    /// @notice SafeTransferLib - library for safe and optimised operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    bytes32 public immutable connextIndetifier = CONNEXT;

    address public immutable wethAddress;
    /// @notice max value for uint256
    uint256 public constant UINT256_MAX = type(uint256).max;

    /// @notice Function-selector for ERC20-token bridging on Connext-Route
    /// @dev This function selector is to be used while buidling transaction-data to bridge ERC20 tokens

    bytes4 public immutable CONNEXT_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "bridgeERC20To(uint256,uint256,uint256,uint256,uint32,address,address,bytes32,bytes)"
            )
        );

    bytes4 public immutable CONNECT_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "bridgeNativeTo(uint256,uint256,uint256,uint256,uint32,address,bytes32,bytes)"
            )
        );

    bytes4 public immutable CONNEXT_SWAP_BRIDGE_SELECTOR =
        bytes4(
            keccak256(
                "swapAndBridge(uint32,bytes,(uint256,uint256,uint256,uint32,address,bytes32,bytes))"
            )
        );

    /// @notice Connext Contract instance used to deposit ERC20 on to Connext-Bridge
    /// @dev contract instance is to be initialized in the constructor using the router-address passed as constructor argument
    IConnextHandler public immutable router;

    constructor(
        address _router,
        address _wethAddress,
        address _socketGateway,
        address _socketDeployFactory
    ) BridgeImplBase(_socketGateway, _socketDeployFactory) {
        router = IConnextHandler(_router);
        wethAddress = _wethAddress;
    }

    /// @notice Struct to be used in decode step from input parameter - a specific case of bridging after swap.
    /// @dev the data being encoded in offchain or by caller should have values set in this sequence of properties in this struct
    struct ConnextBridgeNoTokenData {
        uint256 toChainId;
        uint256 slippage;
        uint256 relayerFee;
        uint32 dstChainDomain;
        address receiverAddress;
        bytes32 metadata;
        bytes callData;
    }

    /// @notice Struct to be used in decode step from input parameter - a specific case of bridging after swap.
    /// @dev the data being encoded in offchain or by caller should have values set in this sequence of properties in this struct
    struct ConnextBridgeData {
        uint256 toChainId;
        uint256 slippage;
        uint256 relayerFee;
        uint32 dstChainDomain;
        address token;
        address receiverAddress;
        bytes32 metadata;
        bytes callData;
    }

    /**
     * @notice function to bridge tokens after swap. This is used after swap function call
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
        ConnextBridgeData memory connextBridgeData = abi.decode(
            bridgeData,
            (ConnextBridgeData)
        );

        if (connextBridgeData.token == NATIVE_TOKEN_ADDRESS) {
            WETH(wethAddress).deposit{value: amount}();
        }

        if (
            amount >
            ERC20(connextBridgeData.token).allowance(
                address(this),
                address(router)
            )
        ) {
            ERC20(connextBridgeData.token).safeApprove(
                address(router),
                UINT256_MAX
            );
        }
        router.xcall(
            connextBridgeData.dstChainDomain,
            connextBridgeData.receiverAddress,
            connextBridgeData.token,
            msg.sender,
            amount - connextBridgeData.relayerFee,
            connextBridgeData.slippage,
            connextBridgeData.callData,
            connextBridgeData.relayerFee
        );

        emit SocketBridge(
            amount,
            connextBridgeData.token,
            connextBridgeData.toChainId,
            connextIndetifier,
            msg.sender,
            connextBridgeData.receiverAddress,
            connextBridgeData.metadata
        );
    }

    function swapAndBridge(
        uint32 swapId,
        bytes calldata swapData,
        ConnextBridgeNoTokenData calldata connextBridgeData
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
            WETH(wethAddress).deposit{value: bridgeAmount}();
        }
        if (
            bridgeAmount >
            ERC20(token).allowance(address(this), address(router))
        ) {
            ERC20(token).safeApprove(address(router), UINT256_MAX);
        }
        router.xcall(
            connextBridgeData.dstChainDomain,
            connextBridgeData.receiverAddress,
            token,
            msg.sender,
            bridgeAmount - connextBridgeData.relayerFee,
            connextBridgeData.slippage,
            connextBridgeData.callData,
            connextBridgeData.relayerFee
        );

        emit SocketBridge(
            bridgeAmount,
            token,
            connextBridgeData.toChainId,
            connextIndetifier,
            msg.sender,
            connextBridgeData.receiverAddress,
            connextBridgeData.metadata
        );
    }

    function bridgeERC20To(
        uint256 amount,
        uint256 toChainId,
        uint256 slippage,
        uint256 relayerFee,
        uint32 dstChainDomain,
        address receiverAddress,
        address token,
        bytes32 metadata,
        bytes memory callData
    ) external payable {
        ERC20(token).safeTransferFrom(msg.sender, socketGateway, amount);
        if (amount > ERC20(token).allowance(address(this), address(router))) {
            ERC20(token).safeApprove(address(router), UINT256_MAX);
        }
        router.xcall(
            dstChainDomain,
            receiverAddress,
            token,
            msg.sender,
            amount - relayerFee,
            slippage,
            callData,
            relayerFee
        );

        emit SocketBridge(
            amount,
            token,
            toChainId,
            connextIndetifier,
            msg.sender,
            receiverAddress,
            metadata
        );
    }

    function bridgeNativeTo(
        uint256 amount,
        uint256 toChainId,
        uint256 slippage,
        uint256 relayerFee,
        uint32 dstChainDomain,
        address receiverAddress,
        bytes32 metadata,
        bytes memory callData
    ) external payable {
        WETH(wethAddress).deposit{value: amount}();
        if (
            amount >
            ERC20(wethAddress).allowance(address(this), address(router))
        ) {
            ERC20(wethAddress).safeApprove(address(router), UINT256_MAX);
        }

        router.xcall(
            dstChainDomain,
            receiverAddress,
            wethAddress,
            msg.sender,
            amount - relayerFee,
            slippage,
            callData,
            relayerFee
        );

        emit SocketBridge(
            amount,
            NATIVE_TOKEN_ADDRESS,
            toChainId,
            connextIndetifier,
            msg.sender,
            receiverAddress,
            metadata
        );
    }
}