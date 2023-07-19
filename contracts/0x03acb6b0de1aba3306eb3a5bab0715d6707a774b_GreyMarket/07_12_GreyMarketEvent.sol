// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title gm.co Event
 * @author projectPXN
 * @notice gm.co is a Business-to-Consumer (B2C) and Peer-to-Peer (P2P) marketplace
 *         using blockchain technology for proof of transactions and allow users
 *         to buy and sell real world goods using cryptocurrency.
 */
contract GreyMarketEvent {
    event NewProofSigner(address newProofSigner);

    event OrderCreated(bytes32 id, address paymentType, uint256 amount);

    event OrderCancelled(bytes32 id);

    event OrderCompleted(bytes32 id);

    event WithdrawAdminFee(address token, uint256 amount);

}