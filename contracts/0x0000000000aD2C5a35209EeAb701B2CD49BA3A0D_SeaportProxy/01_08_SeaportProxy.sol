// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {BasicOrder} from "../libraries/OrderStructs.sol";
import {ItemType, OrderType} from "../libraries/seaport/ConsiderationEnums.sol";
import {AdvancedOrder, CriteriaResolver, OrderParameters, OfferItem, ConsiderationItem, FulfillmentComponent, AdditionalRecipient} from "../libraries/seaport/ConsiderationStructs.sol";
import {IProxy} from "../interfaces/IProxy.sol";
import {SeaportInterface} from "../interfaces/SeaportInterface.sol";
import {InvalidOrderLength, TradeExecutionFailed} from "../libraries/SharedErrors.sol";

/**
 * @title SeaportProxy
 * @notice This contract allows NFT sweepers to batch buy NFTs from Seaport
 *         by passing high-level structs + low-level bytes as calldata.
 * @author LooksRare protocol team (👀,💎)
 */
contract SeaportProxy is IProxy {
    SeaportInterface public immutable marketplace;
    address public immutable aggregator;

    /**
     * @param offerFulfillments Contains the order and item index of each offer item
     * @param considerationFulfillments Contains the order and item index of each consideration item
     */
    struct ExtraData {
        FulfillmentComponent[][] offerFulfillments;
        FulfillmentComponent[][] considerationFulfillments;
    }

    /**
     * @param numerator A fraction to attempt to fill
     * @param denominator The total size of the order
     * @param orderType Seaport order type
     * @param zone A zone can cancel the order or restrict who can fulfill the order
     *             depending on the type
     * @param zoneHash An arbitrary 32-byte value that will be supplied to the zone when
     *                 fulfilling restricted orders that the zone can utilize when making
     *                 a determination on whether to authorize the order
     * @param salt An arbitrary source of entropy for the order
     * @param conduitKey A bytes32 value that indicates what conduit, if any, should be
     *                   utilized as a source for token approvals when performing transfers
     * @param recipients Recipients of consideration items
     */
    struct OrderExtraData {
        uint120 numerator;
        uint120 denominator;
        OrderType orderType;
        address zone;
        bytes32 zoneHash;
        uint256 salt;
        bytes32 conduitKey;
        AdditionalRecipient[] recipients;
    }

    /**
     * @param _marketplace Seaport's address
     * @param _aggregator LooksRareAggregator's address
     */
    constructor(address _marketplace, address _aggregator) {
        marketplace = SeaportInterface(_marketplace);
        aggregator = _aggregator;
    }

    /**
     * @notice Execute Seaport NFT sweeps in a single transaction
     * @param orders Orders to be executed by Seaport
     * @param ordersExtraData Extra data for each order
     * @param extraData Extra data for the whole transaction
     * @param recipient The address to receive the purchased NFTs
     * @param isAtomic Flag to enable atomic trades (all or nothing) or partial trades
     */
    function execute(
        BasicOrder[] calldata orders,
        bytes[] calldata ordersExtraData,
        bytes calldata extraData,
        address recipient,
        bool isAtomic
    ) external payable override {
        if (address(this) != aggregator) {
            revert InvalidCaller();
        }

        uint256 ordersLength = orders.length;
        if (ordersLength == 0 || ordersLength != ordersExtraData.length) {
            revert InvalidOrderLength();
        }

        if (isAtomic) {
            _executeAtomicOrders(orders, ordersExtraData, extraData, recipient);
        } else {
            _executeNonAtomicOrders(orders, ordersExtraData, recipient);
        }
    }

    function _executeAtomicOrders(
        BasicOrder[] calldata orders,
        bytes[] calldata ordersExtraData,
        bytes calldata extraData,
        address recipient
    ) private {
        uint256 ordersLength = orders.length;
        AdvancedOrder[] memory advancedOrders = new AdvancedOrder[](ordersLength);
        ExtraData memory extraDataStruct = abi.decode(extraData, (ExtraData));

        uint256 ethValue;

        for (uint256 i; i < ordersLength; ) {
            OrderExtraData memory orderExtraData = abi.decode(ordersExtraData[i], (OrderExtraData));
            advancedOrders[i].parameters = _populateParameters(orders[i], orderExtraData);
            advancedOrders[i].numerator = orderExtraData.numerator;
            advancedOrders[i].denominator = orderExtraData.denominator;
            advancedOrders[i].signature = orders[i].signature;

            if (orders[i].currency == address(0)) {
                ethValue = ethValue + orders[i].price;
            }

            unchecked {
                ++i;
            }
        }

        (bool[] memory availableOrders, ) = marketplace.fulfillAvailableAdvancedOrders{value: ethValue}(
            advancedOrders,
            new CriteriaResolver[](0),
            extraDataStruct.offerFulfillments,
            extraDataStruct.considerationFulfillments,
            bytes32(0),
            recipient,
            ordersLength
        );

        for (uint256 i; i < availableOrders.length; ) {
            if (!availableOrders[i]) {
                revert TradeExecutionFailed();
            }
            unchecked {
                ++i;
            }
        }
    }

    function _executeNonAtomicOrders(
        BasicOrder[] calldata orders,
        bytes[] calldata ordersExtraData,
        address recipient
    ) private {
        for (uint256 i; i < orders.length; ) {
            OrderExtraData memory orderExtraData = abi.decode(ordersExtraData[i], (OrderExtraData));
            AdvancedOrder memory advancedOrder;
            advancedOrder.parameters = _populateParameters(orders[i], orderExtraData);
            advancedOrder.numerator = orderExtraData.numerator;
            advancedOrder.denominator = orderExtraData.denominator;
            advancedOrder.signature = orders[i].signature;

            address currency = orders[i].currency;
            uint256 price = orders[i].price;

            try
                marketplace.fulfillAdvancedOrder{value: currency == address(0) ? price : 0}(
                    advancedOrder,
                    new CriteriaResolver[](0),
                    bytes32(0),
                    recipient
                )
            {} catch {}

            unchecked {
                ++i;
            }
        }
    }

    function _populateParameters(BasicOrder calldata order, OrderExtraData memory orderExtraData)
        private
        pure
        returns (OrderParameters memory parameters)
    {
        uint256 recipientsLength = orderExtraData.recipients.length;

        parameters.offerer = order.signer;
        parameters.zone = orderExtraData.zone;
        parameters.zoneHash = orderExtraData.zoneHash;
        parameters.salt = orderExtraData.salt;
        parameters.conduitKey = orderExtraData.conduitKey;
        parameters.orderType = orderExtraData.orderType;
        parameters.startTime = order.startTime;
        parameters.endTime = order.endTime;
        parameters.totalOriginalConsiderationItems = recipientsLength;

        OfferItem[] memory offer = new OfferItem[](1);
        // Seaport enums start with NATIVE and ERC20 so plus 2
        unchecked {
            offer[0].itemType = ItemType(uint8(order.collectionType) + 2);
        }
        offer[0].token = order.collection;
        offer[0].identifierOrCriteria = order.tokenIds[0];
        uint256 amount = order.amounts[0];
        offer[0].startAmount = amount;
        offer[0].endAmount = amount;
        parameters.offer = offer;

        ConsiderationItem[] memory consideration = new ConsiderationItem[](recipientsLength);
        for (uint256 j; j < recipientsLength; ) {
            AdditionalRecipient memory recipient = orderExtraData.recipients[j];
            // We don't need to assign value to identifierOrCriteria as it is always 0.
            uint256 recipientAmount = recipient.amount;
            consideration[j].startAmount = recipientAmount;
            consideration[j].endAmount = recipientAmount;
            consideration[j].recipient = payable(recipient.recipient);
            consideration[j].itemType = order.currency == address(0) ? ItemType.NATIVE : ItemType.ERC20;
            consideration[j].token = order.currency;

            unchecked {
                ++j;
            }
        }
        parameters.consideration = consideration;
    }
}