// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IRoles.sol";
import "./IProxyCall.sol";

interface IExternalRegister {
    function onUnregister(bytes32 hash) external;

    function onRegister(bytes32 hash) external;
}