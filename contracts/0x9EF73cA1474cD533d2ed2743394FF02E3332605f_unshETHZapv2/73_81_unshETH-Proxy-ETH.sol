// SPDX-License-Identifier: No License
pragma solidity ^0.8.0;

import "layerzerolabs/contracts/token/oft/extension/ProxyOFT.sol";

contract unshETHProxyOft is ProxyOFT {
    constructor(
        address _lzEndpoint, //0x66A71Dcef29A0fFBDBE3c6a460a3B5BC225Cd675 as per https://layerzero.gitbook.io/docs/technical-reference/mainnet/supported-chain-ids
        address _token // address of the unshETH token
    ) ProxyOFT(_lzEndpoint, _token) {
    }
}