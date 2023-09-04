// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC165, IERC165, ERC1155, ERC1155Pausable} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import {ERC1155Holder, ERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IItemExecutor} from "./IItemExecutor.sol";
import {IZombieTradingPost} from "./IZombieTradingPost.sol";

contract ZombieTradingPost is Ownable, ERC1155Pausable, ERC1155Holder {
    using Strings for uint256;

    address private antidoteInjector;

    string private baseURI;

    mapping(uint256 => IZombieTradingPost.ItemDefinition) public registeredItems;

    uint256[] public itemIds;

    event UpdateBaseURI(string uri);

    event UpdateInjector(address injector);

    event ItemAdded(uint256 itemId);

    event ItemDisabled(uint256 itemId);
    
    event ItemCostUpdated(uint256 oldCost, uint256 newCost);

    event ItemPurchased(address purchaser, uint256 itemId, uint256 amount);

    event ItemDestroyed(address destroyer, uint256 itemId, uint256 amount);

    constructor(string memory _baseURI) ERC1155(_baseURI) {
        baseURI = _baseURI;
    }

    function addItem(uint256 cost, uint256 _purchaseLimit, bool feoEnabled, bool autoEnable, bool mint) public onlyOwner {
        uint256 _itemId = itemIds.length;
        itemIds.push(_itemId);
        registeredItems[_itemId] = IZombieTradingPost.ItemDefinition({
            executor: address(0x0),
            feoEnabled: feoEnabled,
            purchased: 0,
            purchaseLimit: _purchaseLimit,
            cost: cost,
            enabled: autoEnable
        });

        if(mint) {
            _mint(address(this), _itemId, _purchaseLimit, "");
        }

        emit ItemAdded(_itemId);
    }

    function transferItems(uint256 itemId) external onlyOwner _itemRegistered(itemId) {
        safeTransferFrom(address(this), msg.sender, itemId, balanceOf(address(this), itemId), "");
    }

    function updateItemCost(uint256 itemId, uint256 cost) external onlyOwner _itemRegistered(itemId) {
        IZombieTradingPost.ItemDefinition storage definition = registeredItems[itemId];
        uint256 oldCost = definition.cost;
        definition.cost = cost;
        emit ItemCostUpdated(oldCost, cost);
    }

    function disableItem(uint256 itemId) external onlyOwner {
        registeredItems[itemId].enabled = false;
        emit ItemDisabled(itemId);
    }

    function getItemLength() external view returns (uint256 length) {
        length = itemIds.length;
    }

    function getItem(uint256 itemId) external view _itemRegistered(itemId) _itemEnabled(itemId) returns (IZombieTradingPost.ItemDefinition memory definition) {
        return registeredItems[itemId];
    }

    function getItems() external view returns (IZombieTradingPost.ItemDefinition[] memory definitions) {
        definitions = new IZombieTradingPost.ItemDefinition[](itemIds.length);
        for(uint256 index = 0; index<itemIds.length; index++) {
            definitions[index] = registeredItems[itemIds[index]];
        }
    }

    function destroyItem(uint256 itemId, uint256 amount) external _itemRegistered(itemId) whenNotPaused {
        _burn(msg.sender, itemId, amount);
        emit ItemDestroyed(msg.sender, itemId, amount);
    }

    function destroyItemFor(address owner, uint256 itemId, uint256 amount) external _itemRegistered(itemId) _onlyExecutor(itemId) whenNotPaused {
        _burn(owner, itemId, amount);
        emit ItemDestroyed(owner, itemId, amount);
    }

    function updateBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
        _setURI(_baseURI);
        emit UpdateBaseURI(baseURI);
    }

    function mintBatch(uint256[] memory ids, uint256[] memory amounts) external onlyOwner {
        _mintBatch(owner(), ids, amounts, "");
    }

    function mintBatchFor(uint256[] memory ids, uint256[] memory amounts, address to) external onlyOwner {
        _mintBatch(to, ids, amounts, "");
    }

    function uri(uint256 typeId)
        public
        view                
        override
        returns (string memory)
    {
        require(
            registeredItems[typeId].enabled,
            "URI requested for invalid item type"
        );
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, typeId.toString()))
                : baseURI;
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    modifier _itemRegistered(uint256 itemId) {
        require(itemIds.length > itemId, "item_non_existent");
        _;
    }

    modifier _itemEnabled(uint256 itemId) {
        require(registeredItems[itemId].enabled, "item_disabled");
        _;
    }

    modifier _onlyExecutor(uint256 tokenId) {
        IZombieTradingPost.ItemDefinition memory definition = registeredItems[tokenId];
        if(definition.executor != address(0x0)) {
            require(msg.sender == definition.executor, "sender_not_executor");
        }
        _;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC1155Receiver) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for(uint256 id = ids[0]; id<ids.length; id++) {
            IZombieTradingPost.ItemDefinition memory definition = registeredItems[id];
            if(definition.executor != address(0x0)) {
                IItemExecutor(definition.executor).executeOnTransfer(id);
            }
        }
    }

    function pause() external onlyOwner whenNotPaused {
        super._pause();
    }

    function unpause() external onlyOwner whenPaused {
        super._unpause();
    }
}