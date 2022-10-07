// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ISingleToken} from "../token/ISingleToken.sol";
import {IMetaUnitTracker} from "../../MetaUnit/Tracker/IMetaUnitTracker.sol";
import {Pausable} from "../../../Pausable.sol";

/**
 * @author MetaPlayerOne DAO
 * @title MakeAnOffer
 * @notice Manages the make an offer logic. 
 */
contract MakeAnOffer is Pausable {
    struct Offer { uint256 uid; address token_address; uint256 token_id; uint256 price; address seller; address buyer; bool canceled; bool finished; }

    Offer[] private _offers;

    address private _meta_unit_tracker_address;

    /**
     * @dev setup Metaunit address and owner of customer.
     */
    constructor(address owner_of_, address meta_unit_tracker_address_) Pausable(owner_of_) {
        _meta_unit_tracker_address = meta_unit_tracker_address_;
    }

    /**
     * @dev emits when offer creates.
     */
    event offerCreated(uint256 uid, address token_address, uint256 token_id, uint256 price, address seller, address buyer, bool canceled, bool finished);

    /**
     * @dev emits when offer cancels.
     */
    event offerCanceled(uint256 uid, address initiator);

    /**
     * @dev emits when offer resolves.
     */
    event offerResolved(uint256 uid);

    /**
     * @dev allows you to create an offer for a token.
     * @param token_address address of the token for which you want to make an offer.
     * @param token_id id of the token for which you want to make an offer.
     * @param price price you offer.
     * @param buyer the offeror's address.
     */
    function create(address token_address, uint256 token_id, uint256 price, address buyer) public notPaused {
        uint256 newOfferUid = _offers.length;
        _offers.push(Offer(newOfferUid, token_address, token_id, price, msg.sender, buyer, false, false));
        IERC721(token_address).transferFrom(msg.sender, address(this), token_id);
        emit offerCreated(newOfferUid, token_address, token_id, price, msg.sender, buyer, false, false);
    }

    /**
     * @dev allows you to cancel offers.
     * @param uid offer unique id you want to cancel.
     */
    function cancel(uint256 uid) public {
        Offer memory offer = _offers[uid];
        require(msg.sender == offer.buyer || msg.sender == offer.seller, "Permission denied");
        IERC721(offer.token_address).transferFrom(address(this), offer.seller, offer.token_id);
        _offers[uid].canceled = true;
        emit offerCanceled(uid, msg.sender);
    }

    /**
     * @dev allows you to cancel an offer
     * @param uid offer unique id you want to accept.
     */
    function resolve(uint256 uid) public payable {
        Offer memory offer = _offers[uid];
        require(msg.sender == offer.buyer, "Permission denied");
        require(msg.value >= offer.price, "Not enough funds sent");
        require(!offer.canceled, "Offer has been canceled");
        require(!offer.finished, "Offer has been already resolved");
        payable(offer.seller).transfer((msg.value * 975) / 1000);
        payable(_owner_of).transfer((msg.value * 25) / 1000);
        IERC721(offer.token_address).transferFrom(address(this), msg.sender, offer.token_id);
        IMetaUnitTracker(_meta_unit_tracker_address).track(offer.seller, offer.price);
        _offers[uid].finished = true;
        emit offerResolved(uid);
    }
}