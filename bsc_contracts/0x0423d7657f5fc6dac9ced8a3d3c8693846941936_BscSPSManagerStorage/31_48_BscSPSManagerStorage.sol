// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BscSPSManagerLayout.sol";
import "../../dependant/ownable/OwnableStorage.sol";
import "../bscSPSNameServiceRef/BscSPSNameServiceRefStorage.sol";

contract BscSPSManagerStorage is Proxy, BscSPSManagerLayout, OwnableStorage,
BscSPSNameServiceRefStorage {

    using SafeMath for uint256;

    constructor (
        address nameService_,
        address owner_
    )
    Proxy(msg.sender)
    OwnableStorage(owner_)
    BscSPSNameServiceRefStorage(nameService_){

    }
}