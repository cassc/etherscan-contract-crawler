// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract NativeToken721Market is 
    Initializable,
    ReentrancyGuardUpgradeable, 
    OwnableUpgradeable,
    UUPSUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    struct MarketItem {
        uint itemId;
        address nftContract;
        uint tokenId;
        address seller;
        uint price;
        uint listedPercentage;
    }

    uint private _itemIds;
    EnumerableSetUpgradeable.UintSet private _activeIds;

    uint private _saleFeePercentage;
    address private _feesAddress;

    mapping(address => EnumerableSetUpgradeable.UintSet) private _usersTotalListings;
    mapping(uint => MarketItem) private _marketItems;

    event ItemListed (
        uint itemId,
        address seller
    );

    event ItemSold (
        uint itemId,
        address buyer
    );

    event ItemCancelled (
        uint itemId,
        address owner
    );

    function initialize(
        address feesAddress, 
        uint256 saleFeePercentage, 
        address owner
    ) public initializer {
        _transferOwnership(owner);
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        _saleFeePercentage = saleFeePercentage;
        _feesAddress = feesAddress;
    }

    function setFeesAddress(address newFeesAddress) external onlyOwner {
        _feesAddress = newFeesAddress;
    }
    
    function getFeesAddress() public view returns (address) {
        return _feesAddress;
    }

    // Allows controller to set new sales fee percentage
    function setSaleFeesPercentage(uint newSaleFeesPercentage) external onlyOwner {
        _saleFeePercentage = newSaleFeesPercentage;
    }

    // Places an item for sale on the marketplace
    function listItem(
        address nftContract,
        uint tokenId,
        uint price
    ) public nonReentrant {
        require(price > 0, "NativeToken721Market: Price must be at least 1 wei");
        uint itemId = _itemIds + 1;

        _marketItems[itemId] = MarketItem(
            itemId,
            nftContract,
            tokenId,
            msg.sender,
            price,
            _saleFeePercentage
        );

        _activeIds.add(itemId);
        _usersTotalListings[msg.sender].add(itemId);
        _itemIds = itemId;

        IERC721Upgradeable(nftContract).transferFrom(msg.sender, address(this), tokenId);
        emit ItemListed(itemId, msg.sender);
    }

     /* Places an item for sale on the marketplace */
    function cancelListing(
        uint itemId
    ) public nonReentrant {
        MarketItem memory item = _marketItems[itemId];
        require(msg.sender == item.seller, "NativeToken721Market: Only seller can cancel");
        
        delete _marketItems[itemId];

        IERC721Upgradeable(item.nftContract).transferFrom(address(this), msg.sender, item.tokenId);
        _activeIds.remove(itemId);

        _usersTotalListings[msg.sender].remove(itemId);

        emit ItemCancelled(itemId, item.seller);
    }

    /* Creates the sale of a marketplace item */
    /* Transfers ownership of the item, as well as funds between parties */
    function purchaseItem(
        uint itemId
    ) public payable nonReentrant {
        MarketItem memory item = _marketItems[itemId];
        require(item.price > 0, "No item for the Id");
        require(msg.value == item.price, "NativeToken721Market: Please submit the asking price in order to complete the purchase");

        delete _marketItems[itemId];
        
        uint feesPortion = msg.value / item.listedPercentage;
    
        (bool paymentSent, ) = payable(item.seller).call{value: msg.value - feesPortion}("");
        require(paymentSent, "NativeToken721Market: Failed to send payment");

        (bool listingFeeSent, ) = payable(_feesAddress).call{value: feesPortion}("");
        require(listingFeeSent, "NativeToken721Market: Failed to send listing fee");
        
        IERC721Upgradeable(item.nftContract).transferFrom(address(this), msg.sender, item.tokenId);

        _activeIds.remove(itemId);
        _usersTotalListings[item.seller].remove(itemId);

        emit ItemSold(itemId, msg.sender);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    /* Returns the percentage taken from sales  */
    function getSaleFeePercentage() public view returns (uint) {
        return _saleFeePercentage;
    }
    
    function totalListings() public view returns (uint) {
        return _itemIds;
    }
    
    function itemById(uint itemId) public view returns (MarketItem memory) {
        return _marketItems[itemId];
    }

    function activeItems() public view returns (MarketItem[] memory) {
        uint totalActive = _activeIds.length();

        MarketItem[] memory items = new MarketItem[](totalActive);
        for (uint i = 0; i < totalActive; i++) {
            items[i] = _marketItems[_activeIds.at(i)];
        }

        return items;
    }

    function usersListings(address user) public view returns (MarketItem[] memory) {
        MarketItem[] memory items = new MarketItem[](_usersTotalListings[user].length());

        for (uint i = 0; i < items.length; i++) {
            items[i] = _marketItems[_usersTotalListings[user].at(i)];
        }

        return items;
    }

    function usersListingIds(address user) public view returns (uint[] memory) {
        uint[] memory ids = new uint[](_usersTotalListings[user].length());
        
        for (uint i = 0; i < ids.length; i++) {
            ids[i] = _usersTotalListings[user].at(i);
        }
        
        return ids;
    }
}