// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "../main/DepositConfirmation.sol";

/** 
* @author Formation.Fi.
* @notice Implementation of the contract DepositConfirmationGamma.
*/
 contract DepositConfirmationGamma is DepositConfirmation {
         constructor() DepositConfirmation ("DGAMMA", "DGAMMA"){
         }
}