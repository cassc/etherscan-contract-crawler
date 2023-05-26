// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "@kyber.network/utils-sc/contracts/IERC20Ext.sol";
import "@kyber.network/utils-sc/contracts/Utils.sol";
import "@kyber.network/utils-sc/contracts/Withdrawable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

contract SmartWalletStorage is Utils, Withdrawable, ReentrancyGuard {
    uint256 internal constant MAX_AMOUNT = type(uint256).max;

    mapping(address => mapping(IERC20Ext => uint256)) public platformWalletFees;

    EnumerableSet.AddressSet internal supportedPlatformWallets;
    
    EnumerableSet.AddressSet internal supportedSwaps;

    EnumerableSet.AddressSet internal supportedLendings;

    // [EIP-1967] bytes32(uint256(keccak256("SmartWalletImplementation")) - 1)
    bytes32 internal constant IMPLEMENTATION =
        0x7cf58d76330f82325c2a503c72b55abca3eb533fadde43d95e3c0cceb1583e99;

    constructor(address _admin) Withdrawable(_admin) {}
}