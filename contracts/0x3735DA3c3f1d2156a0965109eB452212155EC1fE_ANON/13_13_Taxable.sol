/*
╔════╗╔═══╗╔═╗╔═╗╔═══╗╔══╗ ╔╗   ╔═══╗
║╔╗╔╗║║╔═╗║╚╗╚╝╔╝║╔═╗║║╔╗║ ║║   ║╔══╝
╚╝║║╚╝║║ ║║ ╚╗╔╝ ║║ ║║║╚╝╚╗║║   ║╚══╗
  ║║  ║╚═╝║ ╔╝╚╗ ║╚═╝║║╔═╗║║║ ╔╗║╔══╝
 ╔╝╚╗ ║╔═╗║╔╝╔╗╚╗║╔═╗║║╚═╝║║╚═╝║║╚══╗
 ╚══╝ ╚╝ ╚╝╚═╝╚═╝╚╝ ╚╝╚═══╝╚═══╝╚═══╝
A People's Treasury(TM) contract.
https://peoplestreasury.com/
*/

/// @title The Taxable Contract
/// @author People's Treasury
/// @notice Creates an optional tax, flexible within a hardcoded range of 0.25% to 15%. Defaults to 10%.
/// @dev This contract emits events, stores tax vars, and performs checks. 

/*
NOTES:
 • Taxes stored as uint256 in points, which are 2 decimals of percentages and 4 decimals of a factor. (10000 points = 100.00% = 1.0000x)
 • To use this contract for your own ERC20 token, perform the following tasks:
   - In addition to this and the ERC20 contract, import ReentrancyGuard.sol and AccessControl for security reasons:
        import "./Taxable.sol"
        import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
        import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
        import "@openzeppelin/contracts/access/AccessControl.sol";
   - Call the contracts. Example:
        contract __YOURTOKEN__ is ReentrancyGuard, ERC20, AccessControl, Taxable {}
   - Add the PRESIDENT_ROLE, GOVERNOR_ROLE, and EXCLUDED_ROLE vars inside the contract as public constants:
        bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
        bytes32 public constant PRESIDENT_ROLE = keccak256("PRESIDENT_ROLE");
        bytes32 public constant EXCLUDED_ROLE = keccak256("EXCLUDED_ROLE"); 
   - In addition to the standard admin role, add the PRESIDENT_ROLE, GOVERNOR_ROLE, and EXCLUDED_ROLE roles to the standard ERC20 constructor:
        constructor() ERC20("__YOURTOKEN__", "__YOURTOKENSYMBOL__") {
            _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
            _grantRole(GOVERNOR_ROLE, msg.sender);
            _grantRole(PRESIDENT_ROLE, msg.sender);
            _grantRole(EXCLUDED_ROLE, msg.sender);
            _mint(msg.sender, __INITIALMINT__ * 10 ** decimals());
        }
   - Add the public functions for the GOVERNOR_ROLE to enable, disable, an update the tax:
        function enableTax() public onlyRole(GOVERNOR_ROLE) { _taxon(); }
        function disableTax() public onlyRole(GOVERNOR_ROLE) { _taxoff(); }
        function updateTax(uint newtax) public onlyRole(GOVERNOR_ROLE) { _updatetax(newtax); }
   - Add the public function for the PRESIDENT_ROLE to update the tax destination address:
        function updateTaxDestination(address newdestination) public onlyRole(PRESIDENT_ROLE) { _updatetaxdestination(newdestination); }
   - Override the _transfer() function to perform the necessary tax functions:
        function _transfer(address from, address to, uint256 amount) // Overrides the _transfer() function to use an optional transfer tax.
            internal
            virtual
            override(ERC20) // Specifies only the ERC20 contract for the override.
            nonReentrant // Prevents re-entrancy attacks.
            {
                if(hasRole(EXCLUDED_ROLE, from) || hasRole(EXCLUDED_ROLE, to) || !taxed()) { // If to/from a tax excluded address or if tax is off...
                    super._transfer(from, to, amount); // Transfers 100% of amount to recipient.
                } else { // If not to/from a tax excluded address & tax is on...
                    require(balanceOf(from) >= amount, "ERC20: transfer amount exceeds balance"); // Makes sure sender has the required token amount for the total.
                    // If the above requirement is not met, then it is possible that the sender could pay the tax but not the recipient, which is bad...
                    super._transfer(from, taxdestination(), amount*thetax()/10000); // Transfers tax to the tax destination address.
                    super._transfer(from, to, amount*(10000-thetax())/10000); // Transfers the remainder to the recipient.
                }
            }
 • The EXCLUDED_ROLE is for any wallet or contract that would be contradicted to tax to/from such as the deployer, the treasury, or a vesting contract.
 • The GOVERNOR_ROLE can be a governance controlled contract to enable/disable and change the tax amount based on proposal results.
 • The PRESIDENT_ROLE is not the GOVERNOR_ROLE because the address to change the destination address and tax amount is a target for an exploit.
 • It is recommended that the DEFAULT_ADMIN_ROLE renounce either/both the PRESIDENT_ROLE and/or the GOVERNOR_ROLE and assign these to unconnected accounts.
 • Once all roles are set up, it is recommended that the DEFAULT_ADMIN_ROLE add a Multisig admin and renounce the admin role as well as any unnecessary roles.
 • To send the tax to multiple end recipients, consider setting the tax destination address to a splitter contract like PaymentSplitter.sol or 0xSplits.
*/

// SPDX-License-Identifier: MIT
// Modified from OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0; // Must use solidity 0.8.0 or higher. Math isn't so safe otherwise...

import "./Context.sol"; // Context is imported to use _msgSender()

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
        _taxed = false; // Tax is off by default.
        _thetax = 500; // Default tax set to 5.00% = 500 points.
        _maxtax = 500; // Maximum tax hardcoded to 5.00% = 500 points.
        _mintax = 25; // Minimum tax hardcoded to 0.25% = 25 points.
        _taxdestination = 0xbe547E65D0944c3a0ea99E7Bf2d79c6D23566760; // Tax destination defaults to deployer.
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