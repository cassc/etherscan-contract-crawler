// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BscSPSNameServiceRefLayout.sol";
import "../../dependant/nameServiceRef/NameServiceRefStorage.sol";

contract BscSPSNameServiceRefStorage is BscSPSNameServiceRefLayout, NameServiceRefStorage {

    constructor (
        address nameService_
    )
    NameServiceRefStorage(nameService_){

    }
}