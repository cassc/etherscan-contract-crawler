pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./libs/LibBytes.sol";
import "./libs/LibOrder.sol";
import "./interfaces/IExchangeCore.sol";
import "./interfaces/IAssetData.sol";
import "./AssetProxyRegistry.sol";
import "./EIP712Domain.sol";
import "./ProtocolFees.sol";
import "./SignatureValidator.sol";
import "./MarketplaceRegistry.sol";

abstract contract ExchangeCore is
    IExchangeCore,
    AssetProxyRegistry,
    ProtocolFees,
    SignatureValidator,
    MarketplaceRegistry
{
    using LibOrder for LibOrder.Order;
    using SafeMath for uint256;
    using LibBytes for bytes;

    /// @dev orderHash => filled
    /// @return boolean the order has been filled
    mapping (bytes32 => bool) public filled;

    /// @dev orderHash => cancelled
    /// @return boolean the order has been cancelled
    mapping (bytes32 => bool) public cancelled;

    /// @dev makerAddress => lowest salt an order can have in order to be fillable
    /// @return epoc Orders with a salt less than their epoch are considered cancelled
    mapping (address => uint256) public orderEpoch;

    /// @dev Fills the input order.
    /// @param order Order struct containing order specifications.
    /// @param signature Proof that order has been created by maker.
    /// @param takerAddress orider fill for the taker.
    /// @return fulfilled boolean
    function _fillOrder(
        LibOrder.Order memory order,
        bytes memory signature,
        address takerAddress,
        bytes32 marketplaceIdentifier
    )
        internal
        returns (bool fulfilled)
    {
        // Fetch order info
        LibOrder.OrderInfo memory orderInfo = _getOrderInfo(order);

        // Assert that the order is fillable by taker
        _assertFillable(
            order,
            orderInfo,
            takerAddress,
            signature
        );

        bytes32 orderHash = orderInfo.orderHash;

        // Update state
        filled[orderHash] = true;

        Marketplace memory marketplace = marketplaces[marketplaceIdentifier];

        // Settle order
        (uint256 protocolFee, uint256 marketplaceFee) = _settle(
            orderInfo,
            order,
            takerAddress,
            marketplace
        );

        _notifyFill(order, orderHash, takerAddress, protocolFee, marketplaceIdentifier, marketplaceFee);

        return filled[orderHash];
    }

    function _notifyFill(
        LibOrder.Order memory order,
        bytes32 orderHash,
        address takerAddress,
        uint256 protocolFee,
        bytes32 marketplaceIdentifier,
        uint256 marketplaceFee
    ) internal {
        emit Fill(
            order.makerAddress,
            order.royaltiesAddress,
            order.makerAssetData,
            order.takerAssetData,
            orderHash,
            takerAddress,
            msg.sender,
            order.makerAssetAmount,
            order.takerAssetAmount,
            order.royaltiesAmount,
            protocolFee,
            marketplaceIdentifier,
            marketplaceFee
        );
    }

    /// @dev After calling, the order can not be filled anymore.
    ///      Throws if order is invalid or sender does not have permission to cancel.
    /// @param order Order to cancel. Order must be OrderStatus.FILLABLE.
    function _cancelOrder(LibOrder.Order memory order)
        internal
    {
        // Fetch current order status
        LibOrder.OrderInfo memory orderInfo = _getOrderInfo(order);

        // Validate context
        _assertValidCancel(order);

        // Noop if order is already unfillable
        if (orderInfo.orderStatus != LibOrder.OrderStatus.FILLABLE) {
            return;
        }

        // Perform cancel
        _updateCancelledState(order, orderInfo.orderHash);
    }

    /// @dev Updates state with results of cancelling an order.
    ///      State is only updated if the order is currently fillable.
    ///      Otherwise, updating state would have no effect.
    /// @param order that was cancelled.
    /// @param orderHash Hash of order that was cancelled.
    function _updateCancelledState(
        LibOrder.Order memory order,
        bytes32 orderHash
    )
        internal
    {
        // Perform cancel
        cancelled[orderHash] = true;

        // Log cancel
        emit Cancel(
            order.makerAddress,
            order.makerAssetData,
            order.takerAssetData,
            msg.sender,
            orderHash
        );
    }

    /// @dev Validates context for fillOrder. Succeeds or throws.
    /// @param order to be filled.
    /// @param orderInfo OrderStatus, orderHash, and amount already filled of order.
    /// @param takerAddress Address of order taker.
    /// @param signature Proof that the orders was created by its maker.
    function _assertFillable(
        LibOrder.Order memory order,
        LibOrder.OrderInfo memory orderInfo,
        address takerAddress,
        bytes memory signature
    )
        internal
    {
        if (orderInfo.orderType == LibOrder.OrderType.INVALID) {
            revert('EXCHANGE: type illegal');
        }

        if (orderInfo.orderType == LibOrder.OrderType.LIST) {
            address erc20TokenAddress = order.takerAssetData.readAddress(4);
            if (erc20TokenAddress == address(0) && msg.value < order.takerAssetAmount) {
                revert('EXCHANGE: wrong value sent');
            }
        }

        if (orderInfo.orderType != LibOrder.OrderType.LIST && takerAddress != msg.sender) {
            revert('EXCHANGE: fill order for is only valid for buy now');
        }

        if (orderInfo.orderType == LibOrder.OrderType.SWAP) {
            if (msg.value < protocolFixedFee) {
                revert('EXCHANGE: wrong value sent');
            }
        }

        // An order can only be filled if its status is FILLABLE.
        if (orderInfo.orderStatus != LibOrder.OrderStatus.FILLABLE) {
            revert('EXCHANGE: status not fillable');
        }

        // Validate sender is allowed to fill this order
        if (order.senderAddress != address(0)) {
            if (order.senderAddress != msg.sender) {
                revert('EXCHANGE: invalid sender');
            }
        }

        // Validate taker is allowed to fill this order
        if (order.takerAddress != address(0)) {
            if (order.takerAddress != takerAddress) {
                revert('EXCHANGE: invalid taker');
            }
        }

        // Validate signature
        if (!_isValidOrderWithHashSignature(
                order,
                orderInfo.orderHash,
                signature
            )
        ) {
            revert('EXCHANGE: invalid signature');
        }
    }

    /// @dev Validates context for cancelOrder. Succeeds or throws.
    /// @param order to be cancelled.
    function _assertValidCancel(
        LibOrder.Order memory order
    )
        internal
        view
    {
        // Validate sender is allowed to cancel this order
        if (order.senderAddress != address(0)) {
            if (order.senderAddress != msg.sender) {
                revert('EXCHANGE: invalid sender');
            }
        }

        // Validate transaction signed by maker
        address makerAddress = msg.sender;
        if (order.makerAddress != makerAddress) {
            revert('EXCHANGE: invalid maker');
        }
    }

    /// @dev Gets information about an order: status, hash, and amount filled.
    /// @param order Order to gather information on.
    /// @return orderInfo Information about the order and its state.
    ///         See LibOrder.OrderInfo for a complete description.
    function _getOrderInfo(LibOrder.Order memory order)
        internal
        view
        returns (LibOrder.OrderInfo memory orderInfo)
    {
        // Compute the order hash
        orderInfo.orderHash = order.getTypedDataHash(DOMAIN_HASH);

        bool isTakerAssetDataERC20 = _isERC20Proxy(order.takerAssetData);
        bool isMakerAssetDataERC20 = _isERC20Proxy(order.makerAssetData);

        if (isTakerAssetDataERC20 && !isMakerAssetDataERC20) {
            orderInfo.orderType = LibOrder.OrderType.LIST;
        } else if (!isTakerAssetDataERC20 && isMakerAssetDataERC20) {
            orderInfo.orderType = LibOrder.OrderType.OFFER;
        } else if (!isTakerAssetDataERC20 && !isMakerAssetDataERC20) {
            orderInfo.orderType = LibOrder.OrderType.SWAP;
        } else {
            orderInfo.orderType = LibOrder.OrderType.INVALID;
        }

        // If order.makerAssetAmount is zero the order is invalid
        if (order.makerAssetAmount == 0) {
            orderInfo.orderStatus = LibOrder.OrderStatus.INVALID_MAKER_ASSET_AMOUNT;
            return orderInfo;
        }

        // If order.takerAssetAmount is zero the order is invalid
        if (order.takerAssetAmount == 0) {
            orderInfo.orderStatus = LibOrder.OrderStatus.INVALID_TAKER_ASSET_AMOUNT;
            return orderInfo;
        }

        if (orderInfo.orderType == LibOrder.OrderType.LIST && order.royaltiesAmount > order.takerAssetAmount) {
            orderInfo.orderStatus = LibOrder.OrderStatus.INVALID_ROYALTIES;
            return orderInfo;
        }

        if (orderInfo.orderType == LibOrder.OrderType.OFFER && order.royaltiesAmount > order.makerAssetAmount) {
            orderInfo.orderStatus = LibOrder.OrderStatus.INVALID_ROYALTIES;
            return orderInfo;
        }

        // Check if order has been filled
        if (filled[orderInfo.orderHash]) {
            orderInfo.orderStatus = LibOrder.OrderStatus.FILLED;
            return orderInfo;
        }

        // Check if order has been cancelled
        if (cancelled[orderInfo.orderHash]) {
            orderInfo.orderStatus = LibOrder.OrderStatus.CANCELLED;
            return orderInfo;
        }

        if (orderEpoch[order.makerAddress] > order.salt) {
            orderInfo.orderStatus = LibOrder.OrderStatus.CANCELLED;
            return orderInfo;
        }

        // Validate order expiration
        if (block.timestamp >= order.expirationTimeSeconds) {
            orderInfo.orderStatus = LibOrder.OrderStatus.EXPIRED;
            return orderInfo;
        }

        // All other statuses are ruled out: order is Fillable
        orderInfo.orderStatus = LibOrder.OrderStatus.FILLABLE;
        return orderInfo;
    }


    /// @dev Settles an order by transferring assets between counterparties.
    /// @param orderInfo The order info struct.
    /// @param order Order struct containing order specifications.
    /// @param takerAddress Address selling takerAsset and buying makerAsset.
    function _settle(
        LibOrder.OrderInfo memory orderInfo,
        LibOrder.Order memory order,
        address takerAddress,
        Marketplace memory marketplace
    )
        internal
        returns (uint256 protocolFee, uint256 marketplaceFee)
    {
        bytes memory payerAssetData;
        bytes memory sellerAssetData;
        address payerAddress;
        address sellerAddress;
        uint256 buyerPayment;
        uint256 sellerAmount;

        if (orderInfo.orderType == LibOrder.OrderType.LIST) {
            payerAssetData = order.takerAssetData;
            sellerAssetData = order.makerAssetData;
            payerAddress = msg.sender;
            sellerAddress = order.makerAddress;
            buyerPayment = order.takerAssetAmount;
            sellerAmount = order.makerAssetAmount;
        }

        if (orderInfo.orderType == LibOrder.OrderType.OFFER || orderInfo.orderType == LibOrder.OrderType.SWAP) {
            payerAssetData = order.makerAssetData;
            sellerAssetData = order.takerAssetData;
            payerAddress = order.makerAddress;
            sellerAddress = msg.sender;
            takerAddress = payerAddress;
            buyerPayment = order.makerAssetAmount;
            sellerAmount = order.takerAssetAmount;
        }


        // pay protocol fees
        if (protocolFeeCollector != address(0)) {
            bytes memory protocolAssetData = payerAssetData;
            if (orderInfo.orderType == LibOrder.OrderType.SWAP && protocolFixedFee > 0) {
                protocolFee = protocolFixedFee;
                protocolAssetData = abi.encodeWithSelector(IAssetData(address(0)).ERC20Token.selector, address(0));
            } else if (protocolFeeMultiplier > 0) {
                protocolFee = buyerPayment.mul(protocolFeeMultiplier).div(100);
                buyerPayment = buyerPayment.sub(protocolFee);
            }

            if (marketplace.isActive && marketplace.feeCollector != address(0) && marketplace.feeMultiplier > 0 && distributeMarketplaceFees) {
                marketplaceFee = protocolFee.mul(marketplace.feeMultiplier).div(100);
                protocolFee = protocolFee.sub(marketplaceFee);
                _dispatchTransfer(
                    protocolAssetData,
                    payerAddress,
                    marketplace.feeCollector,
                    marketplaceFee
                );
            }

            _dispatchTransfer(
                protocolAssetData,
                payerAddress,
                protocolFeeCollector,
                protocolFee
            );
        }

        // pay royalties
        if (order.royaltiesAddress != address(0) && order.royaltiesAmount > 0 ) {
            buyerPayment = buyerPayment.sub(order.royaltiesAmount);
            _dispatchTransfer(
                payerAssetData,
                payerAddress,
                order.royaltiesAddress,
                order.royaltiesAmount
            );
        }

        // pay seller // erc20
        _dispatchTransfer(
            payerAssetData,
            payerAddress,
            sellerAddress,
            buyerPayment
        );

        // Transfer seller -> buyer (nft / bundle)
        _dispatchTransfer(
            sellerAssetData,
            sellerAddress,
            takerAddress,
            sellerAmount
        );

        return (protocolFee, marketplaceFee);
      
    }
}