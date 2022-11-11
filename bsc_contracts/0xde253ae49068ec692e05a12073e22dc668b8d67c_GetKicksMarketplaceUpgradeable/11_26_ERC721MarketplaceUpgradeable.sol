// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

library ERC721MarketplaceUpgradeable {
    // Enum representing collection category
    // None  - 0
    // Character  - 1
    // Room  - 2
    // Office  - 3
    // Furniture - 4
    // Wearable - 5
    // Badge - 6
    // Consumable - 7
    // Background - 8
    enum Category {
        None,
        Character,
        Room,
        Office,
        Furniture,
        Wearable,
        Badge,
        Consumable,
        Background
    }

    // Enum representing listing status
    // None - 0
    // Added - 1
    // Cancelled - 2
    // Executed - 3
    // Removed - 4
    // Pending - 5
    // Blocked - 6
    enum Status {
        None,
        Added,
        Cancelled,
        Executed,
        Removed,
        Pending,
        Blocked
    }

    struct ERC721Listing {
        uint256 listingId;
        address seller;
        address erc721TokenAddress;
        uint256 erc721TokenId;
        Category category;
        uint256 priceInWei;
        uint256 timeAdded;
        uint256 timeCancelled;
        uint256 timePurchased;
        Status status;
    }

    struct ListingListItem {
        uint256 parentListingId;
        uint256 listingId;
        uint256 childListingId;
    }

    struct AppStorage {
        uint256[] _listingIds;
        mapping(uint256 => uint256) listingIdIndex;
        mapping(address => Category) erc721Categories;
        mapping(uint256 => ERC721Listing) erc721Listings;
        mapping(uint256 => ListingListItem) erc721ListingListItem;
        mapping(uint256 => ListingListItem) erc721OwnerListingListItem;
        mapping(uint256 => mapping(string => uint256)) erc721ListingHead;
        mapping(address => mapping(uint256 => mapping(string => uint256))) erc721OwnerListingHead;
        mapping(address => mapping(uint256 => mapping(address => uint256))) erc721TokenToListingId;
    }

    event ERC721ListingCancelled(uint256 indexed listingId, Category category, uint256 timeCancelled, Status status);
    event ERC721ListingRemoved(uint256 indexed listingId, Category category, uint256 timeRemoved, Status status);
    event StatusChanged(uint256 listingId, ERC721MarketplaceUpgradeable.Status status);

    function appStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }

    function getAllListingIds(AppStorage storage self) internal view returns (uint256[] memory) {
        return self._listingIds;
    }

    function totalListingIds(AppStorage storage self) internal view returns (uint256) {
        return self._listingIds.length;
    }

    //return the index of listingId
    function getListingIdIndex(AppStorage storage self, uint256 listingId) internal view returns (uint256) {
        return self.listingIdIndex[listingId];
    }

    function getErc721Categories(AppStorage storage self, address erc721TokenAddress) internal view returns (Category) {
        return self.erc721Categories[erc721TokenAddress];
    }

    function getErc721OwnerListingHead(
        AppStorage storage self,
        address mOwner,
        uint256 category,
        string memory sort
    ) internal view returns (uint256) {
        return self.erc721OwnerListingHead[mOwner][category][sort];
    }

    function getErc721TokenToListingId(
        AppStorage storage self,
        address erc721TokenAddress,
        uint256 erc721TokenId,
        address owner
    ) internal view returns (uint256) {
        return self.erc721TokenToListingId[erc721TokenAddress][erc721TokenId][owner];
    }

    function getErc721ListingHead(
        AppStorage storage self,
        uint256 category,
        string memory sort
    ) internal view returns (uint256) {
        return self.erc721ListingHead[category][sort];
    }

    function getErc721OwnerListingListItem(AppStorage storage self, uint256 listingId)
        internal
        view
        returns (ListingListItem storage)
    {
        return self.erc721OwnerListingListItem[listingId];
    }

    function getERC721ListingListItem(AppStorage storage self, uint256 listingId)
        internal
        view
        returns (ListingListItem storage)
    {
        return self.erc721ListingListItem[listingId];
    }

    ///@notice Get an ERC721 listing details through an identifier
    ///@dev Will throw if the listing does not exist
    ///@param listingId The identifier of the ERC721 listing to query
    ///@return listing_ A struct containing certain details about the ERC721 listing like timeAdded etc
    function _getERC721Listing(AppStorage storage self, uint256 listingId)
        internal
        view
        returns (ERC721Listing storage)
    {
        return self.erc721Listings[listingId];
    }

    function addCollectionCategory(
        AppStorage storage self,
        address erc721TokenAddress,
        Category category
    ) internal returns (bool) {
        if (
            erc721TokenAddress != address(0) &&
            uint256(category) <= 8 &&
            category != getErc721Categories(self, erc721TokenAddress)
        ) {
            self.erc721Categories[erc721TokenAddress] = category;
            return true;
        }
        return false;
    }

    function addERC721ListingItem(
        AppStorage storage self,
        address owner,
        uint256 category,
        string memory sort,
        uint256 listingId
    ) internal {
        uint256 headListingId = self.erc721OwnerListingHead[owner][category][sort];
        if (headListingId != 0) {
            ListingListItem storage headListingItem = self.erc721OwnerListingListItem[headListingId];
            headListingItem.parentListingId = listingId;
        }
        ListingListItem storage listingItem = self.erc721OwnerListingListItem[listingId];
        listingItem.childListingId = headListingId;
        self.erc721OwnerListingHead[owner][category][sort] = listingId;
        listingItem.listingId = listingId;

        headListingId = self.erc721ListingHead[category][sort];
        if (headListingId != 0) {
            ListingListItem storage headListingItem2 = self.erc721ListingListItem[headListingId];
            headListingItem2.parentListingId = listingId;
        }
        listingItem = self.erc721ListingListItem[listingId];
        listingItem.childListingId = headListingId;
        self.erc721ListingHead[category][sort] = listingId;
        listingItem.listingId = listingId;

        uint256 index = totalListingIds(self) + 1; // mapping index starts with 1
        self._listingIds.push(listingId);
        self.listingIdIndex[listingId] = index;
    }

    function cancelERC721Listing(
        AppStorage storage self,
        uint256 listingId,
        address owner
    ) internal returns (bool) {
        ListingListItem storage listingItem = self.erc721ListingListItem[listingId];
        ERC721Listing storage listing = self.erc721Listings[listingId];
        if (listingItem.listingId != 0 && listing.status != Status.Cancelled && listing.timePurchased == 0) {
            listing.timeCancelled = block.timestamp;
            changeListingStatus(self, listingItem.listingId, Status.Cancelled);
            emit ERC721ListingCancelled(listingId, listing.category, block.timestamp, Status.Cancelled);
            return removeERC721ListingItem(self, listingId, owner);
        } else {
            return false;
        }
    }

    function cancelERC721ListingByToken(
        AppStorage storage self,
        address erc721TokenAddress,
        uint256 erc721TokenId,
        address owner
    ) internal returns (bool) {
        uint256 listingId = self.erc721TokenToListingId[erc721TokenAddress][erc721TokenId][owner];
        if (listingId > 0) {
            return cancelERC721Listing(self, listingId, owner);
        }
        return false;
    }

    function removeERC721ListingItem(
        AppStorage storage self,
        uint256 listingId,
        address owner
    ) internal returns (bool) {
        ListingListItem storage listingItem = self.erc721ListingListItem[listingId];
        if (listingItem.listingId == 0) {
            return false;
        }
        uint256 parentListingId = listingItem.parentListingId;
        if (parentListingId != 0) {
            ListingListItem storage parentListingItem = self.erc721ListingListItem[parentListingId];
            parentListingItem.childListingId = listingItem.childListingId;
        }
        uint256 childListingId = listingItem.childListingId;
        if (childListingId != 0) {
            ListingListItem storage childListingItem = self.erc721ListingListItem[childListingId];
            childListingItem.parentListingId = listingItem.parentListingId;
        }
        ERC721Listing storage listing = self.erc721Listings[listingId];
        if (self.erc721ListingHead[uint256(listing.category)]["listed"] == listingId) {
            self.erc721ListingHead[uint256(listing.category)]["listed"] = listingItem.childListingId;
        }
        listingItem.listingId = 0;
        listingItem.parentListingId = 0;
        listingItem.childListingId = 0;

        listingItem = self.erc721OwnerListingListItem[listingId];

        parentListingId = listingItem.parentListingId;
        if (parentListingId != 0) {
            ListingListItem storage parentListingItem = self.erc721OwnerListingListItem[parentListingId];
            parentListingItem.childListingId = listingItem.childListingId;
        }
        childListingId = listingItem.childListingId;
        if (childListingId != 0) {
            ListingListItem storage childListingItem = self.erc721OwnerListingListItem[childListingId];
            childListingItem.parentListingId = listingItem.parentListingId;
        }
        listing = self.erc721Listings[listingId];
        if (self.erc721OwnerListingHead[owner][uint256(listing.category)]["listed"] == listingId) {
            self.erc721OwnerListingHead[owner][uint256(listing.category)]["listed"] = listingItem.childListingId;
        }
        listingItem.listingId = 0;
        listingItem.parentListingId = 0;
        listingItem.childListingId = 0;

        uint256 index = getListingIdIndex(self, listingId);
        uint256 arrayIndex = index - 1;
        if (arrayIndex != totalListingIds(self) - 1) {
            self._listingIds[arrayIndex] = self._listingIds[totalListingIds(self) - 1];
            self.listingIdIndex[self._listingIds[arrayIndex]] = index;
        }
        self._listingIds.pop();
        delete self.listingIdIndex[listingId];
        emit ERC721ListingRemoved(listingId, listing.category, block.timestamp, Status.Removed);
        return true;
    }

    function updateERC721Listing(
        AppStorage storage self,
        address erc721TokenAddress,
        uint256 erc721TokenId,
        address owner
    ) internal returns (bool) {
        uint256 listingId = self.erc721TokenToListingId[erc721TokenAddress][erc721TokenId][owner];
        ERC721Listing storage listing = self.erc721Listings[listingId];
        if (
            listingId == 0 &&
            listing.timePurchased != 0 &&
            listing.status == Status.Cancelled &&
            owner == listing.seller &&
            owner != IERC721Upgradeable(listing.erc721TokenAddress).ownerOf(listing.erc721TokenId)
        ) {
            return false;
        }
        return cancelERC721Listing(self, listingId, listing.seller);
    }

    function changeListingStatus(
        AppStorage storage self,
        uint256 mListingId,
        Status status
    ) internal {
        ERC721Listing storage listing = self.erc721Listings[mListingId];
        listing.status = status;
        emit StatusChanged(mListingId, status);
    }
}