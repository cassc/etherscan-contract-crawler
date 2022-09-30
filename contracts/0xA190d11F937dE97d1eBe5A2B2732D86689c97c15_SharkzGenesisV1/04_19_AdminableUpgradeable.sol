// SPDX-License-Identifier: MIT

/**
 *******************************************************************************
 * Adminable access control
 *******************************************************************************
 * Author: Jason Hoi
 *
 */
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides basic multi-admin access control mechanism,
 * admins are granted exclusive access to specific functions with the provided 
 * modifier.
 *
 * By default, the contract owner is the first admin.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyAdmin`, which can be applied to your functions to restrict access.
 * 
 */
contract AdminableUpgradeable is Initializable {
    event AdminCreated(address indexed addr);
    event AdminRemoved(address indexed addr);

    // mapping for admin address
    mapping(address => uint256) _admins;

    // Initializes the contract setting the deployer as the initial admin.
    function __Adminable_init() internal onlyInitializing {
        __Adminable_init_unchained();
    }

    function __Adminable_init_unchained() internal onlyInitializing {
        _admins[_msgSenderAdminable()] = 1;
    }

    modifier onlyAdmin() {
        require(isAdmin(_msgSenderAdminable()), "Adminable: caller is not admin");
        _;
    }

    function isAdmin(address addr) public view virtual returns (bool) {
        return _admins[addr] == 1;
    }

    function setAdmin(address to, bool approved) public virtual onlyAdmin {
        require(to != address(0), "Adminable: cannot set admin for the zero address");

        if (approved) {
            require(!isAdmin(to), "Adminable: add existing admin");
            _admins[to] = 1;
            emit AdminCreated(to);
        } else {
            require(isAdmin(to), "Adminable: remove non-existent admin");
            delete _admins[to];
            emit AdminRemoved(to);
        }
    }

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * For GSN compatible contracts, you need to override this function.
     */
    function _msgSenderAdminable() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}