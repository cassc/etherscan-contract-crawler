// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ConduitControllerInterface} from "../external/seaportcontracts/interfaces/ConduitControllerInterface.sol";
import {SeaportInterface} from "../external/seaportcontracts/interfaces/SeaportInterface.sol";
import {SellOrderV1} from "../passiveorders/SellOrderV1.sol";
import {Order, OrderParameters, OfferItem, ConsiderationItem} from "../external/seaportcontracts/lib/ConsiderationStructs.sol";
import {OrderType, ItemType} from "../external/seaportcontracts/lib/ConsiderationEnums.sol";

library SeaportUtil {
    function approveConduitForERC721(
        address conduitControllerAddress,
        bytes32 conduitKey,
        address erc721Address,
        uint256 tokenId
    ) public {
        ConduitControllerInterface conduitController = ConduitControllerInterface(
                conduitControllerAddress
            );
        // Get conduit.
        (address conduit, ) = conduitController.getConduit(conduitKey);
        IERC721(erc721Address).approve(conduit, tokenId);
    }

    function listERC721(
        SellOrderV1 calldata clowderSellOrder,
        uint256 minExpirationTime,
        uint256 netProceeds
    ) public {
        
        Order[] memory orders = new Order[](1);
        Order memory order = orders[0];
        OrderParameters memory orderParams = order.parameters;
        orderParams.offerer = address(this);
        orderParams.zone = clowderSellOrder.zone;
        orderParams.offer = new OfferItem[](1);
        OfferItem memory offer = orderParams.offer[0];
        offer.itemType = ItemType.ERC721;
        offer.token = clowderSellOrder.collection;
        offer.identifierOrCriteria = clowderSellOrder.tokenId;
        offer.startAmount = 1;
        offer.endAmount = 1;
        orderParams.consideration = new ConsiderationItem[](
            1 + clowderSellOrder.feeRecipients.length
        );
        ConsiderationItem memory cons = orderParams.consideration[0];
        cons.itemType = ItemType.NATIVE;
        cons.startAmount = netProceeds;
        cons.endAmount = netProceeds;
        cons.recipient = payable(address(this));
        for (uint256 i = 0; i < clowderSellOrder.feeRecipients.length; ++i) {
            cons = orderParams.consideration[1 + i];
            cons.itemType = ItemType.NATIVE;
            cons.startAmount = clowderSellOrder.feeRecipients[i].amount;
            cons.endAmount = clowderSellOrder.feeRecipients[i].amount;
            cons.recipient = clowderSellOrder.feeRecipients[i].recipient;
        }
        orderParams.orderType = orderParams.zone == address(0)
            ? OrderType.FULL_OPEN
            : OrderType.FULL_RESTRICTED;
        orderParams.startTime = block.timestamp;
        orderParams.endTime = minExpirationTime;
        orderParams.conduitKey = clowderSellOrder.conduitKey;
        orderParams.totalOriginalConsiderationItems =
            1 +
            clowderSellOrder.feeRecipients.length;

        SeaportInterface seaport = SeaportInterface(
            clowderSellOrder.seaport
        );
        assert(seaport.validate(orders));
    }
}