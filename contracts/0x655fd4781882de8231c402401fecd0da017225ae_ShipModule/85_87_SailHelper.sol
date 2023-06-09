// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Order, OrderComponents, OrderParameters, OfferItem, ItemType, ConsiderationItem, OrderType} from "seaport/lib/ConsiderationStructs.sol";
import {ConsiderationInterface} from "seaport/interfaces/ConsiderationInterface.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

struct SeaportArgs {
    address seaport;
    address seaportConduit;
    address seaportPayableProxy;
    uint256 openseaFee;
    bytes32 seaportConduitKey;
}

struct GnosisArgs {
    address gnosisSafeProxyFactory;
    address gnosisSafeTemplate;
    address gnosisSafeFallbackHandler;
    address gnosisSafeModuleFactory;
}

struct SZNSDaoArgs {
    address sznsDao;
    uint256 sznsDaoFee;
}

/**
 * @title Sealib
 * @dev Library for creating Seaport orders.
 */
contract SailHelper is Ownable {
    address public royaltyEngine;

    address public sznsDao;
    uint256 public sznsDaoFee; // eg: 1e18 == 1% 10e18 == 10%

    // Gnosis refs
    // From https://github.com/safe-global/safe-deployments/tree/main/src/assets/v1.3.0
    address public gnosisSafeProxyFactory;
    address public gnosisSafeTemplate;
    address public gnosisSafeFallbackHandler;

    // From https://github.com/gnosis/zodiac/blob/b5fd8064c596a5ccef3330b072159239768052dd/src/deployments.json#L84
    address public gnosisSafeModuleFactory;

    uint256 public openseaFee;
    // Seaport addresses
    address public seaport;
    address public seaportConduit;
    // Payable proxy for opensea where sale fees get forwarded
    address public seaportPayableProxy;
    bytes32 public seaportConduitKey;

    error InvalidFee();

    constructor(
        GnosisArgs memory gnosisArgs,
        SeaportArgs memory seaportArgs,
        SZNSDaoArgs memory sznsArgs,
        address _royaltyEngine
    ) {
        gnosisSafeProxyFactory = gnosisArgs.gnosisSafeProxyFactory;
        gnosisSafeTemplate = gnosisArgs.gnosisSafeTemplate;
        gnosisSafeFallbackHandler = gnosisArgs.gnosisSafeFallbackHandler;
        gnosisSafeModuleFactory = gnosisArgs.gnosisSafeModuleFactory;

        seaport = seaportArgs.seaport;
        seaportConduit = seaportArgs.seaportConduit;
        seaportPayableProxy = seaportArgs.seaportPayableProxy;
        openseaFee = seaportArgs.openseaFee;
        seaportConduitKey = seaportArgs.seaportConduitKey;

        sznsDao = sznsArgs.sznsDao;
        sznsDaoFee = sznsArgs.sznsDaoFee;

        royaltyEngine = _royaltyEngine;
    }

    /**
     * @dev Builds a Seaport order for an ERC721 token.
     * @param offerer Address of the offerer.
     * @param recipient Address of the recipient.
     * @param nftContract Address of the ERC721 contract.
     * @param tokenID ID of the token being sold.
     * @param amount Amount of the sale.
     * @param endTime End time of the order.
     * @return seaportOrder memory seaportOrder Order created.
     * @notice This function will create an order with 2.5% of the revenue going to the SEAPORT_PAYABLE_PROXY and 97.5% going to the recipient.
     */
    function buildOrderFor(
        address offerer,
        address payable recipient,
        address payable[] memory royaltyRecipients,
        address nftContract,
        uint256 tokenID,
        uint256 amount,
        uint256[] memory royaltyAmounts,
        uint256 endTime
    ) public view returns (Order memory seaportOrder) {
        seaportOrder.parameters.offerer = address(offerer);
        seaportOrder.parameters.zone = address(0);
        seaportOrder.parameters.orderType = OrderType.FULL_OPEN;
        seaportOrder.parameters.startTime = block.timestamp;
        seaportOrder.parameters.endTime = endTime;
        seaportOrder.parameters.zoneHash = bytes32(0);
        seaportOrder.parameters.salt = uint256(0);
        seaportOrder.parameters.conduitKey = seaportConduitKey;

        OfferItem memory nftItem;
        nftItem.itemType = ItemType.ERC721;
        nftItem.token = nftContract;
        nftItem.identifierOrCriteria = tokenID;
        nftItem.startAmount = 1;
        nftItem.endAmount = 1;
        OfferItem[] memory offer = new OfferItem[](1);
        offer[0] = nftItem;
        seaportOrder.parameters.offer = offer;

        uint256 openseaRevenue = (amount * openseaFee) / 100e18;

        uint256 countRecipientsRoyalties = royaltyRecipients.length;
        ConsiderationItem[] memory considerations = new ConsiderationItem[](
            countRecipientsRoyalties + 2 // + 1 for opensea and + 1 for offerer
        );

        for (uint256 i = 0; i < countRecipientsRoyalties; ) {
            ConsiderationItem memory considerationRoyalty;
            considerationRoyalty.itemType = ItemType.NATIVE;
            considerationRoyalty.token = address(0); // For eth
            considerationRoyalty.startAmount = royaltyAmounts[i];
            considerationRoyalty.endAmount = royaltyAmounts[i];
            considerationRoyalty.recipient = payable(royaltyRecipients[i]);
            considerations[i + 2] = considerationRoyalty; // Push royalty to last in array
            amount -= royaltyAmounts[i];
            ++i;
        }

        // Opensea fee minimum 2.5% of revenue
        // We do this so we get exactly 2.5% for opensea
        ConsiderationItem memory openseaConsideration;
        openseaConsideration.itemType = ItemType.NATIVE;
        openseaConsideration.token = address(0); // For eth
        openseaConsideration.startAmount = openseaRevenue;
        openseaConsideration.endAmount = openseaRevenue; // 2.5%
        openseaConsideration.recipient = payable(seaportPayableProxy);

        // remaining amount - opensea: goes to offerer
        uint256 offererRevenue = amount - openseaRevenue;
        ConsiderationItem memory offererConsideration;
        offererConsideration.itemType = ItemType.NATIVE;
        offererConsideration.token = address(0); // For eth
        offererConsideration.startAmount = offererRevenue;
        offererConsideration.endAmount = offererRevenue; // 97.5%
        offererConsideration.recipient = payable(recipient);

        considerations[0] = offererConsideration; // Offerer consideration needs to be the first one in the list
        considerations[1] = openseaConsideration;
        seaportOrder.parameters.consideration = considerations;

        seaportOrder.parameters.totalOriginalConsiderationItems = considerations
            .length;
    }

    function updateSeaportArgs(SeaportArgs memory s) public onlyOwner {
        seaport = s.seaport;
        seaportConduit = s.seaportConduit;
        seaportPayableProxy = s.seaportPayableProxy;
        openseaFee = s.openseaFee;
        seaportConduitKey = s.seaportConduitKey;
    }

    function updateGnosisArgs(GnosisArgs memory g) public onlyOwner {
        gnosisSafeProxyFactory = g.gnosisSafeProxyFactory;
        gnosisSafeTemplate = g.gnosisSafeTemplate;
        gnosisSafeFallbackHandler = g.gnosisSafeFallbackHandler;
        gnosisSafeModuleFactory = g.gnosisSafeModuleFactory;
    }

    function setRoyaltyEngine(address _royaltyEngine) public onlyOwner {
        setRoyaltyEngine(_royaltyEngine);
    }

    function setSznsDaoFee(uint256 _fee) public onlyOwner {
        if (_fee > 100e18) {
            revert InvalidFee();
        }
        sznsDaoFee = _fee;
    }

    function setOpenseaFee(uint256 _fee) public onlyOwner {
        if (_fee > 100e18) {
            revert InvalidFee();
        }
        openseaFee = _fee;
    }
}