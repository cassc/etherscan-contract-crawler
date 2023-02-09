// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BscSafetyBoxLayout.sol";
import "../../dependant/ownable/OwnableStorage.sol";
import "../bscSPSNameServiceRef/BscSPSNameServiceRefStorage.sol";

import "./BscSafetyBoxType.sol";

contract BscSafetyBoxStorage is Proxy,
BscSafetyBoxLayout,
OwnableStorage,
BscSPSNameServiceRefStorage
{
    using SafeMath for uint256;

    constructor (
        address accessControl_,
        address owner_
    )
    Proxy(msg.sender)
    OwnableStorage(owner_)
    BscSPSNameServiceRefStorage(accessControl_)
    {

    }
}