// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IRecoverable.sol";

interface IRecoveryHub {

    function setRecoverable(bool flag) external;
    
    // deletes claim and transfers collateral back to claimer
    function deleteClaim(address target) external;

    // clears claim and transfers collateral to holder
    function clearClaimFromToken(address holder) external;

    function clearClaimFromUser(IRecoverable token) external;

}