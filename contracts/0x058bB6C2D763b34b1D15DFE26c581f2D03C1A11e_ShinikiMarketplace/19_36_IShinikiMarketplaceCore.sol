// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "../lib/LibOrderData.sol";

interface IShinikiMarketplaceCore {
    //events
    event Cancel(uint256 salt, bytes4 typeOrder, bytes32 hash);
    event Match(
        address from,
        uint256 salt,
        bytes4 typeOffer,
        uint256 newLeftFill,
        uint256 newRightFill
    );
    event MatchAuction(
        address from,
        uint256 saltLeft,
        uint256 saltRight,
        uint256 newLeftFill,
        uint256 newRightFill
    );

    function cancel(LibOrder.Order memory order) external;

    /**
        @notice verify signature and match orders 
        @param orderLeft the left order of the match
        @param signatureLeft the signature of left order
        @param orderRight the right order of the match
        @param signatureRight the signature of right order
     */
    function matchOrders(
        LibOrder.Order memory orderLeft,
        bytes memory signatureLeft,
        LibOrder.Order memory orderRight,
        bytes memory signatureRight
    ) external payable;

    /**
        @notice verify signature and match batch orders 
        @param batchOrder the left order of the match
     */
    function matchBatchOrders(LibOrder.BatchOrder[] memory batchOrder)
        external
        payable;

    /**
        @notice verify signature and match auction orders 
        @param orderLeft the left order of the match
        @param signatureLeft the signature of left order
        @param orderRight the right order of the match
        @param signatureRight the signature of right order
     */
    function auctionOrder(
        LibOrder.Order memory orderLeft,
        bytes memory signatureLeft,
        LibOrder.Order memory orderRight,
        bytes memory signatureRight
    ) external;
}