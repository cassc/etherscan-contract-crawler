// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
pragma abicoder v2;

import "@layerzerolabs/solidity-examples/contracts/token/onft/extension/ProxyONFT721.sol";

contract LilPudgysProxyONFT is ProxyONFT721 {
    constructor(address _lzEndpoint, address _proxyToken) ProxyONFT721(_lzEndpoint, _proxyToken) {}
}