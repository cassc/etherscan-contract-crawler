// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@paperxyz/contracts/keyManager/IPaperKeyManager.sol";
import {DefaultOperatorFilterer} from "./opensea/DefaultOperatorFilterer.sol";

contract AAPEHotSauce is ERC1155, Ownable, PaymentSplitter, DefaultOperatorFilterer  {

    using Strings for uint256;

    // collection: 1 = ape, 2 = queen
    struct Item {
        uint16 sauceType;
        uint16 tokenId;
        uint8 collection;
    }

    mapping(address => uint16) public hasMinted;
    mapping(uint256 => address) public orders;
    mapping(uint256 => Item[]) public items;
    mapping(uint256 => uint256) public price;
    string public name;
    string public symbol;
    string private baseURI;
    bool public saleIsActive;
    uint256 public maxSupply;
    uint256 public totalMinted;
    uint256[] sauceIds;
    uint256 orderId;
    IPaperKeyManager paperKeyManager;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        address[] memory _payees,
        uint256[] memory _shares,
        address _owner,
        address _paperAddress
    ) ERC1155(_uri) PaymentSplitter(_payees, _shares) {
        name = _name;
        symbol = _symbol;
        baseURI = _uri;
        paperKeyManager = IPaperKeyManager(_paperAddress);
        transferOwnership(_owner);
    }

    modifier onlyPaper(bytes32 _hash, bytes32 _nonce, bytes calldata _signature) {
        bool success = paperKeyManager.verify(_hash, _nonce, _signature);
        require(success, "Failed to verify signature");
        _;
    }

    function checkClaimEligibility(address _address, uint256 _quantity, uint256 _id) public view returns (string memory) {
        if (totalMinted + _quantity > maxSupply) return "NOT_ENOUGH_SUPPLY";
        if (!saleIsActive) return "NOT_LIVE";
        return "";
    }

    function registerPaperKey(address _paperKey) external onlyOwner {
        require(paperKeyManager.register(_paperKey), "Error registering key");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function uri(uint256 _id) public view override returns (string memory) {
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, _id.toString()))
                : baseURI;
    }

    function setURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setMaxSupply(uint256 _supply) public onlyOwner {
        maxSupply = _supply;
    }

    function updateSaleState(
        bool _saleIsActive
    ) public onlyOwner {
        saleIsActive = _saleIsActive;
    }

    function updateSauce(
        uint256 _id,
        uint72 _price
    ) public onlyOwner {
        require(price[_id] > 0, "Invalid type");
        price[_id] = _price;
    }

    function createSauce(
        uint256 _id,
        uint72 _price
    ) public onlyOwner {
        require(price[_id] == 0, "Token exists");
        price[_id] = _price;
        sauceIds.push(_id);
    }

    function saucesOf(address _address) public view returns (uint256[] memory, uint256[] memory) {
        uint256[] memory _balances = new uint256[](sauceIds.length);
        for (uint16 i = 0; i < sauceIds.length; i++) {
           _balances[i] = balanceOf(_address, sauceIds[i]);
        }
        return (sauceIds, _balances);
    }

    function ordersOf(address _address) public view returns (uint256[] memory) {
        uint256 _orderCount;
        for (uint16 i = 1; i <= orderId; i++) {
            if (orders[i] == _address) {
                _orderCount++;
            }
        }
        uint256[] memory _orders = new uint256[](_orderCount);
        uint256 index;
        for (uint16 i = 1; i <= orderId; i++) {
            if (orders[i] == _address) {
                _orders[index++] = i;
            }
        }
        return _orders;
    }

    function getOrder(uint256 _orderId) public view returns (Item[] memory) {
        return items[_orderId];
    }

    function mint(
        uint256[] memory _ids,
        uint256[] memory _quantities
    ) public payable {
        require(_quantities.length > 0, "Invalid quantity");
        require(_ids.length == _quantities.length, "Invalid parameters");
        require(saleIsActive, "Sale inactive");
        uint256 _price;
        uint256 _quantity;
        for (uint16 i = 0; i < _ids.length; i++) {
            _price += price[_ids[i]] * _quantities[i];
            _quantity += _quantities[i];
        }
        require(totalMinted + _quantity <= maxSupply, "Insufficient supply");
        require(_price <= msg.value, "ETH incorrect");
        totalMinted += _quantity;
        _mintBatch(msg.sender, _ids, _quantities, "");
    }

    function paper(address _address, uint256 _quantity, uint256 _id, bytes32 _nonce, bytes calldata _signature) public payable 
        onlyPaper(keccak256(abi.encode(_address, _quantity, _id)), _nonce, _signature)
    {
        require(saleIsActive, "Sale inactive");
        require(totalMinted + _quantity <= maxSupply, "Insufficient supply");
        require(price[_id] * _quantity <= msg.value, "ETH incorrect");
        totalMinted += _quantity;
        _mint(_address, _id, _quantity, "");
    }

    function order(
        uint256[] memory _ids,
        uint256[] memory _quantities,
        Item[] memory _items
    ) public {
        require(_quantities.length > 0, "Invalid parameters");
        require(_ids.length == _quantities.length, "Invalid parameters");
        uint256 _quantity;
        for (uint16 i = 0; i < _ids.length; i++) {
            require(_quantities[i] > 0, "Quantity is zero");
            require(price[_ids[i]] > 0, "Invalid sauce");
            require(balanceOf(msg.sender, _ids[i]) >= _quantities[i], "Insufficient balance");
            for (uint16 j = 0; j < _items.length; j++) {
                if (_ids[i] == _items[j].sauceType) {
                    _quantity++;
                }
            }
            require(_quantities[i] == _quantity, "Invalid quantity");
            _quantity = 0;
        }
        orderId++;
        orders[orderId] = msg.sender;
        for (uint16 i = 0; i < _items.length; i++) {
            items[orderId].push(_items[i]);
        }
        _burnBatch(msg.sender, _ids, _quantities);
    }

    function reserve(uint256 _id, address _address, uint16 _quantity) public onlyOwner {
        require(totalMinted + _quantity <= maxSupply, "Insufficient supply");
        totalMinted += _quantity;
        _mint(_address, _id, _quantity, "");
    }
}