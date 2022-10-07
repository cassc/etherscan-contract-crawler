// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ISingleToken} from "../token/ISingleToken.sol";
import {IMetaUnitTracker} from "../../MetaUnit/Tracker/IMetaUnitTracker.sol";
import {Pausable} from "../../../Pausable.sol";

/**
 * @author MetaPlayerOne DAO
 * @title SingleTokenInstantSale
 * @notice Manages single ERC721 token sales on MetaPlayerOne. 
 */
contract SingleTokenInstantSale is Pausable {
    struct Item { uint256 uid; address token_address; uint256 token_id; address owner_of; uint256 price; bool is_sold; }
    
    Item[] private _items;
    mapping(address => mapping(uint256 => bool)) private _active_items;

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
     * @dev emits when new ERC721 pushes to market.
     */
    event itemAdded(uint256 uid, address token_address, uint256 token_id, uint256 price, address owner_of, bool is_sold);

    /**
     * @dev emits when order resolves
     */
    event itemSold(uint256 uid, address buyer);

    /**
     * @dev allows you to put the ERC721 token up for sale.
     * @param token_address address of token you pushes to market.
     * @param token_id id of token you pushes to market. 
     * @param price the minimum price for which a token can be bought.
     */
    function sale(address token_address, uint256 token_id, uint256 price) public notPaused {
        require(!_active_items[token_address][token_id], "Item is already on sale");
        require(IERC721(token_address).getApproved(token_id) == address(this), "Token is not approved to this contract");
        uint256 newItemId = _items.length;
        _items.push(Item(newItemId, token_address, token_id, msg.sender, price, false));
        _active_items[token_address][token_id] = true;
        emit itemAdded(newItemId, token_address, token_id, price, msg.sender, false);
    }

     /**
     * @dev allows you to buy tokens.
     * @param uid unique order to be resolved.
     */
    function buy(uint256 uid) public payable notPaused {
        Item memory item = _items[uid];
        require(_active_items[item.token_address][item.token_id], "Order does not exist");
        require(IERC721(item.token_address).getApproved(item.token_id) == address(this), "Token is not approved to this contract");
        require(msg.value >= item.price, "Not enough funds send");
        require(!item.is_sold, "Order has been resolved");
        uint256 summ = 0;
        if (_royalty_receivers[item.token_address]) {
            ISingleToken token = ISingleToken(item.token_address);
            uint256 royalty = token.getRoyalty(item.token_id) * 10;
            address creator = token.getCreator(item.token_id);
            payable(creator).transfer((item.price * royalty) / 1000);
            summ += royalty;
        }
        payable(_owner_of).transfer((item.price * 25) / 1000);
        summ += 25;
        payable(item.owner_of).transfer(msg.value - ((item.price * summ) / 1000));
        IMetaUnitTracker(_meta_unit_tracker_address).track(item.owner_of, item.price);
        IERC721(item.token_address).safeTransferFrom(item.owner_of, msg.sender, item.token_id);
        _items[uid].is_sold = true;
        _active_items[item.token_address][item.token_id] = false;
        emit itemSold(uid, msg.sender);
    }

    function update(address[] memory addresses) public {
        require(msg.sender == _owner_of || msg.sender == _selective_factory_address || msg.sender == _generative_factory_address, "Permission denied");
        for (uint256 i = 0; i < addresses.length; i++) {
            _royalty_receivers[addresses[i]] = true;
        }
    }
}