// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

interface IBabylon7Core {
    /// @dev Indicates type of a token
    enum ItemType {
        ERC721,
        ERC1155
    }

    /// @dev Storage struct that contains all information about raffled token
    struct ListingItem {
        /// @dev Type of a token
        ItemType itemType;
        /// @dev Address of a token
        address token;
        /// @dev Token identifier
        uint256 identifier;
        /// @dev Amount of tokens
        uint256 amount;
    }

    /// @dev Indicates state of a listing
    enum ListingState {
        Active,
        Resolving,
        Successful,
        Finalized,
        Canceled
    }

    /// @dev Storage struct that contains all required information for a specific listing
    struct ListingInfo {
        /// @dev Token that is provided for a raffle
        ListingItem item;
        /// @dev Indicates current state of a listing
        ListingState state;
        /// @dev Address of a listing creator
        address creator;
        /// @dev Address of a listing winner
        address winner;
        /// @dev ETH price per 1 ticket
        uint256 price;
        /// @dev Timestamp when listing starts
        uint256 timeStart;
        /// @dev Total amount of tickets to be sold
        uint256 totalTickets;
        /// @dev Current amount of sold tickets
        uint256 currentTickets;
        /// @dev Basis points of donation
        uint256 donationBps;
        /// @dev Requiest id from Chainlink VRF
        uint256 randomRequestId;
        /// @dev Timestamp of creation
        uint256 creationTimestamp;
    }

    /// @dev Storage struct that contains all restriction for a specific listing
    struct ListingRestrictions {
        /// @dev Root of an allowlist Merkle tree
        bytes32 allowlistRoot;
        /// @dev Amount of tickets reserved for an allowlist
        uint256 reserved;
        /// @dev Amount of tickets bought by allowlisted users
        uint256 mintedFromReserve;
        /// @dev Amount of maximum tickets per 1 address
        uint256 maxPerAddress;
    }

    /// @notice Determines the winner of a raffle based on the provided random number, then transfers
    /// the item to the winner
    /// @dev called by the Chainlink VRF service only through the Random Provider contract
    /// @param id identifier of a listing
    /// @param random a random number provided by the Chainlink VRF
    function resolveWinner(uint256 id, uint256 random) external;

    /// @notice Returns all info about a listing with a specific id
    /// @param id identifier of a listing
    /// @return ListingInfo struct for a listing
    function getListingInfo(uint256 id) external view returns (ListingInfo memory);
}