// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";

contract WaluigiCoin is ERC20 {
    constructor() ERC20("Waluigi Coin", "WALU") {
        _mint(0x4fC39b432D0ef48685291317Aafe91103CAAb418, 777000000000000 * 10 ** decimals());
    }
}