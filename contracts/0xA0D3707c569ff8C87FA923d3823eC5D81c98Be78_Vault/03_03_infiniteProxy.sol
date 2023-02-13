// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../../infiniteProxy/proxy.sol";

contract Vault is Proxy {
    constructor(address admin_, address dummyImplementation_)
        Proxy(admin_, dummyImplementation_)
    {}
}