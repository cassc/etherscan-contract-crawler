// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RandomMarketPlace is Ownable {
    mapping(address => bool) controllers;
    address public token;
    address public vault;
    uint256 public totalItems = 0;
    bool public isPaused = false;
    mapping(uint256 => Item) public items;
    uint256[] public deletedIds;
    mapping(address => mapping(uint256 => NftItem)) public nftItems;
    NftItem[] public nftItemsArray;

    struct CollectionForSell {
        address collection;
        uint256[] nftIds;
    }

    struct NftItem {
        address seller;
        uint256 price;
        uint256 tokenId;
        address tokenCollection;
        bool isForSale;
    }

    struct Item {
        uint256 id;
        string name;
        uint256 price;
        address owner;
        bool purchased;
        string mongoId;
        bool exists;
    }

    event ItemBought(
        uint256 id,
        string name,
        uint256 price,
        address owner,
        bool purchased
    );

    event NftBought(
        address seller,
        uint256 price,
        uint256 tokenId,
        address tokenCollection,
        bool isForSale
    );

    modifier onlyItemOwner(uint256 _id) {
        require(items[_id].owner == msg.sender, "You are not the owner");
        _;
    }

    modifier onlyController() {
        require(controllers[msg.sender], "You are not a controller");
        _;
    }

    modifier itemAlreadyPurchased(uint256 _id) {
        require(items[_id].purchased == false, "Item already purchased");
        _;
    }
    modifier allArraysAreSameLength(
        string[] memory _names,
        uint256[] memory _prices,
        string[] memory __mongoIds
    ) {
        require(
            _names.length == _prices.length &&
                _prices.length == __mongoIds.length,
            "Arrays are not the same length"
        );
        _;
    }

    modifier enoughMoneyToBuy(uint256 _id) {
        require(
            IERC20(token).balanceOf(msg.sender) >= items[_id].price,
            "You don't have enough money"
        );
        _;
    }

    modifier deleteNftItemsLengthCompliant(
        uint256[] memory _tokenIds,
        address[] memory _tokenCollections
    ) {
        require(
            _tokenIds.length == _tokenCollections.length,
            "Arrays are not the same length"
        );
        _;
    }

    modifier buyNftCompliant(
        uint256 _tokenId,
        address _tokenCollection,
        uint256 _price
    ) {
        NftItem memory _item = nftItems[_tokenCollection][_tokenId];
        require(_item.isForSale == true, "Item is not for sale");
        require(_item.price == _price, "Price is not correct");
        require(
            IERC721(_tokenCollection).ownerOf(_tokenId) == _item.seller,
            "Seller is not the owner"
        );
        require(
            IERC20(token).balanceOf(msg.sender) >= _item.price,
            "You don't have enough money"
        );
        require(
            IERC721(_tokenCollection).isApprovedForAll(
                _item.seller,
                address(this)
            ),
            "The Owner of this nft is no longer approved for this contract"
        );
        _;
    }

    modifier addNftItemsCompliant(
        uint256[] memory _prices,
        uint256[] memory _tokenIds,
        address[] memory _tokenCollections
    ) {
        require(
            _tokenCollections.length == _tokenIds.length &&
                _tokenIds.length == _prices.length,
            "Arrays are not the same length"
        );
        for (uint256 i = 0; i < _tokenCollections.length; i++) {
            require(
                IERC721(_tokenCollections[i]).isApprovedForAll(
                    msg.sender,
                    address(this)
                ),
                "You need to approve this contract before you sell your NFTs"
            );
            require(
                IERC721(_tokenCollections[i]).ownerOf(_tokenIds[i]) ==
                    msg.sender,
                "You are not the owner of this NFT"
            );
        }
        _;
    }

    modifier notPaused() {
        require(isPaused == false, "Contract is paused");
        _;
    }

    constructor(address _token) {
        token = _token;
    }

    function createItem(
        string memory _name,
        uint256 _price,
        string memory mongoId,
        address _seller
    ) public onlyController {
        uint256 id = totalItems;
        _seller == address(0) ? _seller = msg.sender : _seller = _seller;
        if (deletedIds.length > 0) {
            id = deletedIds[deletedIds.length - 1];
            deletedIds.pop();
        } else {
            id = totalItems;
            totalItems++;
        }
        items[id] = Item(id, _name, _price, _seller, false, mongoId, true);
    }

    function buyItem(uint256 _id)
        public
        itemAlreadyPurchased(_id)
        enoughMoneyToBuy(_id)
        notPaused
    {
        Item memory _item = items[_id];
        IERC20(token).transferFrom(msg.sender, _item.owner, _item.price);
        items[_id].owner = msg.sender;
        items[_id].purchased = true;
        emit ItemBought(_item.id, _item.name, _item.price, msg.sender, true);
    }

    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }

    function createManyItems(
        string[] memory _names,
        uint256[] memory _prices,
        string[] memory _mongoIds,
        address _seller
    ) public allArraysAreSameLength(_names, _prices, _mongoIds) onlyController {
        for (uint256 i = 0; i < _names.length; i++) {
            createItem(_names[i], _prices[i], _mongoIds[i], _seller);
        }
    }

    function addNftItems(
        uint256[] memory _prices,
        uint256[] memory _tokenIds,
        address[] memory _tokenCollections
    )
        public
        onlyController
        addNftItemsCompliant(_prices, _tokenIds, _tokenCollections)
    {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            NftItem memory _item = NftItem(
                msg.sender,
                _prices[i],
                _tokenIds[i],
                _tokenCollections[i],
                true
            );
            nftItems[_tokenCollections[i]][_tokenIds[i]] = _item;
            _addNftItemToArray(_item);
        }
    }

    function buyNftItem(
        uint256 _tokenId,
        address _tokenCollection,
        uint256 _price
    ) public notPaused buyNftCompliant(_tokenId, _tokenCollection, _price) {
        NftItem memory _item = nftItems[_tokenCollection][_tokenId];
        IERC20(token).transferFrom(msg.sender, _item.seller, _price);
        IERC721(_tokenCollection).transferFrom(
            _item.seller,
            msg.sender,
            _tokenId
        );
        _removeNftItemFromArray(_item);
        delete nftItems[_tokenCollection][_tokenId];
        emit NftBought(_item.seller, _price, _tokenId, _tokenCollection, false);
    }

    function deleteNftItems(
        uint256[] memory _tokenIds,
        address[] memory _tokenCollections
    )
        public
        deleteNftItemsLengthCompliant(_tokenIds, _tokenCollections)
        onlyController
    {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _removeNftItemFromArray(
                nftItems[_tokenCollections[i]][_tokenIds[i]]
            );
            delete nftItems[_tokenCollections[i]][_tokenIds[i]];
        }
    }

    function getNftItemsForSell()
        public
        view
        returns (NftItem[] memory _items)
    {
        return nftItemsArray;
    }

    function getItems() public view returns (Item[] memory) {
        Item[] memory _items = new Item[](totalItems);
        uint256 counter = 0;
        for (uint256 i = 0; i < totalItems; i++) {
            if (items[i].exists) {
                _items[counter] = items[i];
                counter++;
            }
        }
        return _items;
    }

    function getItemsForSaleIds() public view returns (uint256[] memory) {
        uint256[] memory _itemsForSellIds = new uint256[](totalItems);
        uint256 counter = 0;
        for (uint256 i = 0; i < totalItems; i++) {
            if (items[i].purchased == false) {
                _itemsForSellIds[counter] = items[i].id;
                counter += 1;
            }
        }
        return _itemsForSellIds;
    }

    function _addNftItemToArray(NftItem memory _item) internal {
        for (uint256 i = 0; i < nftItemsArray.length; i++) {
            if (
                nftItemsArray[i].tokenId == _item.tokenId &&
                nftItemsArray[i].tokenCollection == _item.tokenCollection
            ) {
                return;
            }
        }
        nftItemsArray.push(_item);
    }

    function _removeNftItemFromArray(NftItem memory _item) internal {
        for (uint256 i = 0; i < nftItemsArray.length; i++) {
            if (
                nftItemsArray[i].tokenId == _item.tokenId &&
                nftItemsArray[i].tokenCollection == _item.tokenCollection
            ) {
                delete nftItemsArray[i];
                nftItemsArray[i] = nftItemsArray[nftItemsArray.length - 1];
                nftItemsArray.pop();
                return;
            }
        }
    }

    function getSoldItems() public view returns (Item[] memory) {
        Item[] memory _soldItems = new Item[](totalItems);
        uint256 counter = 0;
        for (uint256 i = 0; i < totalItems; i++) {
            if (items[i].purchased == true) {
                _soldItems[counter] = items[i];
                counter += 1;
            }
        }
        return _soldItems;
    }

    function paused() public view returns (bool) {
        return isPaused;
    }

    function getSomeLove() public pure returns (string memory) {
        return "Love you <3 <3 <3";
    }

    function getSoldItemsIds() public view returns (uint256[] memory) {
        uint256[] memory _soldItemsIds = new uint256[](totalItems);
        uint256 counter = 0;
        for (uint256 i = 0; i < totalItems; i++) {
            if (items[i].purchased == true) {
                _soldItemsIds[counter] = items[i].id;
                counter += 1;
            }
        }
        return _soldItemsIds;
    }

    function getItem(uint256 _id) public view returns (Item memory) {
        return items[_id];
    }

    function getBalance() public view returns (uint256) {
        return IERC20(token).balanceOf(msg.sender);
    }

    function deleteItem(uint256 _id) public onlyController {
        require(items[_id].purchased == false, "Item is already purchased");
        require(items[_id].exists == true, "Item does not exist");
        deletedIds.push(_id);
        delete items[_id];
    }

    function deleteManyItems(uint256[] memory _ids) public onlyController {
        for (uint256 i = 0; i < _ids.length; i++) {
            deleteItem(_ids[i]);
        }
    }
}