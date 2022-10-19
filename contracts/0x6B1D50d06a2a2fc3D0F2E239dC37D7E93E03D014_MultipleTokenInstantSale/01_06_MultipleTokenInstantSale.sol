// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IMultipleToken} from "../token/IMultipleToken.sol";
import {IMetaUnitTracker} from "../../MetaUnit/Tracker/IMetaUnitTracker.sol";
import {Pausable} from "../../../Pausable.sol";

/**
 * @author MetaPlayerOne DAO
 * @title SingleTokenInstantSale
 * @notice Manages single ERC1155 token sales on MetaPlayerOne. 
 */
contract MultipleTokenInstantSale is Pausable {
    struct Item { uint256 uid; address token_address; uint256 token_id; uint256 amount; uint256 sold; address owner_of; uint256 price; bool is_canceled; }
    Item[] private _items;
    mapping(address => mapping(uint256 => bool)) private _active_items;
    address private _meta_unit_tracker_address;
    mapping(address => bool) private _royalty_receivers;

    /**
     * @dev setup metaunit address and owner of contract.
     */
    constructor(address owner_of_, address meta_unit_tracker_address_, address[] memory platform_token_addresses_) Pausable(owner_of_) {
        _meta_unit_tracker_address = meta_unit_tracker_address_;
        for (uint256 i = 0; i < platform_token_addresses_.length; i++) {
            _royalty_receivers[platform_token_addresses_[i]] = true;
        }
    }

    /**
     * @dev emits when new ERC1155 pushes to market.
     */
    event itemSold(uint256 uid, uint256 amount, address buyer);
    
    /**
     * @dev emits when order resolves
     */
    event itemAdded(uint256 uid, address token_address, uint256 token_id, uint256 amount, uint256 sold, address owner_of, uint256 price);

    /**
     * @dev emits when order revokes.
     */
    event itemRevoked(uint256 uid);

    /**
     * @dev emits when order edits.
     */
    event itemEdited(uint256 uid, uint256 value);
    /**
     * @dev allows you to put the ERC1155 token up for sale.
     * @param token_address address of token you pushes to market.
     * @param token_id id of token you pushes to market. 
     * @param price the minimum price for which a token can be bought.
     * @param amount amount of ERC1155 tokens.
     */
    function sale(address token_address, uint256 token_id, uint256 price, uint256 amount) public notPaused {
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
    function buy(uint256 uid, uint256 amount) public payable notPaused {
        Item memory item = _items[uid];
        require(item.price * amount <= msg.value, "Not enough funds send");
        require(msg.sender != item.owner_of, "You are an owner");
        require(item.sold + amount <= item.amount, "Limit exceeded");
        uint256 summ = 0;
        if (_royalty_receivers[item.token_address]) {
            IMultipleToken token = IMultipleToken(item.token_address);
            uint256 royalty = token.getRoyalty(item.token_id) * 10;
            address creator = token.getCreator(item.token_id);
            payable(creator).transfer((item.price * amount * royalty) / 1000);
            summ += royalty;
        }
        payable(_owner_of).transfer((item.price * amount * 25) / 1000);
        summ += 25;
        payable(item.owner_of).transfer(msg.value - ((item.price * amount * summ) / 1000));
        IMetaUnitTracker(_meta_unit_tracker_address).track(msg.sender, item.price * amount);
        IERC1155(item.token_address).safeTransferFrom(item.owner_of, msg.sender, item.token_id, amount, "");
        _items[uid].sold += amount;
        emit itemSold(uid, amount, msg.sender);
    }

    function revoke(uint256 uid) public {
        Item memory item = _items[uid];
        require(msg.sender == item.owner_of, "You are not an owner");
        require(_active_items[item.token_address][item.token_id], "Order does not exist");
        require(item.sold != item.amount, "Limit exceeded");
        _active_items[item.token_address][item.token_id] = false;
        _items[uid].is_canceled = true;
        emit itemRevoked(uid);
    }

    function edit(uint256 uid, uint256 value) public {
        Item memory item = _items[uid];
        require(msg.sender == item.owner_of, "You are not an owner");
        require(_active_items[item.token_address][item.token_id], "Order does not exist");
        require(!item.is_canceled, "Order has been canceled");
        require(item.sold != item.amount, "Limit exceeded");
        _active_items[item.token_address][item.token_id] = false;
        _items[uid].price = value;
        emit itemEdited(uid, value);
    }

    function update(address[] memory addresses) public {
        require(_owner_of == msg.sender, "Permission denied");
        for (uint256 i = 0; i < addresses.length; i++) {
            _royalty_receivers[addresses[i]] = true;
        }
    }
}