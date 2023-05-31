// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ProxyOFT} from "../lib/solidity-examples/contracts/token/oft/extension/ProxyOFT.sol";

/**
 * @title ProxyOFT for Open Exchange Token (OX)
 * @notice Proxy contract for OX that enables seamless cross-chain transfers and
 *         custody between Ethereum and other chains.
 * @author opnxj
 */
contract OpenExchangeProxyOFT is ProxyOFT {
    constructor(
        address _lzEndpoint,
        address _token
    ) ProxyOFT(_lzEndpoint, _token) {}
}