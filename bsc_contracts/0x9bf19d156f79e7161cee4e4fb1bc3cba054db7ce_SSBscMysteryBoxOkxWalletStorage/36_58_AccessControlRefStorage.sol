// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AccessControlRefLayout.sol";

//this is a leaf module
contract AccessControlRefStorage is AccessControlRefLayout {

    constructor (address accessControl_){
        _accessControl = accessControl_;
    }
}