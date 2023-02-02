// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import './MinterControl.sol';
import '@openzeppelin/contracts/security/Pausable.sol';

abstract contract InventoryAccessControl is MinterControl, Pausable {
    /**
     * @dev Pauses the erc721a contract.
     * Only Owner can pause the contract.
     * Mint cannot be performed while the contract is paused
     */

    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev unpauses the paused erc721a contract.
     * Only Owner can unpause the contract.
     * unpaused by default.
     */

    function unpause() public onlyOwner {
        _unpause();
    }
}