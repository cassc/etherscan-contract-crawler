// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "../main/WithdrawalConfirmation.sol";

/** 
* @author Formation.Fi.
* @notice Implementation of the contract WithdrawalConfirmationGamma.
*/
 contract WithdrawalConfirmationGamma is WithdrawalConfirmation {
    constructor() WithdrawalConfirmation("WGAMMA", "WGAMMA") {
    }
}