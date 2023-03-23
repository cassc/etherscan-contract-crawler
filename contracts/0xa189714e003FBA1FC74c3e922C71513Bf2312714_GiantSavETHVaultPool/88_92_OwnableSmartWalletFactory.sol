// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {OwnableSmartWallet} from "./OwnableSmartWallet.sol";
import {IOwnableSmartWallet} from "./interfaces/IOwnableSmartWallet.sol";
import {IOwnableSmartWalletFactory} from "./interfaces/IOwnableSmartWalletFactory.sol";

/// @title Ownable smart wallet factory
contract OwnableSmartWalletFactory is IOwnableSmartWalletFactory {

    /// @dev Address of the contract to clone from
    address public immutable masterWallet;

    /// @dev Whether a wallet is created by this factory
    /// @notice Can be used to verify that the address is actually
    ///         OwnableSmartWallet and not an impersonating malicious
    ///         account
    mapping(address => bool) public walletExists;

    constructor() {
        masterWallet = address(new OwnableSmartWallet());

        emit WalletCreated(masterWallet, address(this)); // F: [OSWF-2]
    }

    function createWallet() external returns (address wallet) {
        wallet = _createWallet(msg.sender); // F: [OSWF-1]
    }

    function createWallet(address owner) external returns (address wallet) {
        wallet = _createWallet(owner); // F: [OSWF-1]
    }

    function _createWallet(address owner) internal returns (address wallet) {
        require(owner != address(0), 'Wallet cannot be address 0');

        wallet = Clones.clone(masterWallet);
        IOwnableSmartWallet(wallet).initialize(owner); // F: [OSWF-1]
        walletExists[wallet] = true;

        emit WalletCreated(wallet, owner); // F: [OSWF-1]
    }
}