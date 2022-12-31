// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IMarketGeneral.sol";

contract MarketGeneralBase is IMarketGeneral, Ownable {
    using SafeERC20 for IERC20;

    mapping(uint256 => Offer) public offers; // nonce => Offer
    mapping(uint256 => AuctionInfo) public auctionInfos; // nonce => AuctionInfo
    mapping(uint256 => BidInfo) public bidInfos; // nonce => Bid Info
    mapping(uint256 => mapping(address => bool)) offerCurrencies; // offer nonce => currency address

    modifier notContract() {
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    modifier _offerValid(uint256 nonce) {
        require(offers[nonce].status == OfferStatus.Open, "offer not active");
        require(
            block.timestamp >= offers[nonce].startTime &&
                block.timestamp <= offers[nonce].endTime,
            "offer is not start or already end"
        );
        _;
    }

    modifier _offerOwner(uint256 nonce) {
        require(offers[nonce].maker == msg.sender, "call should own the offer");
        _;
    }

    modifier _checkCurrencyValidity(address currency, uint256 amount) {
        require(
            IERC20(currency).allowance(msg.sender, address(this)) >= amount,
            "not enough allowance"
        );
        require(
            IERC20(currency).balanceOf(msg.sender) >= amount,
            "not enough balance"
        );
        _;
    }

    modifier _checkLastOffer(uint256 nonce) {
        if (offers[nonce].maker != address(0)) {
            require(
                offers[nonce].maker == msg.sender,
                "caller should own the offer"
            );
        }
        _;
    }
}