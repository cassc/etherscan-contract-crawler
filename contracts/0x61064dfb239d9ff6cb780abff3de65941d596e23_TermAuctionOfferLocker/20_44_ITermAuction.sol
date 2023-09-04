//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;

/// @title ITermAuction Term Auction interface
interface ITermAuction {
    function auctionCancelledForWithdrawal() external view returns (bool);
}