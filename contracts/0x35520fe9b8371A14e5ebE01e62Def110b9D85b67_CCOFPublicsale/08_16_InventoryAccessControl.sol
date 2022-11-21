// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;
import "./MinterControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

abstract contract InventoryAccessControl is MinterControl, Pausable {

    /**@dev burnPaused returns the boolean value of the burn functionality */
    bool private burnPaused;

    /** @dev whenBurNotPaused is a modifier used with the Burn function.
    *It essentially checks if the burn function has been paused or not.
    *Burn can be paused when the burned function is unpaused by the owner.
     */
    modifier whenBurnNotPaused() {
        require(!burnPaused, "Burning is paused");
        _;
    }

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

     /**
     * @dev pauses the 'Burn' functionality.
     * Only Owner can pause the function.
     */ 

    function pauseBurn() public onlyOwner {
        burnPaused = true;
    }

    
     /**
     * @dev unpauses the 'Burn' functionality.
     * Only Owner can unpause the function.
     */ 

    function unpauseBurn() public onlyOwner {
        burnPaused = false;
    }
}