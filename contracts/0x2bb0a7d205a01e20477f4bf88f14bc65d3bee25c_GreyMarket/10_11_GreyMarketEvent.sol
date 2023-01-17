// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title GreyMarketEvent
 * @author @bldr
 * @notice The Grey Market is a Peer-To-Peer (P2P) marketplace platform designed to utilise
 *         blockchain technology for proof of transactions and allow users to trade items
 *         (physical/digital assets) using cryptocurrencies.
 */
contract GreyMarketEvent {
    event NewProofSigner(address newProofSigner);

    event OrderCreated(bytes32 id, address indexed buyer, address indexed seller, uint8 paymentType, uint8 orderType, uint256 blockTimestamp, uint256 amount);

    event OrderCancelled(bytes32 id, address indexed buyer, address indexed seller, uint256 blockTimestamp);

    event OrderCompleted(bytes32 id, address indexed buyer, address indexed seller, uint256 blockTimestamp);

    event OrderDisputeHandled(bytes32 id, address indexed buyer, address indexed seller, address winner, uint256 blockTimestamp);

    event NewEscrowFee(uint256 newEscrowFee);

    event NewEscrowPendingPeriod(uint256 newEscrowPendingPeriod);

    event NewEscrowLockPeriod(uint256 newEscrowLockPeriod);

    event NewAdmins(address[] newAdmins);

    event WithdrawAdminFee(address caller, address recipient, address token, uint256 amount);

    event WithdrawLockedFund(address caller, bytes32 orderId, address recipient, uint256 amount);

    event NewTransactionFee(uint256 newTransactionFee);
}