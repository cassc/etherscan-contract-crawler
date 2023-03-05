// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "./im/message/framework/MessageSenderApp.sol";
import "./im/message/framework/MessageReceiverApp.sol";
import "../../../interfaces/IUniswapV2.sol";
import "../../../interfaces/IWETH.sol";
import "./im/interfaces/IMessageBusSender.sol";
import "../../../interfaces/IRangoCBridge.sol";
import "../../../libraries/LibInterchain.sol";
import "../../../interfaces/IRangoMessageReceiver.sol";
import "../../../interfaces/Interchain.sol";
import "../../../utils/ReentrancyGuard.sol";
import "../../../libraries/LibDiamond.sol";
import {RangoCBridgeMiddleware} from "./RangoCBridgeMiddleware.sol";

/// @title The root contract that handles Rango's interaction with cBridge through a middleware
/// @author George
/// @dev Logic for direct interaction with CBridge is mostly implemented in RangoCBridgeMiddleware contract.
contract RangoCBridgeFacet is IRango, IRangoCBridge, ReentrancyGuard {
    /// @dev keccak256("exchange.rango.facets.cbridge")
    bytes32 internal constant CBRIDGE_NAMESPACE = hex"c41612f6cce3d3f6bab8332956a2c64db0d9b22d96d4f739ed2233d021aebb9b";

    struct cBridgeStorage {
        address payable rangoCBridgeMiddlewareAddress;
    }

    /// Constructor

    /// @notice Initialize the contract.
    /// @param rangoCBridgeMiddlewareAddress The address of rango cBridge middleware
    function initCBridge(address payable rangoCBridgeMiddlewareAddress) external {
        LibDiamond.enforceIsContractOwner();
        updateRangoCBridgeMiddlewareAddressInternal(rangoCBridgeMiddlewareAddress);
    }

    /// @notice Enables the contract to receive native ETH token from other contracts including WETH contract
    receive() external payable {}


    /// @notice Emits when the cBridge address is updated
    /// @param oldAddress The previous address
    /// @param newAddress The new address
    event RangoCBridgeMiddlewareAddressUpdated(address oldAddress, address newAddress);

    /// @notice Executes a DEX (arbitrary) call + a cBridge send function
    /// @param request The general swap request containing from/to token and fee/affiliate rewards
    /// @param calls The list of DEX calls, if this list is empty, it means that there is no DEX call and we are only bridging
    /// @dev The cbridge part is handled in the RangoCBridgeMiddleware contract
    /// @dev If this function is success, user will automatically receive the fund in the destination in his/her wallet (receiver)
    /// @dev If bridge is out of liquidity somehow after submiting this transaction and success, user must sign a refund transaction which is not currently present here, will be supported soon
    function cBridgeSwapAndBridge(
        LibSwapper.SwapRequest memory request,
        LibSwapper.Call[] calldata calls,
        CBridgeBridgeRequest calldata bridgeRequest
    ) external payable nonReentrant {
        address payable middleware = getCBridgeStorage().rangoCBridgeMiddlewareAddress;
        require(middleware != LibSwapper.ETH, "Middleware not set");
        // transfer tokens to middleware if necessary
        uint sgnFee = bridgeRequest.sgnFee;
        uint value = sgnFee;
        uint bridgeAmount;
        if (request.toToken == LibSwapper.ETH && msg.value == 0) {
            uint out = LibSwapper.onChainSwapsPreBridge(request, calls, 0);
            bridgeAmount = out - sgnFee;
            // value should not decrease sgnFee, we should send full value to the middleware
            value = out;
        }
        else {
            bridgeAmount = LibSwapper.onChainSwapsPreBridge(request, calls, sgnFee);
        }
        // transfer tokens to middleware if necessary
        if (request.toToken != LibSwapper.ETH) {
            SafeERC20.safeTransfer(IERC20(request.toToken), middleware, bridgeAmount);
        }

        if (bridgeRequest.bridgeType == CBridgeBridgeType.TRANSFER) {
            RangoCBridgeMiddleware(middleware).doSend{value : value}(
                bridgeRequest.receiver,
                request.toToken,
                bridgeAmount,
                bridgeRequest.dstChainId,
                bridgeRequest.nonce,
                bridgeRequest.maxSlippage);

            // event emission
            emit RangoBridgeInitiated(
                request.requestId,
                request.toToken,
                bridgeAmount,
                bridgeRequest.receiver,
                bridgeRequest.dstChainId,
                false,
                false,
                uint8(BridgeType.CBridge),
                request.dAppTag
            );
        } else {
            Interchain.RangoInterChainMessage memory imMessage = abi.decode((bridgeRequest.imMessage), (Interchain.RangoInterChainMessage));
            RangoCBridgeMiddleware(middleware).doCBridgeIM{value : value}(
                request.toToken,
                bridgeAmount,
                bridgeRequest.receiver,
                bridgeRequest.dstChainId,
                bridgeRequest.nonce,
                bridgeRequest.maxSlippage,
                sgnFee,
                imMessage
            );

            // event emission
            emit RangoBridgeInitiated(
                request.requestId,
                request.toToken,
                bridgeAmount,
                bridgeRequest.receiver,
                bridgeRequest.dstChainId,
                true,
                imMessage.actionType != Interchain.ActionType.NO_ACTION,
                uint8(BridgeType.CBridge),
                request.dAppTag
            );
        }
    }

    /// @notice Executes a DEX (arbitrary) call + a cBridge send function

    /// @dev The cbridge part is handled in the RangoCBridgeMiddleware contract
    /// @dev If this function is success, user will automatically receive the fund in the destination in his/her wallet (receiver)
    /// @dev If bridge is out of liquidity somehow after submiting this transaction and success, user must sign a refund transaction which is not currently present here, will be supported later
    function cBridgeBridge(
        RangoBridgeRequest memory request,
        CBridgeBridgeRequest calldata bridgeRequest
    ) external payable nonReentrant {
        address payable middleware = getCBridgeStorage().rangoCBridgeMiddlewareAddress;
        require(middleware != LibSwapper.ETH, "Middleware not set");
        // transfer tokens to middleware if necessary
        uint amount = request.amount;
        uint sumFees = LibSwapper.sumFees(request);
        uint value = bridgeRequest.sgnFee;
        if (request.token == LibSwapper.ETH) {
            require(msg.value >= amount + bridgeRequest.sgnFee + sumFees, "Insufficient ETH");
            value = amount + bridgeRequest.sgnFee;
        } else {
            // To save gas we dont transfer to this contract, instead we directly transfer from user to middleware.
            // Note we only send the amount to middleware (doesn't include fees)
            SafeERC20.safeTransferFrom(IERC20(request.token), msg.sender, middleware, amount);
            require(msg.value >= value, "Insufficient ETH");
        }

        // collect fees directly from sender
        LibSwapper.collectFeesFromSender(request);

        if (bridgeRequest.bridgeType == CBridgeBridgeType.TRANSFER) {
            RangoCBridgeMiddleware(middleware).doSend{value : value}(
                bridgeRequest.receiver,
                request.token,
                amount,
                bridgeRequest.dstChainId,
                bridgeRequest.nonce,
                bridgeRequest.maxSlippage);

            // event emission
            emit RangoBridgeInitiated(
                request.requestId,
                request.token,
                amount,
                bridgeRequest.receiver,
                bridgeRequest.dstChainId,
                false,
                false,
                uint8(BridgeType.CBridge),
                request.dAppTag
            );
        } else {
            Interchain.RangoInterChainMessage memory imMessage = abi.decode((bridgeRequest.imMessage), (Interchain.RangoInterChainMessage));
            RangoCBridgeMiddleware(middleware).doCBridgeIM{value : value}(
                request.token,
                amount,
                bridgeRequest.receiver,
                bridgeRequest.dstChainId,
                bridgeRequest.nonce,
                bridgeRequest.maxSlippage,
                bridgeRequest.sgnFee,
                imMessage
            );

            // event emission
            emit RangoBridgeInitiated(
                request.requestId,
                request.token,
                amount,
                bridgeRequest.receiver,
                bridgeRequest.dstChainId,
                true,
                imMessage.actionType != Interchain.ActionType.NO_ACTION,
                uint8(BridgeType.CBridge),
                request.dAppTag
            );
        }
    }

    function updateRangoCBridgeMiddlewareAddressInternal(address payable newAddress) private {
        cBridgeStorage storage s = getCBridgeStorage();

        address oldAddress = getRangoCBridgeMiddlewareAddress();
        s.rangoCBridgeMiddlewareAddress = newAddress;

        emit RangoCBridgeMiddlewareAddressUpdated(oldAddress, newAddress);
    }

    function getRangoCBridgeMiddlewareAddress() internal view returns (address) {
        cBridgeStorage storage s = getCBridgeStorage();
        return s.rangoCBridgeMiddlewareAddress;
    }

    /// @dev fetch local storage
    function getCBridgeStorage() private pure returns (cBridgeStorage storage s) {
        bytes32 namespace = CBRIDGE_NAMESPACE;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            s.slot := namespace
        }
    }
}