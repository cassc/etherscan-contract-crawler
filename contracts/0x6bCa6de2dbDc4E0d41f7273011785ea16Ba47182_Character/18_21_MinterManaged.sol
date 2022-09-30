// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IMinterManaged.sol";
import "./Permissions.sol";
import "./Errors.sol";

/**
 * @dev Minter Manager
 * @notice Manage minter access controls
 */
contract MinterManaged is IMinterManaged, AccessControl, Ownable, Errors {
    address private _manager;

    constructor(address manager, address asm) {
        if (manager == address(0)) revert InvalidInput(INVALID_MANAGER);
        _grantRole(MANAGER_ROLE, manager);
        transferOwnership(asm); // OpenSea checks the ownership of the contract
        _manager = manager;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IMinterManaged, AccessControl)
        returns (bool)
    {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IMinterManaged).interfaceId ||
            interfaceId == type(AccessControl).interfaceId;
    }

    /** ----------------------------------
     * ! Manager's functions
     * ----------------------------------- */

    /**
     * @notice Set manager address (contract or wallet) to manage this contract
     * @dev This function can only to called from contracts or wallets with MANAGER_ROLE
     * @dev The old manager will be removed
     * @param newManager The new manager address to be granted
     */
    function setManager(address newManager) external onlyRole(MANAGER_ROLE) {
        if (newManager == address(0)) revert InvalidInput(INVALID_ADDRESS);
        _grantRole(MANAGER_ROLE, newManager);
        _revokeRole(MANAGER_ROLE, _manager);
        _manager = newManager;
    }

    /**
     * @notice Add minter address (contract or wallet) to manage this contract
     * @dev This function can only to called from contracts or wallets with MANAGER_ROLE
     * @dev The old manager will be retained
     * @param newMinter The new minter address to be granted
     */
    function addMinter(address newMinter) external onlyRole(MANAGER_ROLE) {
        _grantRole(MINTER_ROLE, newMinter);
    }

    /**
     * @notice Revoke minter address (contract or wallet) to manage this contract
     * @dev This function can only to called from contracts or wallets with MANAGER_ROLE
     * @param oldMinter The old minter address to be revoked
     */
    function revokeMinter(address oldMinter) external onlyRole(MANAGER_ROLE) {
        _revokeRole(MINTER_ROLE, oldMinter);
    }
}