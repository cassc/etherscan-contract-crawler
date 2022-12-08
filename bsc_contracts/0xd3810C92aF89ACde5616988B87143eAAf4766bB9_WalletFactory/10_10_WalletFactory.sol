// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/IWalletFactory.sol";
import "./ManagedVestingWallet.sol";


/**
 * @title WalletFactory
 * @dev Used to reduce crowdsale conract size.
 */
contract WalletFactory is IWalletFactory {

    function createManagedVestingWallet(address beneficiary, address vestingManager) public returns (address) {
        ManagedVestingWallet wallet = new ManagedVestingWallet(beneficiary, vestingManager);
        return address(wallet);
    }

}