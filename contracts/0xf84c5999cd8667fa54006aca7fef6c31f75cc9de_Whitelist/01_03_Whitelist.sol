// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.5;

import '@openzeppelin/contracts/access/Ownable.sol';

/// @title Whitelist
/// @notice contains a list of wallets allowed to perform a certain operation
contract Whitelist is Ownable {
    mapping(address => bool) internal wallets;

    /// @notice events of approval and revoking wallets
    event ApproveWallet(address);
    event RevokeWallet(address);

    /// @notice approves wallet
    /// @param _wallet the wallet to approve
    function approveWallet(address _wallet) external onlyOwner {
        if (!wallets[_wallet]) {
            wallets[_wallet] = true;
            emit ApproveWallet(_wallet);
        }
    }

    /// @notice revokes wallet
    /// @param _wallet the wallet to revoke
    function revokeWallet(address _wallet) external onlyOwner {
        if (wallets[_wallet]) {
            wallets[_wallet] = false;
            emit RevokeWallet(_wallet);
        }
    }

    /// @notice checks if _wallet is whitelisted
    /// @param _wallet the wallet to check
    /// @return true if wallet is whitelisted
    function check(address _wallet) external view returns (bool) {
        return wallets[_wallet];
    }
}