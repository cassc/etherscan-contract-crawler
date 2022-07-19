// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";


/**
 * @title OwnablePausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
abstract contract OwnablePausableUpgradeable is OwnableUpgradeable {
    event Pause();
    event Unpause();

    bool public paused;

    /**
      * @dev Initializes the contract in unpaused state.
    */
    function __OwnablePausable_init() internal onlyInitializing {
        __Ownable_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
   */
    modifier whenNotPaused() {
        require(!paused, "OwnablePausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
   */
    modifier whenPaused() {
        require(paused, "OwnablePausable: not paused");
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
   */
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
   */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }

    /**
    * @dev This empty reserved space is put in place to allow future versions to add new
  * variables without shifting down storage in the inheritance chain.
  * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
  */
    uint256[49] private __gap;
}