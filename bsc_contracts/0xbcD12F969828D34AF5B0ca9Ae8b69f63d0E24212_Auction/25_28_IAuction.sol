//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IAuction
 * @author gotbit
 */

import './INFTAssist.sol';

interface IAuction is INFTAssist {
    enum Status {
        NULL,
        ACTIVE,
        FINISHED,
        CANCELED
    }

    enum UserLotType {
        NULL,
        PLACED,
        BID,
        FINISH,
        CANCELED
    }

    enum Direction {
        NULL,
        SELL,
        BUY
    }

    struct Step {
        uint256 value;
        bool inPercents;
    }

    struct BonusTime {
        uint256 left;
        uint256 bonus;
    }

    struct Parameters {
        uint256 startPrice;
        uint256 startTimestamp;
        uint256 finishPrice;
        address tokenAddress;
        uint256 period;
        Step step;
        BonusTime bonusTime;
    }

    struct Bid {
        uint256 id;
        address bidder;
        uint256 amount;
        uint256 timestamp;
    }

    struct Lot {
        uint256 id;
        address owner;
        uint256 startTimestamp;
        address lastBidder;
        uint256 lastBid;
        NFT nft;
        Parameters parameters;
        Status status;
    }

    struct LotOutput {
        Lot lot;
        Bid[] bids;
    }

    struct UserActivity {
        uint256 timestamp;
        Lot lot;
        address user;
        uint256 amount;
        Direction direction;
    }

    struct UserLot {
        uint256 timestamp;
        Lot lot;
        address user;
        UserLotType userLotType;
    }

    struct UserHistory {
        uint256 timestamp;
        Lot lot;
        address user;
        uint256 amount;
        Direction direction;
    }

    /// @dev Adds new lot structure in array, gets nft from nft owner and sets parameters
    /// @param nft address of nft to be placed on auction
    /// @param tokenId token if of nft address to be placed on auction
    /// @param parameters_ parameters of this nft auction act
    function createLot(
        address nft,
        uint256 tokenId,
        Parameters memory parameters_
    ) external;

    /// @dev Cancels selected nft lot, sends back last bit to last bidder
    /// @param lotId id of the lot to be canceled
    function cancelLot(uint256 lotId) external;

    /// @dev Finishes the lot, lot owner gets profit, bidder gets nft, can be called only from lot owner
    /// @param lotId id of the lot to finish
    function finishLot(uint256 lotId) external;

    /// @dev Finishes the lot, lot owner gets profit, bidder gets nft,
    /// can be called if lot time is passed or finishPrice is reached
    /// @param lotId id of the lot to finish
    function claim(uint256 lotId) external;

    /// @dev Bids higher tokens amount on selected lot, last bidder gets his bid back, and caller becomes last bidder
    /// @param lotId id of the lot to bid on
    /// @param bid_ new higher than previos tokens amount
    function bid(uint256 lotId, uint256 bid_) external;

    /// @dev Bids higher eth amount on selected lot, last bidder gets his eth bid back,
    /// and caller becomes last bidder, enabled only if token in lot parameters is weth
    /// @param lotId id of the lot to bid on
    function bidETH(uint256 lotId) external payable;

    /// @dev Resturns lot with specific `lotId` with bids
    /// @param lotId id of lot
    function getLot(uint256 lotId) external view returns (LotOutput memory);

    /// @dev Resturns lot with specific `lotId`
    /// @param lotId id of lot
    function getLotNFT(uint256 lotId) external view returns (Lot memory);

    /// @dev Returns array of lots with `offset` and `limit`
    /// @param offset start index
    /// @param limit length of array
    function lots(uint256 offset, uint256 limit)
        external
        view
        returns (LotOutput[] memory);

    /// @dev Returns array of lots with `offset` and `limit` with status `status`
    /// @param offset start index
    /// @param limit length of array
    /// @param status status of lot
    function lotsStatus(
        uint256 offset,
        uint256 limit,
        Status status
    ) external view returns (LotOutput[] memory);

    /// @dev Allows to get all activites for user
    /// @param user addres of user
    /// @param offset start index
    /// @param limit length of array
    function getActivities(
        address user,
        uint256 offset,
        uint256 limit
    ) external view returns (UserActivity[] memory);

    /// @dev Allows to get lot ids of user's lots
    /// @param user address to get his lots
    /// @param offset start index
    /// @param limit length of array
    /// @return ids of all user lots
    function userLots(
        address user,
        uint256 offset,
        uint256 limit
    ) external view returns (uint256[] memory);

    /// @dev Allows to get ids of lots user bidded on
    /// @param user address who bidded
    /// @param offset start index
    /// @param limit length of array
    /// @return ids of user lots he bidded
    function userBids(
        address user,
        uint256 offset,
        uint256 limit
    ) external view returns (uint256[] memory);
}