// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../infiniteProxy/proxy.sol";

contract InstaVault is Proxy {
    constructor(address admin_, address dummyImplementation_)
        Proxy(admin_, dummyImplementation_)
    {}
}