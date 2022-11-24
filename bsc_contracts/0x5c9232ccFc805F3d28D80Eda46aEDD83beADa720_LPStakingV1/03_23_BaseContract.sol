// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/IAddressBook.sol";
import "../interfaces/IAutoCompound.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title BaseContract
 * @author Steve Harmeyer
 * @notice This is an abstract base contract to handle UUPS upgrades and pausing.
 */

/// @custom:security-contact [email protected]
abstract contract BaseContract is Initializable, PausableUpgradeable, OwnableUpgradeable, UUPSUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { _disableInitializers(); }

    /**
     * Contract initializer.
     * @dev This intializes all the parent contracts.
     */
    function __BaseContract_init() internal onlyInitializing {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    /**
     * Address book.
     */
    IAddressBook public addressBook;

    /**
     * -------------------------------------------------------------------------
     * ADMIN FUNCTIONS.
     * -------------------------------------------------------------------------
     */

    /**
     * Pause contract.
     * @dev This stops all operations with the contract.
     */
    function pause() external onlyOwner
    {
        _pause();
    }

    /**
     * Unpause contract.
     * @dev This resumes all operations with the contract.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * Set address book.
     * @param address_ Address book address.
     * @dev Sets the address book address.
     */
    function setAddressBook(address address_) public onlyOwner
    {
        addressBook = IAddressBook(address_);
    }

    /**
     * -------------------------------------------------------------------------
     * HOOKS.
     * -------------------------------------------------------------------------
     */

    /**
     * @dev This prevents upgrades from anyone but owner.
     */
    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}