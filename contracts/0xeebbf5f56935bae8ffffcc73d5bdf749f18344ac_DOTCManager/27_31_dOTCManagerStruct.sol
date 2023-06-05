// solhint-disable
//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.17;

import "./OfferType.sol";

/**
 * @dev dOTC Offer stucture
 * @author Swarm
 */
struct dOTCOffer {
    address maker;
    address cpk;
    uint256 offerId;
    bool fullyTaken;
    address[2] tokenInTokenOut; // Tokens to exchange
    uint256[2] amountInAmountOut; // Amount of tokens
    uint256 availableAmount; // available amount
    uint256 unitPrice;
    OfferType offerType; // can be PARTIAL or FULL
    address specialAddress; // makes the offer avaiable for one account.
    uint256 expiryTime;
    uint256 timelockPeriod;
}

/**
 * @dev dOTC Order stucture
 * @author Swarm
 */
struct Order {
    uint256 offerId;
    uint256 amountToSend; // the amount the taker sends to the maker
    address takerAddress;
    uint256 amountToReceive;
    uint256 minExpectedAmount; // the amount the taker is to recieve
}