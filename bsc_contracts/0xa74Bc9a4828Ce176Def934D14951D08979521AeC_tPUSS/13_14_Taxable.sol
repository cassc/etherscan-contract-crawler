// SPDX-License-Identifier: MIT
// Modified from OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0; // Must use solidity 0.8.0 or higher. Math isn't so safe otherwise...

import "@openzeppelin/contracts/utils/Context.sol"; // Context is imported to use _msgSender()

abstract contract Taxable is Context {

/// @dev Events defined for any contract changes.

	event TaxOn(address account); // Emits event "Tax On" when tax is enabled, returning the address of the Governor.
	event TaxOff(address account); // Emits event "Tax Off" when tax is disabled, returning the address of the Governor.
    event TaxChanged(address account); // Emits event "Tax Changed" when tax amount is updated, returning the address of the Governor.
	event TaxDestinationChanged(address account); // Emits event "Tax Destination Changed" when tax destination is changed, returning the address of the President.

/// @dev Name and type of constants defined.

	bool private _taxed; // Stores whether tax is enabled/disabled in a boolean.
	uint private _thetax; // Stores tax amount as a uint256 integer.
    uint private _maxtax; // Stores maximum tax amount as a uint256 integer.
    uint private _mintax; // Stores minimum tax amount as a uint256 integer.
    address private _taxdestination; // Stores tax destination as a blockchain address type.

/// @dev Constructor adds values to constants.

// Note that min/max tax are hardcoded.

	constructor() {
        _taxed = true; 
        _thetax = 1; 
        _maxtax = 100; // Maximum tax hardcoded to 15.00% = 1500 points.
        _mintax = 1; // Minimum tax hardcoded to 0.25% = 25 points.
        _taxdestination = _msgSender(); // Tax destination defaults to deployer.
    }

/// @dev Modifiers throw errors if conditions are not met.

	modifier whenNotTaxed() { // Modifier for requiring the tax be off in order for the caller function to work.
        _requireNotTaxed(); // Function requires tax be off.
        _;
    }

	modifier whenTaxed() { // Modifier for requiring the tax be on in order for the caller function to work.
        _requireTaxed(); // Function requires tax be on.
        _;
    }

/// @dev Public view functions allow privately stored constants to be interfaced.

	function taxed() public view virtual returns (bool) { // Function enables public interface for tax enabled/disabled boolean.
        return _taxed; // Returns true if tax is enabled, false if it is disabled.
    }

    function thetax() public view virtual returns (uint) { // Function enables public interface for tax amount in points.
        return _thetax; // Returns the current tax amount in points.
    }

    function taxdestination() public view virtual returns (address) { // Function enables public interface for tax destination address.
        return _taxdestination; // Returns the destination address for the tax.
    }

/// @dev Internal view functions contain the require() statements for the modifiers to use.

	function _requireNotTaxed() internal view virtual { // Function is used in the whenNotTaxed() modifier.
        require(!taxed(), "Taxable: taxed"); // Throws the call if the tax is disabled.
    }

	function _requireTaxed() internal view virtual { // Function is used in the whenTaxed() modifier.
        require(taxed(), "Taxable: not taxed"); // Throws the call if the tax is enabled.
    }

/// @dev Internal virtual functions perform the requested contract updates and emit the events to the blockchain.

	function _taxon() internal virtual whenNotTaxed { // Function turns on the tax if it was disabled and emits "Tax On" event.
        _taxed = true; // Sets the tax enabled boolean to true, enabling the tax.
        emit TaxOn(_msgSender()); // Emits the "Tax On" event to the blockchain.
    }

	function _taxoff() internal virtual whenTaxed { // Function turns off the tax if it was enabled and emits "Tax Off" event.
        _taxed = false; // Sets the tax enabled boolean to false, disabling the tax.
        emit TaxOff(_msgSender()); // Emits the "Tax Off" event to the blockchain.
    }

    function _updatetax(uint newtax) internal virtual { // Function updates the tax amount if in allowable range and emits "Tax Changed" event.
        require(newtax <= _maxtax, "Taxable: tax is too high"); // Throws the call if the new tax is above the maximum tax.
        require(newtax >= _mintax, "Taxable: tax is too low"); // Throws the call if the new tax is below the minimum tax.
        _thetax = newtax; // Sets the tax amount integer to the new value, updating the tax amount.
        emit TaxChanged(_msgSender());  // Emits the "Tax Changed" event to the blockchain.
    }

	function _updatetaxdestination(address newdestination) internal virtual { // Function updates the tax destination address and emits "Tax Destination Changed" event.
        _taxdestination = newdestination; // Sets the tax destination address to the new value, updating the tax destination address.
        emit TaxDestinationChanged(_msgSender());  // Emits the "Tax Destination Changed" event to the blockchain.
    }
}