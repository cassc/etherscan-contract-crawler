// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC20Wrapper.sol";


contract WTUSD is ERC20Wrapper {
    constructor(address tusd) ERC20Wrapper("Wrapped TUSD", "wTUSD", tusd) {}
}