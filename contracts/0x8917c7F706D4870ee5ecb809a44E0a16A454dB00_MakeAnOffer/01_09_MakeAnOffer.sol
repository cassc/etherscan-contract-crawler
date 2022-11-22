// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from  "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {ISingleToken} from "../token/ISingleToken.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {IMetaUnitTracker} from "../../MetaUnit/Tracker/IMetaUnitTracker.sol";
import {Pausable} from "../../../Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @author MetaPlayerOne DAO
 * @title MakeAnOffer
 * @notice Manages the make an offer logic. 
 */
contract MakeAnOffer is Pausable, ReentrancyGuard {
    struct Offer { uint256 uid; bool is_single;  address token_address; uint256 token_id; uint256 amount; uint256 price; address buyer; address seller; bool canceled; bool finished; }

    Offer[] private _offers;

    address private _meta_unit_tracker_address;

    constructor(address owner_of_, address meta_unit_tracker_address_) Pausable(owner_of_) {
        _meta_unit_tracker_address = meta_unit_tracker_address_;
    }

    event offerCreated(uint256 uid, address token_address, uint256 token_id, uint256 amount, uint256 price, address buyer, address seller, bool canceled, bool finished);
    event offerCanceled(uint256 uid, address initiator);
    event offerResolved(uint256 uid);

    function create(address token_address_, uint256 token_id_, address seller_, uint256 amount_) public payable notPaused nonReentrant {
        uint256 newOfferUid = _offers.length;
        bool is_single = false;
        try IERC721Metadata(token_address_).tokenURI(token_id_) { is_single = true; } catch {}
        _offers.push(Offer(newOfferUid, is_single, token_address_, token_id_, amount_, msg.value, msg.sender, seller_, false, false));
        emit offerCreated(newOfferUid, token_address_, token_id_, amount_, msg.value, msg.sender, seller_, false, false);
    }

    function cancel(uint256 uid_) public nonReentrant {
        Offer memory offer = _offers[uid_];
        require(msg.sender == offer.buyer, "Permission denied");
        payable(offer.buyer).send(offer.price);
        _offers[uid_].canceled = true;
        emit offerCanceled(uid_, msg.sender);
    }

    function resolve(uint256 uid_) public nonReentrant {
        Offer memory offer = _offers[uid_];
        require(!offer.canceled, "Offer has been canceled");
        require(!offer.finished, "Offer has been already resolved");
        require(offer.seller == msg.sender, "You are not an owner of this nft");
        if (offer.is_single) IERC721(offer.token_address).transferFrom(msg.sender, offer.buyer, offer.token_id); 
        else IERC1155(offer.token_address).safeTransferFrom(msg.sender, offer.buyer, offer.token_id, offer.amount, "");
        payable(msg.sender).send((offer.price * 975) / 1000);
        payable(_owner_of).send((offer.price * 25) / 1000);
        IMetaUnitTracker(_meta_unit_tracker_address).track(msg.sender, offer.price);
        _offers[uid_].finished = true;
        emit offerResolved(uid_);
    }
}