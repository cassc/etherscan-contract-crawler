// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/* @title Freezable
 * @author minimizer <[email protected]>; https://www.minimizer.art/
 * 
 * Generic interface that provides a modifier allowing "freezing"
 * 
 * Implementors of this contract will need to call _freeze() when appropriate, after which 
 * any methods using the modifier onlyWhenNotFrozen are no longer accessible
 */
contract Freezable {
    
    bool public frozen = false;
    
    modifier onlyWhenNotFrozen() {
        require(frozen == false, "Freezable: Cannot perform operation once contract is frozen.");
        _;
    }
    
    function _freeze() internal {
        frozen = true;
    }
}