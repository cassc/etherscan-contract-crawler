// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Marketplace is Ownable, ReentrancyGuard, ERC721Holder, ERC1155Holder {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;

    IERC20 public laroToken;
    IERC20 public busdToken;

    uint256 public constant LARO_TOKEN = 1;
    uint256 public constant BUSD_TOKEN = 2;

    uint256 constant ASSET_ERC721 = 1;
    uint256 constant ASSET_ERC1155 = 2;

    uint256 public busdFee = 500;
    uint256 public laroFee = 300;

    address public operationsAddress;

    struct MarketItem {
        uint256 itemId;
        uint256 assetType;
        address assetContract;
        uint256 tokenId;
        address seller;
        address owner;
        uint256 paymentMethod;
        uint256 price;
        bool sold;
        uint256 datePosted;
        uint256 dateSold;
        uint256 quantity;
    }

    mapping(address => bool) allowedAssetList;
    mapping(address => uint256) assetTypes;

    mapping(uint256 => MarketItem) private idToMarketItem;

    mapping(address => uint256[]) listedByUser;
    mapping(address => uint256[]) purchasedByUser;

    event MarketItemCreated(
        uint256 indexed itemId,
        uint256 assetType,
        address indexed assetContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 paymentMethod,
        uint256 price,
        bool sold,
        uint256 datePosted,
        uint256 dateSold
    );

    event MarketItemSold(
        uint256 indexed itemId,
        address seller,
        address owner,
        bool sold,
        uint256 datePosted,
        uint256 dateSold
    );

    bool public maintenanceMode;

    constructor(
        address anitoAddress,
        address stonesAddress,
        address duendeAddress,
        address _laroToken,
        address _busdToken,
        address _operationsAddress
    ) {
        allowedAssetList[anitoAddress] = true;
        allowedAssetList[stonesAddress] = true;
        allowedAssetList[duendeAddress] = true;

        assetTypes[anitoAddress] = ASSET_ERC721;
        assetTypes[duendeAddress] = ASSET_ERC721;

        assetTypes[stonesAddress] = ASSET_ERC1155;

        laroToken = IERC20(_laroToken);
        busdToken = IERC20(_busdToken);

        operationsAddress = _operationsAddress;
    }

    function setMaintenanceMode(bool _maintenanceMode) public onlyOwner {
        maintenanceMode = _maintenanceMode;
    }

    function setLaroFee(uint256 _laroFee) public onlyOwner {
        laroFee = _laroFee;
    }

    function setBusdFee(uint256 _busdFee) public onlyOwner {
        busdFee = _busdFee;
    }

    function updateOperationsAddress(
        address _operationsAddress
    ) public onlyOwner {
        operationsAddress = _operationsAddress;
    }

    function setAllowAsset(
        address _assetAddress,
        uint256 _assetType,
        bool allow
    ) public onlyOwner {
        allowedAssetList[_assetAddress] = allow;
        assetTypes[_assetAddress] = _assetType;
    }

    function createMarketItem(
        address assetContract,
        uint256 tokenId,
        uint256 paymentMethod,
        uint256 price,
        uint256 quantity
    ) public nonReentrant {
        require(!maintenanceMode, "Maintenance mode");
        require(price > 0, "Invalid price");
        require(allowedAssetList[assetContract], "Invalid asset");
        require(
            paymentMethod == LARO_TOKEN || paymentMethod == BUSD_TOKEN,
            "invalid payment method"
        );

        uint256 assetType = assetTypes[assetContract];

        if (assetType == ASSET_ERC721) {
            quantity = 1;
            IERC721(assetContract).safeTransferFrom(
                msg.sender,
                address(this),
                tokenId
            );
        }

        if (assetType == ASSET_ERC1155) {
            IERC1155(assetContract).safeTransferFrom(
                msg.sender,
                address(this),
                tokenId,
                quantity,
                ""
            );
        }

        _itemIds.increment();
        uint256 itemId = _itemIds.current();

        idToMarketItem[itemId] = MarketItem(
            itemId,
            assetType,
            assetContract,
            tokenId,
            msg.sender,
            address(0),
            paymentMethod,
            price,
            false,
            block.timestamp,
            0,
            quantity
        );

        listedByUser[msg.sender].push(itemId);

        emit MarketItemCreated(
            itemId,
            assetType,
            assetContract,
            tokenId,
            msg.sender,
            address(0),
            paymentMethod,
            price,
            false,
            block.timestamp,
            0
        );
    }

    function delistMarketItem(
        address assetContract,
        uint256 itemId
    ) public nonReentrant {
        require(!maintenanceMode, "Maintenance mode");
        require(msg.sender == idToMarketItem[itemId].seller, "NFT not owned");
        require(!idToMarketItem[itemId].sold, "NFT already sold");

        uint256 assetType = assetTypes[assetContract];

        if (assetType == ASSET_ERC721) {
            IERC721(assetContract).safeTransferFrom(
                address(this),
                msg.sender,
                idToMarketItem[itemId].tokenId
            );
        }

        if (assetType == ASSET_ERC1155) {
            IERC1155(assetContract).safeTransferFrom(
                address(this),
                msg.sender,
                idToMarketItem[itemId].tokenId,
                idToMarketItem[itemId].quantity,
                ""
            );
        }

        idToMarketItem[itemId].owner = msg.sender;
        idToMarketItem[itemId].sold = true;
        idToMarketItem[itemId].dateSold = block.timestamp;

        _itemsSold.increment();

        emit MarketItemSold(
            itemId,
            idToMarketItem[itemId].seller,
            msg.sender,
            true,
            idToMarketItem[itemId].datePosted,
            idToMarketItem[itemId].dateSold
        );
    }

    function createMarketSale(
        address assetContract,
        uint256 itemId
    ) public nonReentrant {
        require(!maintenanceMode, "Maintenance mode");
        require(idToMarketItem[itemId].tokenId != 0, "Invalid itemId");
        require(!idToMarketItem[itemId].sold, "NFT already sold");

        uint256 price = idToMarketItem[itemId].price;
        uint256 tokenId = idToMarketItem[itemId].tokenId;
        uint256 paymentMethod = idToMarketItem[itemId].paymentMethod;
        uint256 assetType = assetTypes[assetContract];

        if (paymentMethod == LARO_TOKEN) {
            uint256 toOperations = price.mul(laroFee).div(10000);
            uint256 netAmount = price - toOperations;
            laroToken.safeTransferFrom(msg.sender, address(this), price);
            laroToken.safeTransfer(idToMarketItem[itemId].seller, netAmount);
            laroToken.safeTransfer(operationsAddress, toOperations);
        }

        if (paymentMethod == BUSD_TOKEN) {
            uint256 toOperations = price.mul(busdFee).div(10000);
            uint256 netAmount = price - toOperations;
            busdToken.safeTransferFrom(msg.sender, address(this), price);
            busdToken.safeTransfer(idToMarketItem[itemId].seller, netAmount);
            busdToken.safeTransfer(operationsAddress, toOperations);
        }

        if (assetType == ASSET_ERC721) {
            IERC721(assetContract).safeTransferFrom(
                address(this),
                msg.sender,
                tokenId
            );
        }

        if (assetType == ASSET_ERC1155) {
            IERC1155(assetContract).safeTransferFrom(
                address(this),
                msg.sender,
                tokenId,
                idToMarketItem[itemId].quantity,
                ""
            );
        }

        idToMarketItem[itemId].owner = msg.sender;
        idToMarketItem[itemId].sold = true;
        idToMarketItem[itemId].dateSold = block.timestamp;

        _itemsSold.increment();

        purchasedByUser[msg.sender].push(itemId);

        emit MarketItemSold(
            itemId,
            idToMarketItem[itemId].seller,
            msg.sender,
            true,
            idToMarketItem[itemId].datePosted,
            idToMarketItem[itemId].dateSold
        );
    }

    function fetchLatestItemId() public view returns (uint256) {
        return _itemIds.current();
    }

    function fetchMarketItem(
        uint256 _itemId
    ) public view returns (MarketItem memory) {
        MarketItem memory currentMarketItem = idToMarketItem[_itemId];
        return currentMarketItem;
    }

    function fetchMarketItems(
        uint256[] memory itemIds
    ) public view returns (MarketItem[] memory) {
        MarketItem[] memory items = new MarketItem[](itemIds.length);
        for (uint256 i = 0; i < itemIds.length; i++) {
            MarketItem memory currentMarketItem = idToMarketItem[itemIds[i]];
            items[i] = currentMarketItem;
        }
        return items;
    }

    function fetchMyPurchasedItems(
        address account,
        uint256 cursor,
        uint256 size
    ) public view returns (uint256[] memory, MarketItem[] memory, uint256) {
        uint256 length = size;
        if (length > purchasedByUser[account].length - cursor) {
            length = purchasedByUser[account].length - cursor;
        }

        uint256[] memory values = new uint256[](length);
        MarketItem[] memory purchasedMarketItems = new MarketItem[](length);

        for (uint256 i = 0; i < length; i++) {
            values[i] = purchasedByUser[account][cursor + i];
            purchasedMarketItems[i] = idToMarketItem[values[i]];
        }

        return (values, purchasedMarketItems, cursor + length);
    }

    function fetchMyItemsListed(
        address account,
        uint256 cursor,
        uint256 size
    ) public view returns (uint256[] memory, MarketItem[] memory, uint256) {
        uint256 length = size;
        if (length > listedByUser[account].length - cursor) {
            length = listedByUser[account].length - cursor;
        }

        uint256[] memory values = new uint256[](length);
        MarketItem[] memory listedMarketItems = new MarketItem[](length);

        for (uint256 i = 0; i < length; i++) {
            values[i] = listedByUser[account][cursor + i];
            listedMarketItems[i] = idToMarketItem[values[i]];
        }

        return (values, listedMarketItems, cursor + length);
    }

    function fetchMyPurchasedItemIds(
        address account
    ) public view returns (uint256[] memory) {
        return purchasedByUser[account];
    }

    function fetchMyListedItemIds(
        address account
    ) public view returns (uint256[] memory) {
        return listedByUser[account];
    }
}