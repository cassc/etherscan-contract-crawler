//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../library/Types.sol";

interface IMarketStateManager {
    struct MarketItemStruct {
        uint256 itemId;
        Types.TokenStandard tokenStandard;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price; // lowest price for open for bids and timed auction
        uint256 tokenAmount; // for ERC1155
        uint256 inventoryBalance; // inventory balance for items remaining (if ERC721, inventory balance == 1)
        Types.PaymentMethod paymentMethod;
        bool sold;
        uint256 numSold; // for ERC1155
        Types.PaymentOptions paymentOption;
        uint256 auctionEndTime; // only for timed auction
    }

    struct BidStruct {
        address user;
        uint256 amount;
        uint256 itemId;
        bool active;
        bool isAccepted;
        uint256 time;
    }

    struct CreatorStruct {
        address payable creator;
        uint256 royalty;
    }

    function allowBRN() external view returns (bool);

    function BRN() external view returns (address);

    function updateMarketAddress(address _newMarketAddress) external;

    function updateListingPrice(uint256 _amount) external;

    function updateSalesCommission(uint256 _commission) external;

    function getMarketContracts() external view returns (address[] memory);

    function getRate() external view returns (uint256, uint256);

    function getListingPrice() external view returns (uint256);

    function getSalesCommission() external view returns (uint256);

    function getItemsCount() external view returns (uint256);

    function updateItemsCount() external;

    function getSoldItemsCount() external view returns (uint256);

    function updateSoldItemsCount() external;

    function getIsMarketContract(
        address nftContract
    ) external view returns (bool);

    function updateMarketContractsList(address nftContract) external;

    function getTokenToCreatorStruct(
        address nftContract,
        uint tokenId
    ) external view returns (IMarketStateManager.CreatorStruct memory);

    function updateTokenToCreatorStruct(
        address user,
        address nftContract,
        uint tokenId,
        uint royalty
    ) external;

    function getItemIdToMarketplaceMapping(
        uint256 _itemId
    ) external view returns (IMarketStateManager.MarketItemStruct memory);

    function addItemIdToMarketplaceMapping(
        uint256 _itemId,
        IMarketStateManager.MarketItemStruct memory _marketItemStruct
    ) external;

    function updateItemIdToMarketplaceMapping(
        uint256 _itemId,
        IMarketStateManager.MarketItemStruct memory _marketItemStruct
    ) external;

    function addItemBid(
        uint256 _itemId,
        IMarketStateManager.BidStruct memory _itemBidStruct
    ) external;

    function getItemBids(
        uint256 _itemId
    ) external view returns (IMarketStateManager.BidStruct[] memory);

    function updateItemBidStatus(
        uint256 _itemId,
        uint index,
        bool status
    ) external;

    function updateItemBidAccepted(
        uint256 _itemId,
        uint index,
        bool accepted
    ) external;

    function addUserBid(
        address user,
        IMarketStateManager.BidStruct memory _userBidStruct
    ) external;

    function getUserBids(
        address user
    ) external view returns (IMarketStateManager.BidStruct[] memory);

    function updateUserBidStatus(
        address user,
        uint index,
        bool status
    ) external;

    function updateUserBidAccepted(
        address user,
        uint index,
        bool accepted
    ) external;

    function fetchMarketItems()
        external
        view
        returns (IMarketStateManager.MarketItemStruct[] memory);

    function getCollectionSalesData(
        address nftContract
    ) external view returns (uint256 floorPrice, uint256 totalSalesUSD);

    function fetchMarketItemsFromCollection(
        address collectionAddress
    ) external view returns (IMarketStateManager.MarketItemStruct[] memory);

    function fetchNFTDetailsFromMarket(
        address nftContract,
        uint256 tokenId
    ) external view returns (IMarketStateManager.MarketItemStruct[] memory);
}