// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/oft/v2/ProxyOFTV2.sol";

/// @title Gravita Layer Zero Proxy
/// @notice Use this contract only on the BASE CHAIN. It locks tokens on source, on outgoing send(), and unlocks tokens when receiving from other chains.
contract GravitaProxy is ProxyOFTV2 {
    constructor(address _token, address _layerZeroEndpoint) ProxyOFTV2(_token, _layerZeroEndpoint) {}
}