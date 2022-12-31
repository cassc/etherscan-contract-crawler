// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAuctionManager {
    function bid(
        uint256 nonce,
        uint256 amount,
        address bidder
    ) external;

    function getHighestBidder(uint256 nonce)
        external
        view
        returns (address, uint256);

    function getWithdrawAmount(uint256 nonce, address bidder)
        external
        returns (uint256);
}