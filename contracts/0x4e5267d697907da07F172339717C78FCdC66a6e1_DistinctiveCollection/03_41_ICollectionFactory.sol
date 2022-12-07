// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IRoles.sol";
import "./IProxyCall.sol";

interface ICollectionFactory {
    function rolesContract() external returns (IRoles);
}