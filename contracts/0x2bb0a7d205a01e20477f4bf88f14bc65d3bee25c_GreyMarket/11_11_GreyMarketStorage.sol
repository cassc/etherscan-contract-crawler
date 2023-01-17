// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./GreyMarketData.sol";

/**
 * @title GreyMarketStorage
 * @author @bldr
 * @notice The Grey Market is a Peer-To-Peer (P2P) marketplace platform designed to utilise
 *         blockchain technology for proof of transactions and allow users to trade items
 *         (physical/digital assets) using cryptocurrencies.
 */
contract GreyMarketStorage {
    address public proofSigner;

    address[] public admins;

    uint256 public transactionFee = 5000;

    uint256 public defaultEscrowFee = 2900;

    uint256 public escrowPendingPeriod;

    uint256 public escrowLockPeriod;

    mapping(address => uint256) public adminFees;

    mapping(address => uint256) public escrowFees;

    mapping(bytes32 => OrderInfo) public orders;

    mapping(address => bool) public paymentTokens;
}