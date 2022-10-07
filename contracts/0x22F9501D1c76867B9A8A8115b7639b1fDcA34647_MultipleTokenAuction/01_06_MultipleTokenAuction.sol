// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IMetaUnitTracker} from "../../MetaUnit/Tracker/IMetaUnitTracker.sol";
import {IMultipleToken} from "../token/IMultipleToken.sol";
import {Pausable} from "../../../Pausable.sol";

/**
 * @author MetaPlayerOne DAO
 * @title MultipleTokenAuction
 * @notice Manages ERC1155 token auctions on MetaPlayerOne.
 */
contract MultipleTokenAuction is Pausable {
    struct Item { uint256 uid; address token_address; uint256 token_id; uint256 amount; address owner_of; address curator_address; uint256 curator_fee; uint256 start_price; bool approved; uint256 highest_bid; address highest_bidder; uint256 end_time; uint256 duration; }
    Item[] private _items;
    mapping(uint256 => bool) private _finished;
    address private _meta_unit_tracker_address;
    mapping(address => bool) private _royalty_receivers;

    /**
     * @dev setup metaunit tracker address and owner of contract.
     */
    constructor(address owner_of_, address meta_unit_tracker_address_, address[] memory platform_token_addresses_) Pausable(owner_of_) {
        _meta_unit_tracker_address = meta_unit_tracker_address_;
        for (uint256 i = 0; i < platform_token_addresses_.length; i++) {
            _royalty_receivers[platform_token_addresses_[i]] = true;
        }
    }

    /**
     * @dev emitted when an NFT is auctioned.
     */
    event itemAdded(uint256 uid, address token_address, uint256 token_id, uint256 amount, address owner_of, address curator_address, uint256 curator_fee, uint256 start_price, bool approved, uint256 highest_bid, address highest_bidder);

    /**
     * @dev emitted when an auction approved by curator.
     */
    event auctionApproved(uint256 uid, uint256 end_time);

    /**
     * @dev emitted when bid creates.
     */
    event bidCreated(uint256 uid, uint256 highest_bid, address highest_bidder);

    /**
     * @dev emitted when an auction resolved.
     */
    event itemSold(uint256 uid);

    /**
     * @dev allows us to sell for sale.
     * @param token_address address of the token to be auctioned.
     * @param token_id address of the token to be auctioned.
     * @param amount amount of ERC1155 token for sale.
     * @param curator_address address of user which should curate auction.
     * @param curator_fee percentage of auction highest bid value, which curator will receive after successfull curation.
     * @param start_price threshold of auction.
     * @param duration auction duration in seconds.
     */
    function sale(address token_address, uint256 token_id, uint256 amount, address curator_address, uint256 curator_fee, uint256 start_price, uint256 duration) public notPaused {
        IERC1155 token = IERC1155(token_address);
        require(token.isApprovedForAll(msg.sender, address(this)), "Token is not approved to contract");
        require(token.balanceOf(msg.sender, token_id) >= amount, "You are not an owner");
        uint256 newItemId = _items.length;
        _items.push(Item(newItemId, token_address, token_id, amount, msg.sender, curator_address, curator_fee, start_price, false, 0, address(0), 0, duration));
        emit itemAdded(newItemId, token_address, token_id, amount, msg.sender, curator_address, curator_fee, start_price, false, 0, address(0));
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
    function bid(uint256 uid) public payable notPaused {
        require(uid < _items.length && _items[uid].uid == uid, "Token does not exists");
        Item memory item = _items[uid];
        IERC1155 token = IERC1155(item.token_address);
        require(block.timestamp <= item.end_time, "Auction has been finished");
        require(token.balanceOf(item.owner_of, item.token_id) > item.amount, "Token is already sold");
        require(token.isApprovedForAll(item.owner_of, address(this)), "Token is not approved");
        require(msg.value > item.start_price, "Bid is lower than start price");
        require(msg.value > item.highest_bid, "Bid is lower than previous one");
        require(item.approved, "Auction is not approved with curator");
        require(item.owner_of != msg.sender, "You are an owner");
        require(item.curator_address != msg.sender, "You are curator");
        if (item.highest_bidder != address(0)) {
            payable(item.highest_bidder).transfer(item.highest_bid);
        }
        _items[uid].highest_bid = msg.value;
        _items[uid].highest_bidder = msg.sender;
        emit bidCreated(uid, _items[uid].highest_bid, _items[uid].highest_bidder);
    }

    /**
     * @dev allows curator to resolve auction.
     * @param uid unique id of auction order.
     */
    function resolve(uint256 uid) public notPaused {
        require(uid < _items.length && _items[uid].uid == uid, "Order does not exists");
        Item memory item = _items[uid];
        IERC1155 token = IERC1155(item.token_address);
        require(block.timestamp > item.end_time, "Auction is not finished");
        require(item.curator_address == msg.sender, "You are not curator");
        require(item.approved, "Is not curator approved");
        require(token.isApprovedForAll(item.owner_of, address(this)), "Token is not approved");
        require(!_finished[uid], "Is resolved");
        if (item.highest_bidder != address(0)) {
            uint256 summ = 0;
            if (_royalty_receivers[item.token_address]) {
                IMultipleToken multiple_token = IMultipleToken(item.token_address);
                uint256 royalty = multiple_token.getRoyalty(item.token_id);
                address creator = multiple_token.getCreator(item.token_id);
                payable(creator).transfer((item.highest_bid * royalty) / 1000);
                summ += royalty;
            }
            payable(_owner_of).transfer((item.highest_bid * 25) / 1000);
            summ += 25;
            payable(item.curator_address).transfer((item.highest_bid * item.curator_fee) / 1000);
            summ += item.curator_fee;
            payable(item.owner_of).transfer((item.highest_bid - ((item.highest_bid * summ) / 1000)));
            IMetaUnitTracker(_meta_unit_tracker_address).track(msg.sender, item.highest_bid);
            token.safeTransferFrom(item.owner_of, item.highest_bidder, item.token_id, item.amount, "");
        }
        _finished[uid] = true;
        emit itemSold(uid);
    }

    function update(address[] memory addresses) public {
        require(msg.sender == _owner_of, "Permission denied");
        for (uint256 i = 0; i < addresses.length; i++) {
            _royalty_receivers[addresses[i]] = true;
        }
    }
}