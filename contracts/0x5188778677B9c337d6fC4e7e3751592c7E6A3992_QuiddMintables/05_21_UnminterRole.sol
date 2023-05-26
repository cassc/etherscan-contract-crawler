pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @dev Contract module which creates an Unminter role, to which more than one
 * address can be assigned, to grant limited access to the unmint function
 * (and any related activities)
 *
 * By default, the account that deploys the contract will be assigned the Unminter role. 
 * Accounts can be added or removed with the functions defined below.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyMinter`, which can be applied to your functions to restrict their use to
 * minters.
 */
abstract contract UnminterRole is AccessControl {
    bytes32 public constant UNMINTER_ROLE = keccak256("UNMINTER_ROLE");
 
    /**
     * Modifier to make a function callable only by accounts with the minter role.
     */
    modifier onlyUnminter() {
        require(isUnminter(_msgSender()), "Not an Unminter");
        _;
    }

    /**
     * Constructor.
     */
    constructor() {
        _setupRole(UNMINTER_ROLE, _msgSender());
    }

    /**
     * Validates whether or not the given account has been granted the unminter role.
     * @param account The account to validate.
     * @return True if the account has been granted the minter role, false otherwise.
     */
    function isUnminter(address account) public view returns (bool) {
        return hasRole(UNMINTER_ROLE, account);
    }

    /**
     * Grants the unminter role to a non-unminter.
     * @param account The account to grant the unminter role to.
     */
    function addUnminter(address account) public onlyUnminter {
        require(!isUnminter(account), "Already an Unminter");
        grantRole(UNMINTER_ROLE, account);
    }

    /**
     * Removes the granted unminter role.
     */
    function removeUnminter() public onlyUnminter {
        renounceRole(UNMINTER_ROLE, _msgSender());
    }
}