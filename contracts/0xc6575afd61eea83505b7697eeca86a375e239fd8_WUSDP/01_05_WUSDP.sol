// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC20Wrapper.sol";


contract WUSDP is ERC20Wrapper {
    constructor(address usdp) ERC20Wrapper("Wrapped USDP", "wUSDP", usdp) {}
}