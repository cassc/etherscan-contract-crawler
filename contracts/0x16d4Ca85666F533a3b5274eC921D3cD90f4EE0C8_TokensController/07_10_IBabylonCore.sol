// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8.0;

interface IBabylonCore {
    enum ItemType {
        ERC721,
        ERC1155
    }

    struct ListingItem {
        ItemType itemType;
        address token;
        uint256 identifier;
        uint256 amount;
    }

    /**
     * @dev Indicates state of a listing.
    */
    enum ListingState {
        Active,
        Resolving,
        Successful,
        Finalized,
        Canceled
    }

    /**
     * @dev Contains all information for a specific listing.
    */
    struct ListingInfo {
        ListingItem item;
        ListingState state;
        address creator;
        address claimer;
        address mintPass;
        uint256 randomRequestId;
        uint256 price;
        uint256 timeStart;
        uint256 totalTickets;
        uint256 currentTickets;
        uint256 creationTimestamp;
    }

    function resolveClaimer(
        uint256 id,
        uint256 random
    ) external;

    function getListingInfo(uint256 id) external view returns (ListingInfo memory);
}