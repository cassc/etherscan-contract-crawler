// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";

// import "hardhat/console.sol";

/*
    Author: chosta.eth (@chosta_eth)
 */
/*
    Inspired by: 0xInu's Martian Marketplace 0xFD8f4aC172457FD30Df92395BC69d4eF6d92eDd4
*/
/**
    Borrowed the core VendingItems functionality and amended it to work with the Founders token. 
    Additionally, an option to purchase an item in the form of erc1155 was added. The concept of having an 
    erc1155 token as a marketplace entry enables decentralized whitelisting where users can own the item, 
    trade, burn, or mint with it without having to go through discord admins and wallet collection.
 */
/* To draw a front-end interface:
    
        getWLVendingItemsAll() - Enumerate all vending items
        available for the contract. Supports over 1000 items in 1 call but
        if you get gas errors, use a pagination method instead.

        Pagination method: 
        getWLVendingItemsPaginated(uint256 start_, uint256 end_)
        for the start_, generally you can use 0, and for end_, inquire from function
        getWLVendingItemsLength()

    For interaction of users:

        purchaseWLVendingItem(uint256 index_) can be used
        and automatically populated to the correct buttons for each WLVendingItem
        for that, an ethers.js call is invoked for the user to call the function
        which will transfer their ERC20 token and add them to the purchasers list
        + ability to buy erc1155 compatible tokens used as WL entries

    For administration:

        addWLVendingItem(WLVendingItem memory WLVendingItem_) is used to create a new WLVendingItem

        modifyWLVendingItem(uint256 index_, 
        WLVendingItem memory WLVendingItem_) lets you modify a WLVendingItem.
        You have to pass in a tuple instead. Only use when necessary. Not
        recommended to use.

        deleteMostRecentWLVendingItem() we use a .pop() for this so
        it can only delete the most recent item. For some mistakes that you made and
        want to erase them.

        manageController(address operator_, bool bool_) is a special
        governance function which allows you to add controllers to the contract
        to do actions on your behalf. */

interface IToken {
    function owner() external view returns (address);

    function balanceOf(address address_) external view returns (uint256);

    function burn(address from_, uint256 amount_) external;
}

interface IMarketItem1155 {
    function safeTransferFrom(
        address from_,
        address to_,
        uint256 id_,
        uint256 amount_,
        bytes memory data_
    ) external;

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function burn(
        address from,
        uint256 id,
        uint256 value
    ) external;
}

