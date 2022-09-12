//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/*
🍤🍤🍤🍤🍤🍤🍤🍤🍤🍤🍤🍤
🍤The Tempura Shop 🍤
🍤🍤🍤🍤🍤🍤🍤🍤🍤🍤🍤🍤
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
}

contract TempuraShop is Ownable {
    ///@notice Main listing struct
    ///@param amountAvailable Total amount available for listing
    ///@param amountPurchased Total amount purchased for listing
    ///@param startTime Start time for listing
    ///@param endTime End time for listing
    ///@param price Price of listing in ETH base units
    ///@param _type Indicator for OG/Elite/Regular market
    struct Item {
        uint64 index;
        uint32 amountAvailable;
        uint32 amountPurchased;
        uint32 startTime;
        uint32 endTime;
        uint32 price;
        uint32 _type;
    }

    struct Raffle {
        uint64 index;
        uint32 amountAvailable;
        uint32 amountPurchased;
        uint32 startTime;
        uint32 endTime;
        uint32 price;
        uint32 _type;
    }

    ///@notice Arrays containing all listings
    Item[] public items;
    Raffle[] public raffles;

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
    mapping(uint256 => address[]) public raffleIndexToPurchasers;

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

    function addItem(Item memory Item_) external onlyManager {
        Item_.amountPurchased = 0;
        Item_.index = uint64(items.length);
        items.push(Item_);
    }

    function addRaffle(Raffle memory Raffle_) external onlyManager {
        Raffle_.amountPurchased = 0;
        Raffle_.index = uint64(raffles.length);
        raffles.push(Raffle_);
    }

    function addMultiItems(Item[] memory Item_) external onlyManager {
        for (uint256 i; i < Item_.length; i++) {
            Item_[i].amountPurchased = 0;
            Item_[i].index = uint64(items.length);
            items.push(Item_[i]);
        }
    }

    function addMultiRaffles(Raffle[] memory Raffle_) external onlyManager {
        for (uint256 i; i < Raffle_.length; i++) {
            Raffle_[i].amountPurchased = 0;
            Raffle_[i].index = uint64(raffles.length);
            raffles.push(Raffle_[i]);
        }
    }

    function modifyItem(uint256 index_, Item memory Item_) external onlyManager {
        Item memory _item = items[index_];
        require(_item.price > 0, "This Item doesn't exist!");
        Item_.amountPurchased = _item.amountPurchased;
        items[index_] = Item_;
    }

    function deleteMostRecentItem() external onlyManager {
        uint256 _lastIndex = items.length - 1;

        Item memory _item = items[_lastIndex];

        require(_item.amountPurchased == 0, "Cannot delete item with already bought goods!");

        items.pop();
    }

    function purchaseItem(uint256 index_, string calldata discordId) external {
        Item memory _item = items[index_];

        if (_item._type == 0) {
            require(
                OGYakuza.balanceOf(msg.sender) != 0,
                "You must hold an OG Yakuza to purchase!"
            );
        }
        if (_item._type == 1) {
            require(
                YakuzaElite.balanceOf(msg.sender) != 0,
                "You  must hold a Yakuza Elite to purchase!"
            );
        }

        require(_item.amountAvailable > _item.amountPurchased, "No more items remaining!");
        require(_item.startTime <= block.timestamp, "Not started yet!");
        require(_item.endTime >= block.timestamp, "Already ended!");
        require(!indexToPurchased[index_][msg.sender], "Already purchased!");

        // Pay for the item
        Tempura.transferFrom(msg.sender, burnAddress, (uint256(_item.price) * 1 ether));

        // Add the address into the WL List
        indexToPurchased[index_][msg.sender] = true;
        indexToPurchasers[index_].push(msg.sender);

        // Increment Amount Purchased
        items[index_].amountPurchased++;

        emit Purchase(msg.sender, discordId, _item.index);
    }

    function purchaseRaffleTicket(uint256 index_, string calldata discordId) external {
        Raffle memory _raffle = raffles[index_];

        if (_raffle._type == 0) {
            require(
                OGYakuza.balanceOf(msg.sender) != 0,
                "You must hold an OG Yakuza to purchase!"
            );
        }
        if (_raffle._type == 1) {
            require(
                YakuzaElite.balanceOf(msg.sender) != 0,
                "You  must hold a Yakuza Elite to purchase!"
            );
        }

        require(_raffle.amountAvailable > _raffle.amountPurchased, "No more items remaining!");
        require(_raffle.startTime <= block.timestamp, "Not started yet!");
        require(_raffle.endTime >= block.timestamp, "Already ended!");

        // Pay for the item
        Tempura.transferFrom(msg.sender, burnAddress, (uint256(_raffle.price) * 1 ether));

        // Add the address into the WL List
        indexToPurchasers[index_].push(msg.sender);

        // Increment Amount Purchased
        items[index_].amountPurchased++;

        emit Purchase(msg.sender, discordId, _raffle.index);
    }

    ///////////////////////////////
    // View/Marketplace Helpers //
    /////////////////////////////

    function getPurchasersOfItem(uint256 index_) public view returns (address[] memory) {
        return indexToPurchasers[index_];
    }

    function getPurchasersOfRaffle(uint256 index_) public view returns (address[] memory) {
        return raffleIndexToPurchasers[index_];
    }

    function getItemsLength() public view returns (uint256) {
        return items.length;
    }

    function getRafflesAll() public view returns (Raffle[] memory) {
        return raffles;
    }

    function getRafflesLength() public view returns (uint256) {
        return raffles.length;
    }

    function getItemsAll() public view returns (Item[] memory) {
        return items;
    }

    function getRemainingSupply(uint256 index_) public view returns (uint32) {
        return items[index_].amountAvailable - items[index_].amountPurchased;
    }

    function getRemainingSupplyRaffle(uint256 index_) public view returns (uint32) {
        return raffles[index_].amountAvailable - raffles[index_].amountPurchased;
    }

    function getRemainingSupplyForAll() public view returns (uint32[] memory) {
        uint32[] memory allSupplies = new uint32[](items.length);
        for (uint256 i; i < items.length; i++) {
            uint32 supply = getRemainingSupply(i);
            allSupplies[i] = supply;
        }
        return allSupplies;
    }

    function getRemainingSupplyForAllRaffles() public view returns (uint32[] memory) {
        uint32[] memory allSupplies = new uint32[](raffles.length);
        for (uint256 i; i < raffles.length; i++) {
            uint32 supply = getRemainingSupplyRaffle(i);
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