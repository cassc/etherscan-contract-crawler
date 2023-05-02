// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/IStoreHandler.sol";

/**
 * >>> Join the Resistance <<<
 * >>>   https://nfa.gg/   <<<
 * @title   NonFungible Arcade Store
 * @notice  Flexibly purchase or redeem signed messages to get onchain and offchain items
 * @author  BowTiedPickle
 * Version 1.0.0
 */
contract ArcadeStore is AccessControl, Pausable {
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    bytes32 public constant ITEM_MANAGER_ROLE = keccak256("ITEM_MANAGER_ROLE");

    struct ItemData {
        address token; // ERC-20 token used for payment
        uint256 price; // Price in units of token
        IStoreHandler handler; // Store handler contract to notify on purchase or redemption
    }

    /// @notice Map an item ID to its information
    mapping(bytes32 => ItemData) public items;

    /// @notice Map signer nonces to consumed
    mapping(uint256 => bool) public consumedNonces;

    /// @notice The address allowed to sign messages for redeeming items for free
    address public signer;

    /// @notice The address receiving all funds from purchases
    address public treasury;

    /**
     * @param _admin        Admin role address
     * @param _manager      Item manager address
     * @param _signer       Signer address
     * @param _treasury     Treasury address
     */
    constructor(address _admin, address _manager, address _signer, address _treasury) {
        require(
            _admin != address(0) && _manager != address(0) && _signer != address(0) && _treasury != address(0),
            "ArcadeStore: addresses cannot be the zero address"
        );
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(ITEM_MANAGER_ROLE, _manager);
        signer = _signer;
        treasury = _treasury;
    }

    // ---------- Public Functions ----------

    /**
     * @notice  Purchase an item using ERC-20 tokens
     * @dev     User must have approved this contract for the purchase price first
     * @dev     Effects may be offchain, onchain, or both, depending on the item
     * @param   _itemId     Item to purchase
     * @param   _quantity   Number of this item to purchase
     */
    function purchase(bytes32 _itemId, uint256 _quantity) public whenNotPaused {
        require(_quantity > 0, "ArcadeStore: quantity must be greater than zero");

        ItemData memory item = items[_itemId];
        require(item.token != address(0), "ArcadeStore: item does not exist");

        IERC20(item.token).safeTransferFrom(msg.sender, treasury, item.price * _quantity);

        if (address(item.handler) != address(0)) {
            item.handler.notifyPurchase(_itemId, msg.sender, _quantity);
        }

        emit ItemPurchased(_itemId, msg.sender, _quantity);
    }

    /**
     * @notice  Redeem a signed message to obtain an item
     * @dev     Effects may be offchain, onchain, or both, depending on the item
     * @param   _itemId     Item to purchase
     * @param   _nonce      Signer nonce
     * @param   _quantity   Number of this item to purchase
     * @param   _signature  Signed authorization message
     */
    function redeem(bytes32 _itemId, uint256 _nonce, uint256 _quantity, bytes memory _signature) public whenNotPaused {
        require(_quantity > 0, "ArcadeStore: quantity must be greater than zero");

        ItemData memory item = items[_itemId];
        require(item.token != address(0), "ArcadeStore: item does not exist");
        require(!consumedNonces[_nonce], "ArcadeStore: nonce already consumed");

        // Verify the signer's signature
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, _itemId, _nonce, _quantity)).toEthSignedMessageHash();
        address _signer = hash.recover(_signature);
        require(_signer == signer, "ArcadeStore: invalid signature");

        // Consume the _nonce
        consumedNonces[_nonce] = true;

        if (address(item.handler) != address(0)) {
            item.handler.notifyPurchase(_itemId, msg.sender, _quantity);
        }

        emit ItemRedeemed(_itemId, msg.sender, _quantity);
    }

    // ---------- Item Manager Functions ----------

    /**
     * @notice  Add an item
     * @param   _id         Item ID to add
     * @param   _token      ERC-20 token address
     * @param   _price      Item price in units of the payment token
     * @param   _handler    Onchain handler contract address
     */
    function addItem(bytes32 _id, address _token, uint256 _price, IStoreHandler _handler) public onlyRole(ITEM_MANAGER_ROLE) {
        require(_token != address(0), "ArcadeStore: token address cannot be the zero address");
        require(_price > 0, "ArcadeStore: price must be greater than zero");

        ItemData memory item = ItemData(_token, _price, _handler);
        emit NewItemData(_id, items[_id], item);
        items[_id] = item;
    }

    /**
     * @notice  Add multiple items
     * @param   _ids    Item IDs to add
     * @param   _items  Item data to add
     */
    function addItems(bytes32[] memory _ids, ItemData[] memory _items) public onlyRole(ITEM_MANAGER_ROLE) {
        require(_ids.length == _items.length, "ArcadeStore: input arrays must have the same length");

        for (uint256 i; i < _items.length; ) {
            bytes32 itemId = _ids[i];
            ItemData memory item = _items[i];

            require(item.token != address(0), "ArcadeStore: token address cannot be the zero address");
            require(item.price > 0, "ArcadeStore: price must be greater than zero");

            emit NewItemData(itemId, items[itemId], item);
            items[itemId] = item;
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice  Remove an item
     * @param   _id     Item ID to remove
     */
    function removeItem(bytes32 _id) public onlyRole(ITEM_MANAGER_ROLE) {
        emit NewItemData(_id, items[_id], ItemData(address(0), 0, IStoreHandler(address(0))));
        delete items[_id];
    }

    /**
     * @notice  Remove multiple items
     * @param   _ids    Item IDs to remove
     */
    function removeItems(bytes32[] memory _ids) public onlyRole(ITEM_MANAGER_ROLE) {
        for (uint256 i; i < _ids.length; ) {
            bytes32 itemId = _ids[i];

            emit NewItemData(itemId, items[itemId], ItemData(address(0), 0, IStoreHandler(address(0))));
            delete items[itemId];
            unchecked {
                ++i;
            }
        }
    }

    // ---------- Admin Functions ----------

    /**
     * @notice  Set a new signer address
     * @param   _newSigner  New signer address
     */
    function setSigner(address _newSigner) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_newSigner != address(0), "ArcadeStore: signer address cannot be the zero address");
        emit NewSigner(signer, _newSigner);
        signer = _newSigner;
    }

    /**
     * @notice  Set a new treasury address
     * @param   _newTreasury    New treasury address
     */
    function setTreasury(address _newTreasury) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_newTreasury != address(0), "ArcadeStore: treasury address cannot be the zero address");
        emit NewTreasury(treasury, _newTreasury);
        treasury = _newTreasury;
    }

    /**
     * @notice  Set the minting pause status
     * @param   _status     True to pause, false to unpause
     */
    function setPaused(bool _status) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_status) {
            _pause();
        } else {
            _unpause();
        }
    }

    // ---------- Events ----------

    event ItemPurchased(bytes32 indexed itemId, address indexed buyer, uint256 quantity);
    event ItemRedeemed(bytes32 indexed itemId, address indexed redeemer, uint256 quantity);

    event NewSigner(address oldSigner, address newSigner);
    event NewTreasury(address oldTreasury, address newTreasury);
    event NewItemData(bytes32 indexed itemId, ItemData oldItemData, ItemData newItemData);
}