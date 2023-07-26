// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC20Wrapper.sol";


contract WUSDT is ERC20Wrapper {
    constructor(address usdt) ERC20Wrapper("Wrapped USDT", "wUSDT", usdt) {}
}