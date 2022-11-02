// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IEscrow {
    function createOrder(
        uint256 _tokenId,
        uint256 _amount,
        address _erc20Address,
        address _tokenAddress,
        address _buyer,
        address _seller
    ) external payable returns (uint256);

    function Shipped(uint256 _orderId, uint256 _trackingId) external;

    function Received(uint256 _orderId, uint256 _trackingId) external;

    function claimPayout(uint256 _orderId, uint256 _trackingId) external;

    function cancelOrder(uint256 _orderId, uint256 _trackingId) external;

    function claimRefund(uint256 _orderId, uint256 _trackingId) external;

    function raiseDispute(uint256 _orderId) external;
}