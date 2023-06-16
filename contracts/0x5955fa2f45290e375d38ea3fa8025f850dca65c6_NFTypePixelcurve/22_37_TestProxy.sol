// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./NFTProxy.sol";

// TEST CH //
contract ABCD is NFTProxy {
    constructor() NFTProxy("TestName", "SYMB") {}
}