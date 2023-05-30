// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

interface IEscrow {
    event Withdrawal(uint256 indexed amount, address indexed withdrawer);
    event Deposit(uint256 indexed amount, address indexed depositer);
    event ClaimAuthorized(uint256 indexed claimId, address indexed claimant);
    event PrizeAdded(uint256 indexed claimId);
    event PrizeRemoved(uint256 indexed claimId, address indexed recipient);
    event PrizeReceived(uint256 indexed claimId, address indexed recipient);

    function currencyBalance() external returns (uint256);

    function deposit(address spender, uint256 amount) external;

    function withdraw(address recipient, uint256 amount) external;

    function authorizeClaim(uint256 claimId, address claimant) external;

    function claimFor(address claimant, uint256 claimId, address recipient) external;
}