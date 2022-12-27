// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "../main/DepositConfirmation.sol";

/** 
* @author Formation.Fi.
* @notice Implementation of the contract DepositConfirmationBeta.
*/
 contract DepositConfirmationBeta is DepositConfirmation {
         constructor() DepositConfirmation ("DBETA", "DBETA"){
         }
}