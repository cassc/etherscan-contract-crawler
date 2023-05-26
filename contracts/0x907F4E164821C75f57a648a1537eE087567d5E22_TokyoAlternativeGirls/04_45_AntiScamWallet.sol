// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./RestrictApprove/RestrictApprove.sol";
import "./Lockable/WalletLockable.sol";

abstract contract AntiScamWallet is RestrictApprove, WalletLockable {

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================
    /*
    function _initializeAntiScam() internal virtual override(RestrictApprove, WalletLockable) {
        RestrictApprove._initializeAntiScam();
        WalletLockable._initializeAntiScam();
    }
    */
    function __AntiScamWallet_init() internal onlyInitializingAntiScam {
        __AntiScamWallet_init_unchained();
    }

    function __AntiScamWallet_init_unchained() internal onlyInitializingAntiScam {
        __RestrictApprove_init_unchained();
        __WalletLockable_init_unchained();
        
    }

    function _isTokenApprovable (address transferer, uint256 tokenId) 
        internal
        view
        virtual
        override(RestrictApprove, WalletLockable)
        returns (bool)
    {
        return RestrictApprove._isTokenApprovable(transferer, tokenId) &&
            WalletLockable._isTokenApprovable(transferer, tokenId);
    }

    function _isWalletApprovable(address transferer, address holder)
        internal
        view
        virtual
        override(RestrictApprove, WalletLockable) 
        returns (bool)
    {
        return RestrictApprove._isWalletApprovable(transferer, holder) &&
            WalletLockable._isWalletApprovable(transferer, holder);
    }

    function _isTransferable (
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal view virtual override(AntiScamAbstract, WalletLockable)  returns (bool) {
        return WalletLockable._isTransferable(from, to, startTokenId, quantity);
    }
}