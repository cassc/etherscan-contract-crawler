//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/*
🍤🍤🍤🍤🍤🍤🍤🍤🍤🍤🍤🍤🍤🍤
🍤The Tempura Shop V2 🍤
🍤🍤🍤🍤🍤🍤🍤🍤🍤🍤🍤🍤🍤🍤

Fuck O(n) ( ︶︿︶)_╭∩╮
*/

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20Like {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external;
}

interface IERC721Like {
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 token) external view returns (address);
}

contract TempuraShop is Ownable {
    ///@notice Main listing struct
    ///@param amountAvailable Total amount available for listing
    ///@param amountPurchased Total amount purchased for listing
    ///@param startTime Start time for listing
    ///@param endTime End time for listing
    ///@param price Price of listing in ETH base units
    ///@param shop Indicator for OG/Elite/Regular market
    ///@param listingType Indicates Regular listing vs Raffle
    struct Item {
        uint64 index;
        uint32 amountAvailable;
        uint32 amountPurchased;
        uint32 startTime;
        uint32 endTime;
        uint32 price;
        uint16 shop;
        uint16 listingType;
    }

    ///@notice Arrays containing all listings
    Item[] public items;

    ///@notice Event to index purchases
    event Purchase(address buyer, string discordId, uint64 index);

    ///@notice Setting our contracts...
    IERC20Like public Tempura = IERC20Like(0xf52ae754AE9aaAC2f3A6C8730871d980389a424d);
    IERC721Like public OGYakuza = IERC721Like(0x0EE1448F200e6e65E9bad7A335E3FFb674c0f68C);
    IERC721Like public YakuzaElite = IERC721Like(0xE2C430d0c0B6B690FaCF54Ca26d7620237aA62A4);

    address public burnAddress = 0x000000000000000000000000000000000000dEaD;

    ///@notice Managers can set/modify listings
    mapping(address => bool) public managers;
    ///@notice Mapping that stores an array of all purchases for each item index
    mapping(uint256 => address[]) public indexToPurchasers;
    ///@notice Mapping that notates if an address has purchased a listing already.
    mapping(uint256 => mapping(address => bool)) public indexToPurchased;

    modifier onlyManager() {
        require(managers[msg.sender], "You are not a manager!");
        _;
    }

    /////////////////////////////////
    // Owner Restricted Functions //
    ///////////////////////////////

    function setManagers(address manager, bool status) external onlyOwner {
        managers[manager] = status;
    }

    function setTempura(address _tempura) external onlyOwner {
        Tempura = IERC20Like(_tempura);
    }

    function setOGYakuza(address _og) external onlyOwner {
        OGYakuza = IERC721Like(_og);
    }

    function setYakuzaElite(address _elite) external onlyOwner {
        YakuzaElite = IERC721Like(_elite);
    }

    ///////////////////////////////////
    // Manager Restricted Functions //
    /////////////////////////////////


    ///@notice Add Items using structure [index,amountAvailable,amountPurchased,startTime,endTime,price,shop,listingType]
    function addItem(Item memory Item_) external onlyManager {
        Item_.amountPurchased = 0;
        Item_.index = uint64(items.length);
        items.push(Item_);
    }

    ///@notice Add Items using structure [index,amountAvailable,amountPurchased,startTime,endTime,price,shop,listingType]
    function addMultiItems(Item[] memory Item_) external onlyManager {
        for (uint256 i; i < Item_.length; i++) {
            Item_[i].amountPurchased = 0;
            Item_[i].index = uint64(items.length);
            items.push(Item_[i]);
        }
    }


    ///@notice modify Items using structure [index,amountAvailable,amountPurchased,startTime,endTime,price,shop,listingType]
    function modifyItem(uint256 index_, Item memory Item_) external onlyManager {
        Item memory _item = items[index_];
        require(_item.price > 0, "This Item doesn't exist!");
        Item_.amountPurchased = _item.amountPurchased;
        items[index_] = Item_;
    }

    function addPurchaser(uint256 index_, address purchaser) external onlyManager {
        Item memory _item = items[index_];
        require(_item.amountAvailable > _item.amountPurchased, "No more items remaining!");
        
        indexToPurchased[index_][msg.sender] = true;
        indexToPurchasers[index_].push(purchaser);

        // Increment Amount Purchased
        items[index_].amountPurchased++;

    }

    ///@notice DO NOT FORGET TO UPDATE DATABASE IF DOING THIS MANUALLY
    function deleteMostRecentItem() external onlyManager {
        uint256 _lastIndex = items.length - 1;
        Item memory _item = items[_lastIndex];
        require(_item.amountPurchased == 0, "Cannot delete item with already bought goods!");
        items.pop();
    }

    function purchaseItem(uint256 index_, uint256 token, string calldata discordId) public {
        Item memory _item = items[index_];

        if (_item.shop == 0) {
            require(
                OGYakuza.ownerOf(token) == msg.sender,
                "You must hold an OG Yakuza to purchase!"
            );
        }
        if (_item.shop == 1) {
            require(
                YakuzaElite.balanceOf(msg.sender) != 0,
                "You  must hold a Yakuza Elite to purchase!"
            );
        }
        
        if (_item.listingType == 0) {
            require(!indexToPurchased[index_][msg.sender], "Already purchased!");
        }

        require(_item.amountAvailable > _item.amountPurchased, "No more items remaining!");
        require(_item.startTime <= block.timestamp, "Not started yet!");
        require(_item.endTime >= block.timestamp, "Already ended!");

        // Pay for the item
        Tempura.transferFrom(msg.sender, burnAddress, (uint256(_item.price) * 1 ether));

        // Add the address into the WL List
        indexToPurchased[index_][msg.sender] = true;
        indexToPurchasers[index_].push(msg.sender);

        // Increment Amount Purchased
        items[index_].amountPurchased++;

        emit Purchase(msg.sender, discordId, _item.index);
    }

    function purchaseMultiItem(uint256[] calldata indexes, uint256 token, string calldata discordId) external {
        for (uint256 i; i < indexes.length; i++) {
            purchaseItem(indexes[i], token, discordId);
        }
    }


    ///////////////////////////////
    // View/Marketplace Helpers //
    /////////////////////////////

    function getPurchasersOfItem(uint256 index_) public view returns (address[] memory) {
        return indexToPurchasers[index_];
    }

    function getItemsLength() public view returns (uint256) {
        return items.length;
    }

    function getItemsAll() public view returns (Item[] memory) {
        return items;
    }

    function getRemainingSupply(uint256 index_) public view returns (uint32) {
        return items[index_].amountAvailable - items[index_].amountPurchased;
    }

    function getRemainingSupplyForAll() public view returns (uint32[] memory) {
        uint32[] memory allSupplies = new uint32[](items.length);
        for (uint256 i; i < items.length; i++) {
            uint32 supply = getRemainingSupply(i);
            allSupplies[i] = supply;
        }
        return allSupplies;
    }

    function getSomeItems(uint256 start_, uint256 end_) public view returns (Item[] memory) {
        uint256 _arrayLength = end_ - start_ + 1;
        Item[] memory _items = new Item[](_arrayLength);
        uint256 _index;

        for (uint256 i = 0; i < _arrayLength; i++) {
            _items[_index++] = items[start_ + i];
        }

        return _items;
    }

    function getIndexToPurchasedBatch(address purchaser_, uint256[] memory indexes_)
        public
        view
        returns (bool[] memory)
    {
        uint256 len = indexes_.length;
        bool[] memory purchasedArray = new bool[](len);

        uint256 i = 0;
        while (i < len) {
            purchasedArray[i] = indexToPurchased[indexes_[i]][purchaser_];
            i++;
        }
        return purchasedArray;
    }

}