// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./GreyMarketData.sol";

/**
 * @title gm.co Storage
 * @author projectPXN
 * @custom:coauthor bldr
 * @notice gm.co is a Business-to-Consumer (B2C) and Peer-to-Peer (P2P) marketplace
 *         using blockchain technology for proof of transactions and allow users
 *         to buy and sell real world goods using cryptocurrency.
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