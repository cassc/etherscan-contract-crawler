// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "../main/WithdrawalConfirmation.sol";

/** 
* @author Formation.Fi.
* @notice Implementation of the contract WithdrawalConfirmationBeta.
*/
 contract WithdrawalConfirmationBeta is WithdrawalConfirmation {
    constructor() WithdrawalConfirmation("WBETA", "WBETA") {
    }
}