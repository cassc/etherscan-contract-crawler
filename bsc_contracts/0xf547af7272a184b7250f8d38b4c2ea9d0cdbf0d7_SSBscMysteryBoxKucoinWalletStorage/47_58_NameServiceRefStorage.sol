// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NameServiceRefLayout.sol";
import "../accessControlRef/AccessControlRefStorage.sol";

//this is an endpoint module, only can be directly inherited all the way to the end
//this module substitutes {AccessControlRef}, must be combined with combining modules using {AccessControlRef}
contract NameServiceRefStorage is NameServiceRefLayout, AccessControlRefStorage {

    constructor (
        address nameService_
    )
    AccessControlRefStorage(nameService_){
    }
}