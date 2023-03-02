// SPDX-License-Identifier: Apache-2.0

/// @title BlockList
/// @author transientlabs.xyz

/**
    ____        _ __    __   ____  _ ________                     __ 
   / __ )__  __(_) /___/ /  / __ \(_) __/ __/__  ________  ____  / /_
  / __  / / / / / / __  /  / / / / / /_/ /_/ _ \/ ___/ _ \/ __ \/ __/
 / /_/ / /_/ / / / /_/ /  / /_/ / / __/ __/  __/ /  /  __/ / / / /_  
/_____/\__,_/_/_/\__,_/  /_____/_/_/ /_/  \___/_/   \___/_/ /_/\__/  
                                                                     
  ______                      _            __     __          __        
 /_  __/________ _____  _____(_)__  ____  / /_   / /   ____ _/ /_  _____
  / / / ___/ __ `/ __ \/ ___/ / _ \/ __ \/ __/  / /   / __ `/ __ \/ ___/
 / / / /  / /_/ / / / (__  ) /  __/ / / / /_   / /___/ /_/ / /_/ (__  ) 
/_/ /_/   \__,_/_/ /_/____/_/\___/_/ /_/\__/  /_____/\__,_/_.___/____/  
                                                                        
*/

pragma solidity 0.8.17;

abstract contract BlockList {

    //================= State Variables =================//
    mapping(address => bool) private _blockList;

    //================= Events =================//
    event BlockListStatusChange(address indexed operator, bool indexed status);

    //================= Modifier =================//
    /// @dev modifier that can be applied to approval functions in order to block listings on marketplaces
    modifier notBlocked(address operator) {
        require(!_blockList[operator], "BlockList: operator is blocked");
        _;
    }

    //================= View Function =================//
    /// @dev function to get blocklist status with True meaning that the operator is blocked
    function getBlockListStatus(address operator) public view returns (bool) {
        return _blockList[operator];
    }

    //================= Setter Function =================//
    /// @notice internal function to set the block list status
    /// @dev inheriting contracts must implement a function that can call this one
    function _setBlockListStatus(address operator, bool status) internal {
        _blockList[operator] = status;
        emit BlockListStatusChange(operator, status);
    }

}