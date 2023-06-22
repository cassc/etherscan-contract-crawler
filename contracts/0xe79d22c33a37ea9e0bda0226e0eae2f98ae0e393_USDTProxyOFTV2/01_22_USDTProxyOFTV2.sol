// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@layerzerolabs/solidity-examples/contracts/token/oft/v2/ProxyOFTV2.sol";

contract USDTProxyOFTV2 is ProxyOFTV2 {
    constructor(address _token, address _layerZeroEndpoint) ProxyOFTV2(_token, 6, _layerZeroEndpoint){}
}