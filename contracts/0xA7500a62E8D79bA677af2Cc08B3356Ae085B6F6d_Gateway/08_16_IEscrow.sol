// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IEscrow {
    struct Escrow {
        uint256 productId;
        address buyerAddress;
        address merchantAddress;
        uint256 amount;
        uint256 escrowWithdrawableTime;
        uint256 escrowDisputableTime;
        uint256 status;
        uint256 createdAt;
    }
    event Escrowed(
        address indexed _from,
        uint256 indexed _productID,
        uint256 _amount,
        uint256 indexed _escrowId
    );
    event Withdraw(
        address indexed _withdrawer,
        uint256 indexed _escrowId,
        uint256 _amount
    );
    event Refunded(
        address indexed _withdrawer,
        uint256 indexed _escrowId,
        uint256 _amount
    );
}