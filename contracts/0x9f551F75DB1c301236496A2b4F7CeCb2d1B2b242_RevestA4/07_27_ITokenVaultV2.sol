// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

import "./ITokenVault.sol";

interface ITokenVaultV2 is ITokenVault {

    /// Emitted when an FNFT is created
    event CreateFNFT(uint indexed fnftId, address indexed from);

    /// Emitted when an FNFT is redeemed
    event RedeemFNFT(uint indexed fnftId, address indexed from);

    /// Emitted when an FNFT is created to denote what tokens have been deposited
    event DepositERC20(address indexed token, address indexed user, uint indexed fnftId, uint tokenAmount, address smartWallet);

    /// Emitted when an FNFT is withdraw  to denote what tokens have been withdrawn
    event WithdrawERC20(address indexed token, address indexed user, uint indexed fnftId, uint tokenAmount, address smartWallet);

    function getFNFTAddress(uint fnftId) external view returns (address smartWallet);

    function recordAdditionalDeposit(address user, uint fnftId, uint tokenAmount) external;

}