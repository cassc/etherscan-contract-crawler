// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ISingleToken} from "../token/ISingleToken.sol";
import {IMetaUnitTracker} from "../../MetaUnit/Tracker/IMetaUnitTracker.sol";
import {Pausable} from "../../../Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {IFeeStorage} from "../../Collections/FeeStorage/IFeeStorage.sol";

/**
 * @author MetaPlayerOne DAO
 * @title SingleTokenInstantSale
 */
contract SingleTokenInstantSale is Pausable, ReentrancyGuard {
    struct Item { uint256 uid; address token_address; uint256 token_id; address owner_of; uint256 price; bool is_sold; bool is_canceled; }
    
    Item[] private _items;
    mapping(address => mapping(uint256 => mapping(address => bool))) private _active_items;

    address private _meta_unit_tracker_address;
    address private _selective_factory_address;
    address private _generative_factory_address;
    address private _creator_fee_storage;
    
    constructor(address owner_of_, address meta_unit_tracker_address_, address creator_fee_storage_) Pausable(owner_of_) {
        _meta_unit_tracker_address = meta_unit_tracker_address_;
        _creator_fee_storage = creator_fee_storage_;
    }

    event itemAdded(uint256 uid, address token_address, uint256 token_id, uint256 price, address owner_of, bool is_sold);
    event itemSold(uint256 uid, address buyer);
    event itemRevoked(uint256 uid);
    event itemEdited(uint256 uid, uint256 value);

    function sale(address token_address, uint256 token_id, uint256 price) public notPaused nonReentrant {
        require(!_active_items[token_address][token_id][msg.sender], "Item is already on sale");
        require(IERC721(token_address).getApproved(token_id) == address(this), "Token is not approved to this contract");
        uint256 newItemId = _items.length;
        _items.push(Item(newItemId, token_address, token_id, msg.sender, price, false, false));
        _active_items[token_address][token_id][msg.sender] = true;
        emit itemAdded(newItemId, token_address, token_id, price, msg.sender, false);
    }

    function buy(uint256 uid) public payable notPaused nonReentrant {
        Item memory item = _items[uid];
        require(!item.is_canceled, "Order has been canceled");
        require(_active_items[item.token_address][item.token_id][item.owner_of], "Order does not exist");
        require(IERC721(item.token_address).getApproved(item.token_id) == address(this), "Token is not approved to this contract");
        require(msg.value >= item.price, "Not enough funds send");
        require(!item.is_sold, "Order has been resolved");
        uint256 creator_fee_total = 0;
        address royalty_fee_receiver = address(0);
        uint256 royalty_fee = 0;
        try IFeeStorage(_creator_fee_storage).feeInfo(item.token_address, item.price) returns (address[] memory creator_fee_receiver_, uint256[] memory creator_fee_, uint256 total_) {
            for (uint256 i = 0; i < creator_fee_receiver_.length; i ++) {
                payable(creator_fee_receiver_[i]).send(creator_fee_[i]);
            }
            creator_fee_total = total_;
        } catch {}
        try IERC2981(item.token_address).royaltyInfo(item.token_id, item.price) returns (address royalty_fee_receiver_, uint256 royalty_fee_) {
            royalty_fee_receiver = royalty_fee_receiver_;
            royalty_fee = royalty_fee_;
        } catch {}
        uint256 project_fee = (item.price * 25) / 1000;
        if (royalty_fee_receiver != address(0)) payable(royalty_fee_receiver).send(royalty_fee);
        payable(_owner_of).send(project_fee);
        payable(item.owner_of).send(msg.value - creator_fee_total - royalty_fee - project_fee);
        IMetaUnitTracker(_meta_unit_tracker_address).track(item.owner_of, item.price);
        IERC721(item.token_address).safeTransferFrom(item.owner_of, msg.sender, item.token_id);
        _items[uid].is_sold = true;
        _active_items[item.token_address][item.token_id][item.owner_of] = false;
        emit itemSold(uid, msg.sender);
    }

    function revoke(uint256 uid) public nonReentrant {
        Item memory item = _items[uid];
        require(msg.sender == item.owner_of, "You are not an owner");
        require(_active_items[item.token_address][item.token_id][msg.sender], "Order does not exist");
        require(!item.is_sold, "Order has been resolved");
        _active_items[item.token_address][item.token_id][msg.sender] = false;
        _items[uid].is_canceled = true;
        emit itemRevoked(uid);
    }

    function edit(uint256 uid, uint256 value) public nonReentrant {
        Item memory item = _items[uid];
        require(msg.sender == item.owner_of, "You are not an owner");
        require(_active_items[item.token_address][item.token_id][msg.sender], "Order does not exist");
        require(!item.is_canceled, "Order has been canceled");
        require(!item.is_sold, "Order has been resolved");
        _items[uid].price = value;
        emit itemEdited(uid, value);
    }

    function check(uint256 uid_) public view {
        Item memory item = _items[uid_];
        require(IERC721(item.token_address).ownerOf(item.token_id) == item.owner_of, "Not valid owner");
        require(IERC721(item.token_address).getApproved(item.token_id) == address(this), "Token is not approved");
    }
}