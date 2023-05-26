pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @dev Contract module which creates a Minter role, to which more than one
 * address can be assigned, to grant limited access to minting actions
 *
 * By default, the account that deploys the contract will be assigned the Minter role. 
 * Accounts can be added or removed with the functions defined below.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyMinter`, which can be applied to your functions to restrict their use to
 * minters.
 */
abstract contract MinterRole is AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
 
    /**
     * Modifier to make a function callable only by accounts with the minter role.
     */
    modifier onlyMinter() {
        require(isMinter(_msgSender()), "Not a Minter");
        _;
    }

    /**
     * Constructor.
     */
    constructor() {
        _setupRole(MINTER_ROLE, _msgSender());
    }

    /**
     * Validates whether or not the given account has been granted the minter role.
     * @param account The account to validate.
     * @return True if the account has been granted the minter role, false otherwise.
     */
    function isMinter(address account) public view returns (bool) {
        return hasRole(MINTER_ROLE, account);
    }

    /**
     * Grants the minter role to a non-minter.
     * @param account The account to grant the minter role to.
     */
    function addMinter(address account) public onlyMinter {
        require(!isMinter(account), "Already a Minter");
        grantRole(MINTER_ROLE, account);
    }

    /**
     * Removes the granted minter role.
     */
    function removeMinter() public onlyMinter {
        renounceRole(MINTER_ROLE, _msgSender());
    }
}