// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title gm.co Event
 * @author projectPXN
 * @custom:coauthor bldr
 * @notice gm.co is a Business-to-Consumer (B2C) and Peer-to-Peer (P2P) marketplace
 *         using blockchain technology for proof of transactions and allow users
 *         to buy and sell real world goods using cryptocurrency.
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