// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Adminable
/// @notice Mimics Open Zeppelin Ownable so that a contract can be BOTH Ownable
/// AND Adminable. Centralised offchain marketplaces often expect an owner to
/// be present to manage NFT content on the platform. However it is not clear
/// what criteria the marketplace uses to determine whether a contract
/// implements Ownable, and the criteria may change over time even if we did
/// know it. It's also not necessarily easy or possible to interface with
/// centralised marketplaces using multisig wallets such as gnosis. For that
/// reason we want an onchain admin with a relatively cold multisig separate
/// from the hot wallet doing offchain signing, etc.
/// If there is ever an issue with the owner (e.g. it is hacked/stolen/lost)
/// then the admin MUST be able to recover the owner by setting it directly to
/// a known good uncompromised wallet.
abstract contract Adminable {
    address public admin;

    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);

    /// Throws if called by any account other than the admin.
    modifier onlyAdmin() {
        require(admin == msg.sender, "Adminable: caller is not the admin");
        _;
    }

    /// Transfers admin of the contract to a new account (`newAdmin`).
    /// Can only be called by the current admin.
    function transferAdmin(address newAdmin_) external onlyAdmin {
        require(newAdmin_ != address(0), "Adminable: new admin is the zero address");
        _transferAdmin(newAdmin_);
    }

    /// Transfers admin of the contract to a new account (`newAdmin`).
    /// Internal function without access restriction.
    function _transferAdmin(address newAdmin_) internal {
        address oldAdmin_ = admin;
        admin = newAdmin_;
        emit AdminTransferred(oldAdmin_, newAdmin_);
    }
}