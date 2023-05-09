/**
 *Submitted for verification on 2023-05-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Importing the Ownable contract from another file
import "./Ownable.sol";

// Defining a Pausable abstract contract, which is derived from the Ownable contract
abstract contract Pausable is Ownable {

    // Private boolean variable to keep track of whether the contract is paused or not
    bool private _paused;

    // Events that are emitted when the contract is paused or unpaused
    event Paused(address account);
    event Unpaused(address account);

    // Constructor function that sets the initial value of _paused to false
    constructor() {
        _paused = false;
    }

    // Function to check whether the contract is paused or not
    function paused() public view returns (bool) {
        return _paused;
    }

    // Modifier that can be used to only allow function calls when the contract is not paused
    modifier whenNotPaused() {
        require(!_paused, "Paused");
        _;
    }

    // Modifier that can be used to only allow function calls when the contract is paused
    modifier whenPaused() {
        require(_paused, "Not paused");
        _;
    }

    // Function to pause the contract, which can only be called by the contract owner and only when the contract is not already paused
    function pause() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    // Function to unpause the contract, which can only be called by the contract owner and only when the contract is already paused
    function unpause() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}