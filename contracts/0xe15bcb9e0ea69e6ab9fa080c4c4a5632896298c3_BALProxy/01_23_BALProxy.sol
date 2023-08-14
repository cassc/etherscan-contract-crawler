// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@layerzerolabs/solidity-examples/contracts/token/oft/v2/fee/ProxyOFTWithFee.sol";

contract BALProxy is ProxyOFTWithFee {
    constructor(address _token, address _layerZeroEndpoint) ProxyOFTWithFee(_token, 6, _layerZeroEndpoint){}
}