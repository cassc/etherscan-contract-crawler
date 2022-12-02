// SPDX-FileCopyrightText: 2022 P2P Validator <[email protected]>
// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "../@openzeppelin/contracts/utils/Context.sol";
import "./IOwnable.sol";

/**
* @notice Throws if called by any account other than the owner.
* @param _caller address of the caller
* @param _owner address of the owner
*/
error OwnableBase__CallerNotOwner(address _caller, address _owner);

/**
 * @dev minimalistic version of OpenZeppelin's Ownable.
 * The owner is abstract and is not persisted in storage.
 * Needs to be overridden in a child contract.
 */
abstract contract OwnableBase is Context, IOwnable {

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        address caller = _msgSender();
        address currentOwner = owner();

        if (currentOwner != caller) {
            revert OwnableBase__CallerNotOwner(caller, currentOwner);
        }
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     * Needs to be overridden in a child contract.
     */
    function owner() public view virtual override returns (address);
}