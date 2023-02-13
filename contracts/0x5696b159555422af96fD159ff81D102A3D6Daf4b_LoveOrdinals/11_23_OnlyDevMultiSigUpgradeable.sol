// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OnlyDevMultiSigUpgradeable is ContextUpgradeable {
    address private _devMultiSigWalletAddress;

    event DevMultiSigWalletChanged(
        address indexed previousWallet,
        address indexed newWallet
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __OnlyDevMultiSig_init(address wallet) internal onlyInitializing {
        __OnlyDevMultiSig_init_unchained(wallet);
    }

    function __OnlyDevMultiSig_init_unchained(address wallet)
        internal
        onlyInitializing
    {
        _setDevMultiSigWallet(wallet);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function devMultiSigWallet() public view virtual returns (address) {
        return _devMultiSigWalletAddress;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyDevMultiSig() {
        require(msg.sender == _devMultiSigWalletAddress, "ONLY_DEV_MULTISIG");
        _;
    }

    function updateDevMultiSigWallet(address newWallet)
        public
        virtual
        onlyDevMultiSig
    {
        require(
            newWallet != address(0),
            "OnlyDevMultiSig: new wallet is the zero address"
        );
        _setDevMultiSigWallet(newWallet);
    }

    function _setDevMultiSigWallet(address newWallet) private {
        address oldWallet = _devMultiSigWalletAddress;
        _devMultiSigWalletAddress = newWallet;
        emit DevMultiSigWalletChanged(oldWallet, newWallet);
    }
}