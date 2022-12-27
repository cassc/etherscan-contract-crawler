// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "../main/Management.sol";

/** 
* @author Formation.Fi.
* @notice Implementation of the contract ManagementGamma.
*/

contract ManagementGamma is Management {
    constructor(address _manager, address _treasury, address _stableToken,
     address _token) Management( _manager,  _treasury,  _stableToken,
     _token){
   }
}