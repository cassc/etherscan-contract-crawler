// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../libraries/Pb.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import "./interfaces/cbridge.sol";
import "./interfaces/ICelerStorageWrapper.sol";
import {TransferIdExists, InvalidCelerRefund, CelerAlreadyRefunded, CelerRefundNotReady} from "../../errors/SocketErrors.sol";
import {BridgeImplBase} from "../BridgeImplBase.sol";
import {CBRIDGE} from "../../static/RouteIdentifiers.sol";

/**
 * @title Celer-Route Implementation
 * @notice Route implementation with functions to bridge ERC20 and Native via Celer-Bridge
 * Called via SocketGateway if the routeId in the request maps to the routeId of CelerImplementation
 * Contains function to handle bridging as post-step i.e linked to a preceeding step for swap
 * RequestData is different to just bride and bridging chained with swap
 * @author Socket dot tech.
 */
contract CelerImpl is BridgeImplBase {
    /// @notice SafeTransferLib - library for safe and optimised operations on ERC20 tokens
    using SafeTransferLib for ERC20;

    bytes32 public immutable CBridgeIdentifier = CBRIDGE;

    /// @notice Utility to perform operation on Buffer
    using Pb for Pb.Buffer;

    /// @notice Function-selector for ERC20-token bridging on Celer-Route
    /// @dev This function selector is to be used while building transaction-data to bridge ERC20 tokens
    bytes4 public immutable CELER_ERC20_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "bridgeERC20To(address,address,uint256,bytes32,uint64,uint64,uint32)"
            )
        );

    /// @notice Function-selector for Native bridging on Celer-Route
    /// @dev This function selector is to be used while building transaction-data to bridge Native tokens
    bytes4 public immutable CELER_NATIVE_EXTERNAL_BRIDGE_FUNCTION_SELECTOR =
        bytes4(
            keccak256(
                "bridgeNativeTo(address,uint256,bytes32,uint64,uint64,uint32)"
            )
        );

    bytes4 public immutable CELER_SWAP_BRIDGE_SELECTOR =
        bytes4(
            keccak256(
                "swapAndBridge(uint32,bytes,(address,uint64,uint32,uint64,bytes32))"
            )
        );

    /// @notice router Contract instance used to deposit ERC20 and Native on to Celer-Bridge
    /// @dev contract instance is to be initialized in the constructor using the routerAddress passed as constructor argument
    ICBridge public immutable router;

    /// @notice celerStorageWrapper Contract instance used to store the transferId generated during ERC20 and Native bridge on to Celer-Bridge
    /// @dev contract instance is to be initialized in the constructor using the celerStorageWrapperAddress passed as constructor argument
    ICelerStorageWrapper public immutable celerStorageWrapper;

    /// @notice WETH token address
    address public immutable weth;

    /// @notice chainId used during generation of transferId generated while bridging ERC20 and Native on to Celer-Bridge
    /// @dev this is to be initialised in the constructor
    uint64 public immutable chainId;

    struct WithdrawMsg {
        uint64 chainid; // tag: 1
        uint64 seqnum; // tag: 2
        address receiver; // tag: 3
        address token; // tag: 4
        uint256 amount; // tag: 5
        bytes32 refid; // tag: 6
    }

    /// @notice socketGatewayAddress to be initialised via storage variable BridgeImplBase
    /// @dev ensure routerAddress, weth-address, celerStorageWrapperAddress are set properly for the chainId in which the contract is being deployed
    constructor(
        address _routerAddress,
        address _weth,
        address _celerStorageWrapperAddress,
        address _socketGateway,
        address _socketDeployFactory
    ) BridgeImplBase(_socketGateway, _socketDeployFactory) {
        router = ICBridge(_routerAddress);
        celerStorageWrapper = ICelerStorageWrapper(_celerStorageWrapperAddress);
        weth = _weth;
        chainId = uint64(block.chainid);
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    /// @notice Struct to be used in decode step from input parameter - a specific case of bridging after swap.
    /// @dev the data being encoded in offchain or by caller should have values set in this sequence of properties in this struct
    struct CelerBridgeDataNoToken {
        address receiverAddress;
        uint64 toChainId;
        uint32 maxSlippage;
        uint64 nonce;
        bytes32 metadata;
    }

    struct CelerBridgeData {
        address token;
        address receiverAddress;
        uint64 toChainId;
        uint32 maxSlippage;
        uint64 nonce;
        bytes32 metadata;
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from swapAndBridge, this function is called when the swap has already happened at a different place.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in CelerBridgeData struct
     * @param amount amount of tokens being bridged. this can be ERC20 or native
     * @param bridgeData encoded data for CelerBridge
     */
    function bridgeAfterSwap(
        uint256 amount,
        bytes calldata bridgeData
    ) external payable override {
        CelerBridgeData memory celerBridgeData = abi.decode(
            bridgeData,
            (CelerBridgeData)
        );

        if (celerBridgeData.token == NATIVE_TOKEN_ADDRESS) {
            // transferId is generated using the request-params and nonce of the account
            // transferId should be unique for each request and this is used while handling refund from celerBridge
            bytes32 transferId = keccak256(
                abi.encodePacked(
                    address(this),
                    celerBridgeData.receiverAddress,
                    weth,
                    amount,
                    celerBridgeData.toChainId,
                    celerBridgeData.nonce,
                    chainId
                )
            );

            // transferId is stored in CelerStorageWrapper with in a mapping where key is transferId and value is the msg-sender
            celerStorageWrapper.setAddressForTransferId(transferId, msg.sender);

            router.sendNative{value: amount}(
                celerBridgeData.receiverAddress,
                amount,
                celerBridgeData.toChainId,
                celerBridgeData.nonce,
                celerBridgeData.maxSlippage
            );
        } else {
            // transferId is generated using the request-params and nonce of the account
            // transferId should be unique for each request and this is used while handling refund from celerBridge
            bytes32 transferId = keccak256(
                abi.encodePacked(
                    address(this),
                    celerBridgeData.receiverAddress,
                    celerBridgeData.token,
                    amount,
                    celerBridgeData.toChainId,
                    celerBridgeData.nonce,
                    chainId
                )
            );

            // transferId is stored in CelerStorageWrapper with in a mapping where key is transferId and value is the msg-sender
            celerStorageWrapper.setAddressForTransferId(transferId, msg.sender);
            router.send(
                celerBridgeData.receiverAddress,
                celerBridgeData.token,
                amount,
                celerBridgeData.toChainId,
                celerBridgeData.nonce,
                celerBridgeData.maxSlippage
            );
        }

        emit SocketBridge(
            amount,
            celerBridgeData.token,
            celerBridgeData.toChainId,
            CBridgeIdentifier,
            msg.sender,
            celerBridgeData.receiverAddress,
            celerBridgeData.metadata
        );
    }

    /**
     * @notice function to bridge tokens after swap.
     * @notice this is different from bridgeAfterSwap since this function holds the logic for swapping tokens too.
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @dev for usage, refer to controller implementations
     *      encodedData for bridge should follow the sequence of properties in CelerBridgeData struct
     * @param swapId routeId for the swapImpl
     * @param swapData encoded data for swap
     * @param celerBridgeData encoded data for CelerBridgeData
     */
    function swapAndBridge(
        uint32 swapId,
        bytes calldata swapData,
        CelerBridgeDataNoToken calldata celerBridgeData
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
            // transferId is generated using the request-params and nonce of the account
            // transferId should be unique for each request and this is used while handling refund from celerBridge
            bytes32 transferId = keccak256(
                abi.encodePacked(
                    address(this),
                    celerBridgeData.receiverAddress,
                    weth,
                    bridgeAmount,
                    celerBridgeData.toChainId,
                    celerBridgeData.nonce,
                    chainId
                )
            );

            // transferId is stored in CelerStorageWrapper with in a mapping where key is transferId and value is the msg-sender
            celerStorageWrapper.setAddressForTransferId(transferId, msg.sender);

            router.sendNative{value: bridgeAmount}(
                celerBridgeData.receiverAddress,
                bridgeAmount,
                celerBridgeData.toChainId,
                celerBridgeData.nonce,
                celerBridgeData.maxSlippage
            );
        } else {
            // transferId is generated using the request-params and nonce of the account
            // transferId should be unique for each request and this is used while handling refund from celerBridge
            bytes32 transferId = keccak256(
                abi.encodePacked(
                    address(this),
                    celerBridgeData.receiverAddress,
                    token,
                    bridgeAmount,
                    celerBridgeData.toChainId,
                    celerBridgeData.nonce,
                    chainId
                )
            );

            // transferId is stored in CelerStorageWrapper with in a mapping where key is transferId and value is the msg-sender
            celerStorageWrapper.setAddressForTransferId(transferId, msg.sender);
            router.send(
                celerBridgeData.receiverAddress,
                token,
                bridgeAmount,
                celerBridgeData.toChainId,
                celerBridgeData.nonce,
                celerBridgeData.maxSlippage
            );
        }

        emit SocketBridge(
            bridgeAmount,
            token,
            celerBridgeData.toChainId,
            CBridgeIdentifier,
            msg.sender,
            celerBridgeData.receiverAddress,
            celerBridgeData.metadata
        );
    }

    /**
     * @notice function to handle ERC20 bridging to receipent via Celer-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param receiverAddress address of recipient
     * @param token address of token being bridged
     * @param amount amount of token for bridging
     * @param toChainId destination ChainId
     * @param nonce nonce of the sender-account address
     * @param maxSlippage maximum Slippage for the bridging
     */
    function bridgeERC20To(
        address receiverAddress,
        address token,
        uint256 amount,
        bytes32 metadata,
        uint64 toChainId,
        uint64 nonce,
        uint32 maxSlippage
    ) external payable {
        /// @notice transferId is generated using the request-params and nonce of the account
        /// @notice transferId should be unique for each request and this is used while handling refund from celerBridge
        bytes32 transferId = keccak256(
            abi.encodePacked(
                address(this),
                receiverAddress,
                token,
                amount,
                toChainId,
                nonce,
                chainId
            )
        );

        /// @notice stored in the CelerStorageWrapper contract
        celerStorageWrapper.setAddressForTransferId(transferId, msg.sender);

        ERC20 tokenInstance = ERC20(token);
        tokenInstance.safeTransferFrom(msg.sender, socketGateway, amount);
        router.send(
            receiverAddress,
            token,
            amount,
            toChainId,
            nonce,
            maxSlippage
        );

        emit SocketBridge(
            amount,
            token,
            toChainId,
            CBridgeIdentifier,
            msg.sender,
            receiverAddress,
            metadata
        );
    }

    /**
     * @notice function to handle Native bridging to receipent via Celer-Bridge
     * @notice This method is payable because the caller is doing token transfer and briding operation
     * @param receiverAddress address of recipient
     * @param amount amount of token for bridging
     * @param toChainId destination ChainId
     * @param nonce nonce of the sender-account address
     * @param maxSlippage maximum Slippage for the bridging
     */
    function bridgeNativeTo(
        address receiverAddress,
        uint256 amount,
        bytes32 metadata,
        uint64 toChainId,
        uint64 nonce,
        uint32 maxSlippage
    ) external payable {
        bytes32 transferId = keccak256(
            abi.encodePacked(
                address(this),
                receiverAddress,
                weth,
                amount,
                toChainId,
                nonce,
                chainId
            )
        );

        celerStorageWrapper.setAddressForTransferId(transferId, msg.sender);

        router.sendNative{value: amount}(
            receiverAddress,
            amount,
            toChainId,
            nonce,
            maxSlippage
        );

        emit SocketBridge(
            amount,
            NATIVE_TOKEN_ADDRESS,
            toChainId,
            CBridgeIdentifier,
            msg.sender,
            receiverAddress,
            metadata
        );
    }

    /**
     * @notice function to handle refund from CelerBridge-Router
     * @param _request request data generated offchain using the celer-SDK
     * @param _sigs generated offchain using the celer-SDK
     * @param _signers  generated offchain using the celer-SDK
     * @param _powers generated offchain using the celer-SDK
     */
    function refundCelerUser(
        bytes calldata _request,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external payable {
        WithdrawMsg memory request = decWithdrawMsg(_request);
        bytes32 transferId = keccak256(
            abi.encodePacked(
                request.chainid,
                request.seqnum,
                request.receiver,
                request.token,
                request.amount
            )
        );
        uint256 _initialNativeBalance = address(this).balance;
        uint256 _initialTokenBalance = ERC20(request.token).balanceOf(
            address(this)
        );
        if (!router.withdraws(transferId)) {
            router.withdraw(_request, _sigs, _signers, _powers);
        }

        if (request.receiver != socketGateway) {
            revert InvalidCelerRefund();
        }

        address _receiver = celerStorageWrapper.getAddressFromTransferId(
            request.refid
        );
        celerStorageWrapper.deleteTransferId(request.refid);

        if (_receiver == address(0)) {
            revert CelerAlreadyRefunded();
        }

        uint256 _nativeBalanceAfter = address(this).balance;
        uint256 _tokenBalanceAfter = ERC20(request.token).balanceOf(
            address(this)
        );
        if (_nativeBalanceAfter > _initialNativeBalance) {
            if ((_nativeBalanceAfter - _initialNativeBalance) != request.amount)
                revert CelerRefundNotReady();
            payable(_receiver).transfer(request.amount);
            return;
        }

        if (_tokenBalanceAfter > _initialTokenBalance) {
            if ((_tokenBalanceAfter - _initialTokenBalance) != request.amount)
                revert CelerRefundNotReady();
            ERC20(request.token).safeTransfer(_receiver, request.amount);
            return;
        }

        revert CelerRefundNotReady();
    }

    function decWithdrawMsg(
        bytes memory raw
    ) internal pure returns (WithdrawMsg memory m) {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint256 tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {}
            // solidity has no switch/case
            else if (tag == 1) {
                m.chainid = uint64(buf.decVarint());
            } else if (tag == 2) {
                m.seqnum = uint64(buf.decVarint());
            } else if (tag == 3) {
                m.receiver = Pb._address(buf.decBytes());
            } else if (tag == 4) {
                m.token = Pb._address(buf.decBytes());
            } else if (tag == 5) {
                m.amount = Pb._uint256(buf.decBytes());
            } else if (tag == 6) {
                m.refid = Pb._bytes32(buf.decBytes());
            } else {
                buf.skipValue(wire);
            } // skip value of unknown tag
        }
    } // end decoder WithdrawMsg
}