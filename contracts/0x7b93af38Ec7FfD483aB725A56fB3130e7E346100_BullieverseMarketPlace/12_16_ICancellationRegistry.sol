//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

interface ICancellationRegistry {
    function addRegistrant(address registrant) external;

    function removeRegistrant(address registrant) external;

    function cancelOrder(bytes memory signature) external;

    function isOrderCancelled(bytes memory signature) external view returns (bool);

    function cancelPreviousSellOrders(address seller, address tokenAddr, uint256 tokenId) external;

    function getSellOrderCancellationBlockNumber(address addr, address tokenAddr, uint256 tokenId) external view returns (uint256);
}