contract FFMarketplace is
    ReentrancyGuard,
    ERC1155Holder,
    Pausable,
    AccessControl
{
    enum VendingItemType {
        ERC1155,
        WL,
        RAFFLE,
        LOOTBOX,
        NFT,
        MERCH,
        IRL,
        MISC
    }

    struct WLVendingItem {
        uint256 tokenId; // ERC1155 token id
        VendingItemType itemType;
        bool active; // frontend help - use to hide items
        string title;
        string imageUri;
        string description;
        uint32 amountAvailable;
        uint32 amountPurchased;
        uint256 startTime;
        uint256 endTime;
        uint256 price;
        string discord;
        string twitter;
    }

    IToken public token;
    IMarketItem1155 public marketItem;
    WLVendingItem[] public toWLVendingItems;
    mapping(uint256 => address[]) public toWLPurchasers;
    mapping(uint256 => mapping(address => bool)) public toWLPurchased;
    // On Chain Discord Directory
    // Inspired by 0xInuarashi's OnChainDiscordDirectory
    mapping(address => string) public addressToDiscord;

    event WLVendingItemAdded(address indexed operator_, WLVendingItem item_);
    event WLVendingItemModified(
        address indexed operator_,
        WLVendingItem before_,
        WLVendingItem after_
    );
    event WLVendingItemRemoved(address indexed operator_, WLVendingItem item_);
    event WLVendingItemPurchased(
        address indexed purchaser_,
        uint256 index_,
        WLVendingItem item_
    );
    event WLVendingItemGifted(
        address indexed gifted_,
        uint256 index_,
        WLVendingItem item_
    );
    event DiscordDirectoryUpdated(address indexed setter_, string discordTag_);

    bytes32 public constant MARKETPLACE_ADMIN = keccak256("MARKETPLACE_ADMIN");

    constructor(address _token, address _marketItem) {
        token = IToken(_token);
        marketItem = IMarketItem1155(_marketItem);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MARKETPLACE_ADMIN, msg.sender);
    }

    // override needed for AccessControl and ERC1155Receiver (receiver part of ERC1155Holder)
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC1155Receiver)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /** ###########
        Admin stuff
     */
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /* 
        Changing the erc1155 contract should be fine but it invalidates any previously
        created erc1155 vending items
     */
    function updateMarketItemContract(address marketItem_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        marketItem = IMarketItem1155(marketItem_);
    }

    function addWLVendingItem(WLVendingItem memory WLVendingItem_)
        external
        onlyRole(MARKETPLACE_ADMIN)
    {
        require(
            bytes(WLVendingItem_.title).length > 0,
            "you must specify a title"
        );
        require(
            uint256(WLVendingItem_.endTime) > block.timestamp,
            "already expired timestamp"
        );
        require(
            WLVendingItem_.endTime > WLVendingItem_.startTime,
            "endTime < startTime"
        );
        // Make sure that the token id for non erc1155 is 0
        if (WLVendingItem_.itemType != VendingItemType.ERC1155) {
            WLVendingItem_.tokenId = 0;
        } else {
            require(WLVendingItem_.tokenId > 0, "token id must be > 0");
            // if adding an erc1155 -> check for the amount available
            require(
                WLVendingItem_.amountAvailable <=
                    marketItem.balanceOf(address(this), WLVendingItem_.tokenId),
                "insufficient erc1155 tokens"
            );
        }

        // Make sure that amountPurchased on adding is always 0
        WLVendingItem_.amountPurchased = 0;

        // Push the item to the database array
        toWLVendingItems.push(WLVendingItem_);

        emit WLVendingItemAdded(msg.sender, WLVendingItem_);
    }

    function modifyWLVendingItem(
        uint256 index_,
        WLVendingItem memory WLVendingItem_
    ) external onlyRole(MARKETPLACE_ADMIN) {
        WLVendingItem memory _item = toWLVendingItems[index_];

        require(bytes(_item.title).length > 0, "item does not exist");
        require(
            bytes(WLVendingItem_.title).length > 0,
            "you must specify a title"
        );
        require(
            uint256(WLVendingItem_.endTime) > block.timestamp,
            "already expired timestamp"
        );
        require(
            WLVendingItem_.endTime > WLVendingItem_.startTime,
            "endTime < startTime"
        );
        require(
            WLVendingItem_.amountAvailable >= _item.amountPurchased,
            "available must be >= purchased"
        );

        if (WLVendingItem_.itemType != VendingItemType.ERC1155) {
            WLVendingItem_.tokenId = 0;
        } else {
            require(WLVendingItem_.tokenId > 0, "token id must be > 0");
            require(
                WLVendingItem_.amountAvailable <=
                    marketItem.balanceOf(address(this), WLVendingItem_.tokenId),
                "insufficient erc1155 tokens"
            );
        }

        toWLVendingItems[index_] = WLVendingItem_;

        emit WLVendingItemModified(msg.sender, _item, WLVendingItem_);
    }

    function deleteMostRecentWLVendingItem()
        external
        onlyRole(MARKETPLACE_ADMIN)
    {
        uint256 _lastIndex = toWLVendingItems.length - 1;

        WLVendingItem memory _item = toWLVendingItems[_lastIndex];

        require(_item.amountPurchased == 0, "goods already bought");

        toWLVendingItems.pop();
        emit WLVendingItemRemoved(msg.sender, _item);
    }

    /* in case we have some unused or erroneous erc1155s */
    function burnERC1155Tokens(uint256 tokenId_, uint256 amount_)
        external
        onlyRole(MARKETPLACE_ADMIN)
    {
        marketItem.burn(address(this), tokenId_, amount_);
    }

    function giftPurchaserAsMarketAdmin(uint256 index_, address giftedAddress_)
        external
        onlyRole(MARKETPLACE_ADMIN)
    {
        WLVendingItem memory _item = getWLVendingItem(index_);

        require(bytes(_item.title).length > 0, "object does not exist");
        require(
            _item.amountAvailable > _item.amountPurchased,
            "no more items remaining"
        );
        require(!toWLPurchased[index_][giftedAddress_], "already added");

        if (_item.itemType == VendingItemType.ERC1155) {
            transferERC1155(_item.tokenId, giftedAddress_);
        }

        toWLPurchased[index_][giftedAddress_] = true;
        toWLPurchasers[index_].push(giftedAddress_);

        toWLVendingItems[index_].amountPurchased++;

        emit WLVendingItemGifted(giftedAddress_, index_, _item);
    }

    /* ### 
        User actions
     */
    function purchaseWLVendingItem(uint256 index_) external nonReentrant {
        // Load the WLVendignItem to Memory
        WLVendingItem memory _item = toWLVendingItems[index_];

        // Check the necessary requirements to purchase
        require(bytes(_item.title).length > 0, "object does not exist");
        require(
            _item.amountAvailable > _item.amountPurchased,
            "no more items remaining"
        );

        require(_item.startTime <= block.timestamp, "not started yet");
        require(_item.endTime >= block.timestamp, "past deadline");
        require(!toWLPurchased[index_][msg.sender], "already purchased");
        require(_item.price != 0, "no price for item");
        require(
            token.balanceOf(msg.sender) >= _item.price,
            "not enough tokens"
        );

        token.burn(msg.sender, _item.price);
        // Pay for the WL (burning do)
        // token.transferFrom(msg.sender, burnAddress, _item.price);

        // handle erc1155
        if (_item.itemType == VendingItemType.ERC1155) {
            transferERC1155(_item.tokenId, msg.sender);
        }

        // Add the address into the WL List
        toWLPurchased[index_][msg.sender] = true;
        toWLPurchasers[index_].push(msg.sender);

        // Increment Amount Purchased
        toWLVendingItems[index_].amountPurchased++;

        emit WLVendingItemPurchased(msg.sender, index_, _item);
    }

    // a handy util function to map discord tags to purchaser addresses
    function setDiscordIdentity(string calldata discordTag_) external {
        addressToDiscord[msg.sender] = discordTag_;

        emit DiscordDirectoryUpdated(msg.sender, discordTag_);
    }

    /** #####
        Internal
    */
    function transferERC1155(uint256 tokenId_, address sender_) internal {
        require(
            marketItem.balanceOf(address(this), tokenId_) > 0,
            "no more erc1155"
        );
        marketItem.safeTransferFrom(
            address(this),
            sender_,
            tokenId_,
            1,
            "item transferred"
        );
    }

    /** #####
        Views 
    */
    // raw
    function getWLVendingItemsAll()
        public
        view
        returns (WLVendingItem[] memory)
    {
        return toWLVendingItems;
    }

    function getWLVendingItem(uint256 index_)
        public
        view
        returns (WLVendingItem memory)
    {
        WLVendingItem memory _item = toWLVendingItems[index_];
        return _item;
    }

    function getWLPurchasersOf(uint256 index_)
        public
        view
        returns (address[] memory)
    {
        return toWLPurchasers[index_];
    }

    function getFixedPriceOfItem(uint256 index_)
        external
        view
        returns (uint256)
    {
        return toWLVendingItems[index_].price;
    }

    function getWLVendingItemsLength() public view returns (uint256) {
        return toWLVendingItems.length;
    }

    function getWLVendingItemsPaginated(uint256 start_, uint256 end_)
        public
        view
        returns (WLVendingItem[] memory)
    {
        uint256 _arrayLength = end_ - start_ + 1;
        WLVendingItem[] memory _items = new WLVendingItem[](_arrayLength);
        uint256 _index;

        for (uint256 i = 0; i < _arrayLength; i++) {
            _items[_index++] = toWLVendingItems[start_ + i];
        }

        return _items;
    }
}