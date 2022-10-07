// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ISingleToken} from "../token/ISingleToken.sol";
import {IMetaUnitTracker} from "../../MetaUnit/Tracker/IMetaUnitTracker.sol";
import {Pausable} from "../../../Pausable.sol";

/**
 * @author MetaPlayerOne DAO
 * @title SingleTokenAuction
 * @notice Manages ERC721 token auctions on MetaPlayerOne.
 */
contract SingleTokenAuction is Pausable {
    struct Item { uint256 uid; address token_address; uint256 token_id; address owner_of; address curator_address; uint256 curator_fee; uint256 start_price; bool approved; uint256 highest_bid; address highest_bidder; uint256 end_time; uint256 duration; }

    Item[] private _items;
    mapping(address => mapping(uint256 => bool)) private _active_items;
    mapping(uint256 => bool) private _finished;

    address private _meta_unit_tracker_address;
    address private _selective_factory_address;
    address private _generative_factory_address;
    mapping(address => bool) private _royalty_receivers;

    /**
     * @dev setup metaunit address and owner of contract.
     */
    constructor(address owner_of_, address meta_unit_tracker_address_, address selective_factory_address_, address generative_factory_address_, address[] memory platform_token_addresses_) Pausable(owner_of_) {
        _meta_unit_tracker_address = meta_unit_tracker_address_;
        _selective_factory_address = selective_factory_address_;
        _generative_factory_address = generative_factory_address_;
        for (uint256 i = 0; i < platform_token_addresses_.length; i++) {
            _royalty_receivers[platform_token_addresses_[i]] = true;
        }
    }
   
    /**
     * @dev emitted when an NFT is auctioned.
     */
    event itemAdded(uint256 uid, address token_address, uint256 token_id, address owner_of, address curator_address, uint256 curator_fee, uint256 start_price, bool approved, uint256 highest_bid, address highest_bidder,uint256 end_time);

    /**
     * @dev emitted when an auction approved by curator.
     */
    event auctionApproved(uint256 uid, uint256 end_time);

    /**
     * @dev emitted when bid creates.
     */
    event bidAdded(uint256 uid, uint256 highest_bid, address highest_bidder);

    /**
     * @dev emitted when an auction resolved.
     */
    event itemResolved(uint256 uid);

    /**
     * @dev allows us to sell for sale.
     * @param token_address address of the token to be auctioned.
     * @param token_id address of the token to be auctioned.
     * @param curator_address address of user which should curate auction.
     * @param curator_fee percentage of auction highest bid value, which curator will receive after successfull curation.
     * @param start_price threshold of auction.
     * @param duration auction duration in seconds.
     */
    function sale(address token_address, uint256 token_id, address curator_address, uint256 curator_fee, uint256 start_price, uint256 duration) public notPaused {
        require(IERC721(token_address).ownerOf(token_id) == msg.sender, "You are not an owner");
        require(IERC721(token_address).getApproved(token_id) == address(this), "Token is not approved to contract");
        require(!_active_items[token_address][token_id], "Item is already on sale");
        uint256 newItemId = _items.length;
        _items.push(Item(newItemId, token_address, token_id, msg.sender, curator_address, curator_fee, start_price, false, 0, address(0), 0, duration));
        _active_items[token_address][token_id] == true;
        emit itemAdded(newItemId, token_address, token_id, msg.sender, curator_address, curator_fee, start_price, false, 0, address(0), duration);
        if (curator_address == msg.sender) {
            setCuratorApproval(newItemId);
        }
    }

    /**
     * @dev allows the curator of the auction to put approval on the auction.
     * @param uid unique id of auction order.
     */
    function setCuratorApproval(uint256 uid) public notPaused {
        require(uid < _items.length && _items[uid].uid == uid, "Token does not exists");
        Item memory item = _items[uid];
        require(!item.approved, "Auction is already approved");
        require(item.curator_address == msg.sender, "You are not curator");
        _items[uid].approved = true;
        _items[uid].end_time = block.timestamp + item.duration;
        emit auctionApproved(uid, _items[uid].end_time);
    }

    /**
     * @dev allows you to make bid on the auction.
     * @param uid unique id of auction order.
     */
    function bid(uint256 uid) public payable {
        require(uid < _items.length && _items[uid].uid == uid, "Order does not exists");
        Item memory item = _items[uid];
        IERC721 token = IERC721(item.token_address);
        require(block.timestamp <= item.end_time, "Auction has been finished");
        require(token.getApproved(item.token_id) == address(this), "Token is not approved to contract");
        require(token.ownerOf(item.token_id) == item.owner_of, "Token is already sold");
        require(item.approved, "Auction is not approved");
        require(msg.value > item.start_price, "Bid is lower than start price");
        require(msg.value > item.highest_bid, "Bid is lower than previous one");
        require(item.owner_of != msg.sender, "You are an owner of this auction");
        require(item.curator_address != msg.sender, "You are an curator of this auction");
        if (item.highest_bidder != address(0)) {
            payable(item.highest_bidder).transfer(item.highest_bid);
        }
        _items[uid].highest_bid = msg.value;
        _items[uid].highest_bidder = msg.sender;
        emit bidAdded(uid, _items[uid].highest_bid, _items[uid].highest_bidder);
    }

    /**
     * @dev allows curator to resolve auction.
     * @param uid unique id of auction order.
     */
    function resolve(uint256 uid) public notPaused {
        require(uid < _items.length && _items[uid].uid == uid, "Order does not exists");
        Item memory item = _items[uid];
        IERC721 token = IERC721(item.token_address);
        require(block.timestamp >= item.end_time, "Auction does not finish");
        require(item.curator_address == msg.sender, "You are not curator");
        require(item.approved, "Auction is not approved");
        require(token.getApproved(item.token_id) == address(this), "Token is not approved to contract");
        require(!_finished[uid], "Auction has been resolved");
        if (item.highest_bidder != address(0)) {
            uint256 summ = 0;
            if (_royalty_receivers[item.token_address]) {
                ISingleToken single_token = ISingleToken(item.token_address);
                uint256 royalty = single_token.getRoyalty(item.token_id);
                address creator = single_token.getCreator(item.token_id);
                payable(creator).transfer(((item.highest_bid * royalty) / 1000));
                summ += royalty;
            }
            payable(_owner_of).transfer((item.highest_bid * 25) / 1000);
            summ += 25;
            payable(item.curator_address).transfer((item.highest_bid * item.curator_fee) / 1000);
            summ += item.curator_fee;
            payable(item.owner_of).transfer((item.highest_bid - ((item.highest_bid * summ) / 1000)));
            IMetaUnitTracker(_meta_unit_tracker_address).track(item.owner_of, item.highest_bid);
            IERC721(item.token_address).safeTransferFrom(item.owner_of, item.highest_bidder, item.token_id);
        }
        _finished[uid] = true;
        _active_items[item.token_address][item.token_id] = false;
        emit itemResolved(uid);
    }

    function update(address[] memory addresses) public {
        require(msg.sender == _owner_of || _selective_factory_address == msg.sender || _generative_factory_address == msg.sender, "Permission denied");
        for (uint256 i = 0; i < addresses.length; i++) {
            _royalty_receivers[addresses[i]] = true;
        }
    }

}