// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

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
abstract contract OnlyExpellerUpgradeable is
    ContextUpgradeable,
    OwnableUpgradeable
{
    address private _expellerAddress;

    event ExpellerAddressChanged(
        address indexed previousWallet,
        address indexed newWallet
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __OnlyExpeller_init(address wallet) internal onlyInitializing {
        __OnlyExpeller_init_unchained(wallet);
    }

    function __OnlyExpeller_init_unchained(address wallet)
        internal
        onlyInitializing
    {
        _setExpellerAddress(wallet);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function expellerAddress() public view virtual returns (address) {
        return _expellerAddress;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyExpeller() {
        require(msg.sender == _expellerAddress, "ONLY_EXPELLER");
        _;
    }

    function updateExpellerAddress(address newWallet) public virtual onlyOwner {
        require(
            newWallet != address(0),
            "OnlyExpeller: new wallet is the zero address"
        );
        _setExpellerAddress(newWallet);
    }

    function _setExpellerAddress(address newWallet) private {
        address oldWallet = _expellerAddress;
        _expellerAddress = newWallet;
        emit ExpellerAddressChanged(oldWallet, newWallet);
    }
}