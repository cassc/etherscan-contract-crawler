//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

/**
 * Constant values used elsewhere
 */
library LibConstants {

    
    
    uint16 constant HOUR = 3600;
    uint24 constant DAY = 86400;

    //storage and calldata requirements significantly higher when using more than 
    //6decs for USD price precision
    uint constant USD_PRECISION = 1e6;

    //1_000_000 as a 6-decimal number
    uint constant MM_VOLUME = 1e12;

    //when doing asset-related math, increase precision accordingly.
    uint constant PRICE_PRECISION = 1e30;

    //========================================================================
    // Assignable roles for role-managed contracts
    //========================================================================

    //allowed to add relays and other role managers
    string public constant ROLE_MGR = "ROLE_MANAGER";

    //allowed to submit execution requests
    string public constant RELAY = "RELAY";

    //========================================================================
    // Gas adjustment types
    //========================================================================
    string public constant SWAP_FAILURE = "SWAP_FAILURE";
    string public constant SWAP_SUCCESS = "SWAP_SUCCESS";

}