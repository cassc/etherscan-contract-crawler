// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@layerzerolabs/solidity-examples/contracts/token/oft/extension/ProxyOFT.sol";

contract DAIProxyOFT is ProxyOFT {
    constructor(address _layerZeroEndpoint, address _token) ProxyOFT(_layerZeroEndpoint, _token){}
}