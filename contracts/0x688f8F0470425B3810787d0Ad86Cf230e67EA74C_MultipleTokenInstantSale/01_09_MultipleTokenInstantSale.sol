// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IMultipleToken} from "../token/IMultipleToken.sol";
import {IMetaUnitTracker} from "../../MetaUnit/Tracker/IMetaUnitTracker.sol";
import {Pausable} from "../../../Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {IFeeStorage} from "../../Collections/FeeStorage/IFeeStorage.sol";


/**
 * @author MetaPlayerOne DAO
 * @title MultipleTokenInstantSale
 */
contract MultipleTokenInstantSale is Pausable, ReentrancyGuard {
    struct Item { uint256 uid; address token_address; uint256 token_id; uint256 amount; uint256 sold; address owner_of; uint256 price; bool is_canceled; }
    Item[] private _items;
    mapping(address => mapping(uint256 => bool)) private _active_items;
    address private _meta_unit_tracker_address;
    address private _creator_fee_storage;

    constructor(address owner_of_, address meta_unit_tracker_address_, address creator_fee_storage_) Pausable(owner_of_) {
        _meta_unit_tracker_address = meta_unit_tracker_address_;
        _creator_fee_storage = creator_fee_storage_;
    }

   
    event itemSold(uint256 uid, uint256 amount, address buyer);
    event itemAdded(uint256 uid, address token_address, uint256 token_id, uint256 amount, uint256 sold, address owner_of, uint256 price);
    event itemRevoked(uint256 uid);
    event itemEdited(uint256 uid, uint256 value);
    
    /**
     * @dev allows you to put the ERC1155 token up for sale.
     * @param token_address address of token you pushes to market.
     * @param token_id id of token you pushes to market. 
     * @param price the minimum price for which a token can be bought.
     * @param amount amount of ERC1155 tokens.
     */
    function sale(address token_address, uint256 token_id, uint256 price, uint256 amount) public notPaused nonReentrant {
        IERC1155 token = IERC1155(token_address);
        require(token.balanceOf(msg.sender, token_id) >= amount, "You are not an owner");
        require(token.isApprovedForAll(msg.sender, address(this)), "Token is not approved to contact");
        uint256 newItemId = _items.length;
        _items.push(Item(newItemId, token_address, token_id, amount, 0, msg.sender, price, false));
        emit itemAdded(newItemId, token_address, token_id, amount, 0, msg.sender, price);
    }

    /**
     * @dev allows you to buy tokens.
     * @param uid unique order to be resolved.
     */
    function buy(uint256 uid, uint256 amount) public payable notPaused nonReentrant {
        Item memory item = _items[uid];
        uint256 total_price = item.price * amount;
        require(total_price <= msg.value, "Not enough funds send");
        require(msg.sender != item.owner_of, "You are an owner");
        require(item.sold + amount <= item.amount, "Limit exceeded");
        uint256 creator_fee_total = 0;
        address royalty_fee_receiver = address(0);
        uint256 royalty_fee = 0;
        try IFeeStorage(_creator_fee_storage).feeInfo(item.token_address, total_price) returns (address[] memory creator_fee_receiver_, uint256[] memory creator_fee_, uint256 total_) {
            for (uint256 i = 0; i < creator_fee_receiver_.length; i ++) {
                payable(creator_fee_receiver_[i]).send(creator_fee_[i]);
            }
            creator_fee_total = total_;
        } catch {}
        try IERC2981(item.token_address).royaltyInfo(item.token_id, item.price) returns (address royalty_fee_receiver_, uint256 royalty_fee_) {
            royalty_fee_receiver = royalty_fee_receiver_;
            royalty_fee = royalty_fee_;
        } catch {}
        uint256 project_fee = (total_price * 25) / 1000;
        if (royalty_fee_receiver != address(0)) payable(royalty_fee_receiver).send(royalty_fee);
        payable(_owner_of).send(project_fee);
        payable(item.owner_of).send(msg.value - creator_fee_total - royalty_fee - project_fee);
        IMetaUnitTracker(_meta_unit_tracker_address).track(msg.sender, total_price);
        IERC1155(item.token_address).safeTransferFrom(item.owner_of, msg.sender, item.token_id, amount, "");
        _items[uid].sold += amount;
        emit itemSold(uid, amount, msg.sender);
    }

    function revoke(uint256 uid) public nonReentrant {
        Item memory item = _items[uid];
        require(msg.sender == item.owner_of, "You are not an owner");
        require(_active_items[item.token_address][item.token_id], "Order does not exist");
        require(item.sold != item.amount, "Limit exceeded");
        _active_items[item.token_address][item.token_id] = false;
        _items[uid].is_canceled = true;
        emit itemRevoked(uid);
    }

    function edit(uint256 uid, uint256 value) public nonReentrant {
        Item memory item = _items[uid];
        require(msg.sender == item.owner_of, "You are not an owner");
        require(_active_items[item.token_address][item.token_id], "Order does not exist");
        require(!item.is_canceled, "Order has been canceled");
        require(item.sold != item.amount, "Limit exceeded");
        _items[uid].price = value;
        emit itemEdited(uid, value);
    }
}