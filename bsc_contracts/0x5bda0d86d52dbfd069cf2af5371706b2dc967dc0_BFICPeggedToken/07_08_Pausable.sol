// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Context.sol";
import "./Ownable.sol";

abstract contract Pausable is Context,Ownable {
  event Pause();
  event Unpause();
  event NotPausable();
  
  bool public paused = false;
  bool public canPause = true;

  /**
  * @dev Modifier to make a function callable only when the contract is not paused.
  */
  modifier whenNotPaused() {      
      require(!paused || _owner == _msgSender());
      _;
  }

  /**
  * @dev Modifier to make a function callable only when the contract is paused.
  */
  modifier whenPaused() {
      require(paused);
      _;
  }

  /**
    * @dev called by the owner to pause, triggers stopped state
    **/
  function pause() onlyOwner whenNotPaused public {
      require(canPause == true);
      paused = true;
      emit Pause();
  }

  /**
  * @dev called by the owner to unpause, returns to normal state
  */
  function unpause() onlyOwner whenPaused public {
      require(paused == true);
      paused = false;
      emit Unpause();
  }

  /**
  * @dev Prevent the token from ever being paused again
  **/
  function notPausable() onlyOwner public{
      paused = false;
      canPause = false;
      emit NotPausable();
  }
}