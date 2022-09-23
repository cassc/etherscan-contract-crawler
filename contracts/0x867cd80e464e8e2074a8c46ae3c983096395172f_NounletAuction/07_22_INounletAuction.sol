// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IModule, Permission} from "./IModule.sol";

/// @dev Auction information
struct Auction {
    // Address of the highest bidder
    address bidder;
    // Amount of the highest bid
    uint64 amount;
    // End time of the auction
    uint32 endTime;
}

/// @dev Vault information
struct Vault {
    // Address of the vault curator
    address curator;
    // Current ID of the token
    uint96 currentId;
}

/// @dev Interface for NounletAuction contract
interface INounletAuction is IModule {
    /// @dev Emitted when the auction has already been created for the first Nounlet of a Noun
    error AuctionAlreadyCreated();
    /// @dev Emitted when the auction has not completed
    error AuctionNotCompleted();
    /// @dev Emitted when the auction has already ended
    error AuctionExpired();
    /// @dev Emitted when the minimum bid increase has not been met
    error InvalidBidIncrease();
    /// @dev Emitted when the caller is the not the auction winner
    error NotWinner();

    /// @dev Event log for creating a new auction
    /// @param _vault Address of the vault
    /// @param _token Address of the token contract
    /// @param _id ID of the token
    /// @param _endTime End time of the auction
    event Created(
        address indexed _vault,
        address indexed _token,
        uint256 indexed _id,
        uint256 _endTime
    );

    /// @dev Event log for bidding on an auction
    /// @param _vault Address of the vault
    /// @param _token Address of the token contract
    /// @param _id ID of the token
    /// @param _bidder Address of the bidder
    /// @param _value Ether value of the current bid
    /// @param _endTime New end time if bid is placed in final 10 minutes
    event Bid(
        address indexed _vault,
        address indexed _token,
        uint256 indexed _id,
        address _bidder,
        uint256 _value,
        uint256 _endTime
    );

    /// @dev Event log for settling a finished auction
    /// @param _vault Address of the vault
    /// @param _token Address of the token contract
    /// @param _id ID of the token
    /// @param _winner Address of the highest bidder at auction end
    /// @param _amount Ether value of the highest bid at auction end
    event Settled(
        address indexed _vault,
        address indexed _token,
        uint256 indexed _id,
        address _winner,
        uint256 _amount
    );

    function DURATION() external view returns (uint48);

    function MIN_INCREASE() external view returns (uint48);

    function TIME_BUFFER() external view returns (uint48);

    function TOTAL_SUPPLY() external view returns (uint48);

    function auctionInfo(address, uint256)
        external
        view
        returns (
            address bidder,
            uint64 bid,
            uint32 endTime
        );

    function bid(address _vault) external payable;

    function registry() external view returns (address);

    function createAuction(
        address _vault,
        address _curator,
        bytes32[] calldata _mintProof
    ) external;

    function settleAuction(address _vault, bytes32[] calldata _mintProof) external;

    function vaultInfo(address) external view returns (address curator, uint96 currentId);
}