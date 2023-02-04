// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {AccessControl} from "lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
import {Roles} from "./libraries/Roles.sol";

contract AccessController is AccessControl {
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(Roles.MCAG_MINT_ROLE, msg.sender);
        _grantRole(Roles.MCAG_BURN_ROLE, msg.sender);
        _grantRole(Roles.MCAG_BLACKLIST_ROLE, msg.sender);
        _grantRole(Roles.MCAG_PAUSE_ROLE, msg.sender);
        _grantRole(Roles.MCAG_UNPAUSE_ROLE, msg.sender);
        _grantRole(Roles.MCAG_TRANSMITTER_ROLE, msg.sender);
        _grantRole(Roles.MCAG_MANAGER_ROLE, msg.sender);
        _grantRole(Roles.MCAG_SET_URI_ROLE, msg.sender);
    }
}