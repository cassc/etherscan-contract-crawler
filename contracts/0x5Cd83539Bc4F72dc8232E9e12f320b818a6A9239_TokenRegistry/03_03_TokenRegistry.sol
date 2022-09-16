// SPDX-License-Identifier: MIT
/*
_____   ______________________   ____________________________   __
___  | / /__  ____/_  __ \__  | / /__  __ \__    |___  _/__  | / /
__   |/ /__  __/  _  / / /_   |/ /__  /_/ /_  /| |__  / __   |/ / 
_  /|  / _  /___  / /_/ /_  /|  / _  _, _/_  ___ |_/ /  _  /|  /  
/_/ |_/  /_____/  \____/ /_/ |_/  /_/ |_| /_/  |_/___/  /_/ |_/  
 ___________________________________________________________ 
  S Y N C R O N A U T S: The Bravest Souls in the Metaverse

*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenRegistry is Ownable {
    /// @dev Events of the contract
    event TokenAdded(address token);
    event TokenRemoved(address token);

    /// @notice ERC20 Address -> Bool
    mapping(address => bool) public enabled;

    /**
  @notice Method for adding payment token
  @dev Only admin
  @param token ERC20 token address
  */
    function add(address token) external onlyOwner {
        require(!enabled[token], "token already added");
        enabled[token] = true;
        emit TokenAdded(token);
    }

    /**
  @notice Method for removing payment token
  @dev Only admin
  @param token ERC20 token address
  */
    function remove(address token) external onlyOwner {
        require(enabled[token], "token not exist");
        enabled[token] = false;
        emit TokenRemoved(token);
    }
}