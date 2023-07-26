// #region Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions
// #endregion

// SPDX-License-Identifier: UNLICENCED
pragma solidity 0.8.20;
import "delegate.cash/IDelegationRegistry.sol";

// #region errors
error WalletNotDelegated(address hotWallet, address vault);

// #endregion

contract DelegateUtils {
    // the delegation registry contract
    IDelegationRegistry public immutable delegationRegistry;

    constructor(address _registryAddress) {
        // initialize the delegation registry
        delegationRegistry = IDelegationRegistry(_registryAddress);
    }

    modifier isDelegated(address vault) {
        _checkDelegation(vault, address(this));
        _;
    }

    function _checkDelegation(address vault, address _contract) internal view {
        // check that the caller delegated to the vault
        if (!delegationRegistry.checkDelegateForContract(msg.sender, vault, _contract)) {
            revert WalletNotDelegated(msg.sender, vault);
        }
    }
}