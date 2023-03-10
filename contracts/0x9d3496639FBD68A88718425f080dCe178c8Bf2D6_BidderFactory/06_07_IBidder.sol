// SPDX-License-Identifier: GPL-3.0

import {IERC721} from "openzeppelin-contracts/token/ERC721/IERC721.sol";
import {INounsAuctionHouse} from "./external/interfaces/INounsAuctionHouse.sol";

pragma solidity 0.8.19;

interface IBidder {
    // Returned when a caller attempts to create a bid but this contract
    // is already the highest bidder
    error AlreadyHighestBidder();

    // Returned when the owner attempts to withdraw funds but the last auction bid
    // on has not been settled yet
    error AuctionNotSettled();

    // Returned when an attempt is made to place a bid that exceeds the max
    // configurable amount
    error MaxBidExceeded();

    // Returned when an attempt is made to withdraw a token that has not been bid on
    error NoBidFoundForToken(uint256 tokenId);

    // Returned when an attempt is made to place a bid outside of the auction
    // bid window
    error NotInBidWindow();

    // Returned when updating config that does not have the receiver set
    error InvalidReceiver();

    // Returned when an attempt to withdraw funds or update config has been made
    // and the last bidder was not tipped for winning the auction
    error TipOwed();

    // Emitted when a caller places a bid
    event BidMade(address caller, uint256 tokenId, uint256 amount);

    // Emitted when a caller receives a gas refund
    event GasRefund(address indexed caller, uint256 refundAmount, bool refundSent);

    // Emitted when a token is withdrawn and last bidder tipped
    event WithdrawAndTip(address indexed caller, address indexed tipTo, uint256 tokenId, uint256 tipAmount);

    // Emitted when config is updated
    event ConfigUpdate(Config config);

    // The structure of the config for this bidder
    struct Config {
        // Max bid that can be placed in an auction
        uint256 maxBid;
        // Min bid that can be placed in an auction
        uint256 minBid;
        // Time in seconds a bid can be placed before auction end time
        uint256 bidWindow;
        // Tip rewarded for caller winning auction
        uint256 tip;
        // Address that will receive tokens when withdrawn
        address receiver;
    }

    function initialize(IERC721, INounsAuctionHouse, address, Config memory) external payable;

    function bid() external returns (uint256, uint256);

    function withdraw(uint256) external;

    function withdrawBalance() external;

    function pause() external;

    function unpause() external;

    function setConfig(Config calldata) external;

    function getConfig() external view returns (Config memory);

    function getLastBidder(uint256) external view returns (address);
}