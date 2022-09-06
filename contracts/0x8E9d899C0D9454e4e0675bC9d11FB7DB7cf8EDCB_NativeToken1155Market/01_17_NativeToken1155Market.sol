// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract NativeToken1155Market is 
    Initializable,
    ReentrancyGuardUpgradeable, 
    OwnableUpgradeable, 
    ERC1155ReceiverUpgradeable,
    UUPSUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    struct MarketItem {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        address seller;
        uint256 price;
        uint256 listedPercentage;
    }

    uint private _itemIds;
    EnumerableSetUpgradeable.UintSet private _activeIds;

    address private _feesAddress;
    uint256 private _saleFeePercentage;

    mapping(address => EnumerableSetUpgradeable.UintSet) private _usersTotalListings;
    mapping(uint => MarketItem) private _marketItems;
    
    event ItemListed (
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        uint256 price
    );

    event ItemSold (
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address buyer,
        uint256 price
    );

    event ItemCancelled (
        uint256 indexed itemId,
        address indexed owner
    );

    function initialize(
        address feesAddress, 
        uint256 saleFeePercentage, 
        address owner
    ) public initializer {
        __ERC1155Receiver_init();
        _transferOwnership(owner);
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        
        _saleFeePercentage = saleFeePercentage;
        _feesAddress = feesAddress;
    }

    function setFeesAddress(address newFeesAddress) external onlyOwner {
        _feesAddress = newFeesAddress;
    }

    // Allows controller to set new sales fee percentage
    function setSaleFeesPercentage(uint newSaleFeesPercentage) external onlyOwner {
        _saleFeePercentage = newSaleFeesPercentage;
    }

    function getFeesAddress() public view returns (address) {
        return _feesAddress;
    }

    /* Returns the percentage taken from sales  */
    function getSaleFeePercentage() public view returns (uint256) {
        return _saleFeePercentage;
    }

    /* Places an item for sale on the marketplace */
    function listItem(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) public nonReentrant {
        require(price > 0, "NativeToken1155Market: Price must be at least 1 wei");
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

        IERC1155Upgradeable(nftContract).safeTransferFrom(msg.sender, address(this), tokenId, 1, "");
        emit ItemListed(itemId, nftContract, tokenId, msg.sender, price);
    }

    /* Places an item for sale on the marketplace */
    function batchListItem(
        address[] memory nftContract,
        uint256[] memory tokenId,
        uint256[] memory price
    ) public nonReentrant {
        uint256 nftContractLength = nftContract.length;
        require(nftContractLength == tokenId.length, "NativeToken1155Market: nftContracts and tokenId length mismatch");
        require(nftContractLength == price.length, "NativeToken1155Market: nftContracts and price length mismatch");

        uint itemId = _itemIds;
        for (uint256 i = 0; i < nftContractLength; i++) {
            require(price[i] > 0, "NativeToken1155Market: Price must be at least 1 wei");
            itemId = itemId + 1;
            _marketItems[itemId] = MarketItem(
                itemId,
                nftContract[i],
                tokenId[i],
                msg.sender,
                price[i],
                _saleFeePercentage
            );
            _activeIds.add(itemId);
            _usersTotalListings[msg.sender].add(itemId);
            IERC1155Upgradeable(nftContract[i]).safeTransferFrom(msg.sender, address(this), tokenId[i], 1, "");
            emit ItemListed(itemId, nftContract[i], tokenId[i], msg.sender, price[i]);
        }

        _itemIds = itemId;
    }

     /* Places an item for sale on the marketplace */
    function cancelListing(
        uint256 itemId
    ) public nonReentrant {
        MarketItem memory item = _marketItems[itemId];
        require(msg.sender == item.seller, "NativeToken1155Market: Only seller can cancel");
        
        delete _marketItems[itemId];

        IERC1155Upgradeable(item.nftContract).safeTransferFrom(address(this), msg.sender, item.tokenId, 1, "");
        _activeIds.remove(itemId);

        _usersTotalListings[msg.sender].remove(itemId);

        emit ItemCancelled(itemId, item.seller);
    }

    /* Creates the sale of a marketplace item */
    /* Transfers ownership of the item, as well as funds between parties */
    function purchaseItem(
        uint256 itemId
    ) public payable nonReentrant {
        MarketItem memory item = _marketItems[itemId];
        require(item.price > 0, "No item for the Id");
        require(msg.value == item.price, "NativeToken1155Market: Please submit the asking price in order to complete the purchase");

        delete _marketItems[itemId];
        
        uint feesPortion = msg.value / item.listedPercentage;
    
        (bool paymentSent, ) = payable(item.seller).call{value: msg.value - feesPortion}("");
        require(paymentSent, "NativeToken1155Market: Failed to send payment");

        (bool listingFeeSent, ) = payable(_feesAddress).call{value: feesPortion}("");
        require(listingFeeSent, "NativeToken1155Market: Failed to send listing fee");
        
        IERC1155Upgradeable(item.nftContract).safeTransferFrom(address(this), msg.sender, item.tokenId, 1, "");

        _activeIds.remove(itemId);
        _usersTotalListings[item.seller].remove(itemId);

        emit ItemSold(itemId, item.nftContract, item.tokenId, msg.sender, item.price);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

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

    // /**
    //  * @dev See {IERC165-supportsInterface}.
    //  */
    // function supportsInterface(bytes4 interfaceId)
    //     public
    //     view
    //     virtual
    //     override(AccessControlEnumerable, ERC1155, IERC165)
    //     returns (bool)
    // {
    //     return super.supportsInterface(interfaceId);
    // }

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

     /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4) {
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }
}