// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC20Wrapper.sol";


contract WUSDC is ERC20Wrapper {
    constructor(address usdc) ERC20Wrapper("Wrapped USDC", "wUSDC", usdc) {}
}