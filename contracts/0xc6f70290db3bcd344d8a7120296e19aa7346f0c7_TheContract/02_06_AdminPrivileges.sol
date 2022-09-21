// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
* @notice THIS PRODUCT IS IN BETA, SIBLING LABS IS NOT RESPONSIBLE FOR ANY LOST FUNDS OR
* UNINTENDED CONSEQUENCES CAUSED BY THE USE OF THIS PRODUCT IN ANY FORM.
*/

/**
 * @dev Contract module that designates an owner and admins
 * for a smart contract.
 *
 * Inheriting from `AdminPrivileges` will make the
 * {onlyAdmins} modifier available, which can be applied to
 * functions to restrict all wallets except for the stored
 * owner and admin addresses.
 *
* See more module contracts from Sibling Labs at
* https://github.com/NFTSiblings/Modules
 */
contract AdminPrivileges {
    address public owner;

    mapping(address => bool) private admins;

    constructor() {
        owner = msg.sender;
    }

    /**
    * @dev Returns true if provided address has admin status
    * or is the contract owner.
    */
    function isAdmin(address _addr) public view returns (bool) {
        return owner == _addr || admins[_addr];
    }

    /**
    * @dev Prevents a function from being called by anyone
    * but the contract owner or approved admins.
    */
    modifier onlyAdmins() {
        require(isAdmin(msg.sender), "AdminPrivileges: caller is not an admin");
        _;
    }

    /**
    * @dev Toggles admin status of provided addresses.
    */
    function toggleAdmins(address[] calldata accounts) external onlyAdmins {
        for (uint i; i < accounts.length; i++) {
            if (admins[accounts[i]]) {
                delete admins[accounts[i]];
            } else {
                admins[accounts[i]] = true;
            }
        }
    }

    /**
    * @dev Transfers ownership role to a different address.
    */
    function transferOwnership(address newOwner) public {
        require(msg.sender == owner, "Only contract owner can transfer ownership");
        owner = newOwner;
    }
}