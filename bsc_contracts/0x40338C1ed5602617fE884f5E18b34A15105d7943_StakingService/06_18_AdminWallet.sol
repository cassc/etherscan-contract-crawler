// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Enjinstarter
pragma solidity ^0.8.0;

import "./interfaces/IAdminWallet.sol";

/**
 * @title AdminWallet
 * @author Tim Loh
 * @notice Provides an implementation of the admin wallet interface that is inherited by other contracts
 */
contract AdminWallet is IAdminWallet {
    address private _adminWallet;

    constructor() {
        _adminWallet = msg.sender;
    }

    /**
     * @inheritdoc IAdminWallet
     */
    function adminWallet() public view virtual override returns (address) {
        return _adminWallet;
    }

    /**
     * @dev Change admin wallet to a new wallet address
     * @param newWallet The new admin wallet address
     */
    function _setAdminWallet(address newWallet) internal virtual {
        require(newWallet != address(0), "AdminWallet: new wallet");

        address oldWallet = _adminWallet;
        _adminWallet = newWallet;

        emit AdminWalletChanged(oldWallet, newWallet, msg.sender);
    }
}