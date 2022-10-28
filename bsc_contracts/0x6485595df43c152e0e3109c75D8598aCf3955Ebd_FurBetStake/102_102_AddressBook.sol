// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


import "./abstracts/BaseContract.sol";

/**
 * @title Furio Address Book
 * @author Steve Harmeyer
 * @notice This contract stores important addresses in the Furio ecosystem.
 * @dev Important addresses:    token - Fur token
 *                              payment - USDC token
 *                              vault - Fur vault
 *                              pool - Fur pool
 *                              swap - Fur swap
 *                              router - Pancake swap router V2
 *                              factory - Pancake swap factory V2
 *                              safe - Gnosis safe
 */

/// @custom:security-contact [email protected]
contract AddressBook is BaseContract
{
    /**
     * Contract initializer.
     * @dev This intializes all the parent contracts.
     */
    function initialize() initializer public
    {
        __BaseContract_init();
    }

    /**
     * Address book mapping.
     */
    mapping(string => address) private _addressBook;

    /**
     * Set address.
     * @param name_ Address name.
     * @param address_ Address.
     * @dev Stores an address in the address book.
     */
    function set(string memory name_, address address_) external whenNotPaused onlyOwner
    {
        _addressBook[name_] = address_;
    }

    /**
     * Unset address.
     * @param name_ Address name.
     * @dev Removes an address from the address book.
     */
    function unset(string memory name_) external whenNotPaused onlyOwner
    {
        delete _addressBook[name_];
    }

    /**
     * Get address.
     * @param name_ Address name.
     * @return address Address.
     * @dev Returns an address stored in the address book.
     */
    function get(string memory name_) external view whenNotPaused returns (address)
    {
        return _addressBook[name_];
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}