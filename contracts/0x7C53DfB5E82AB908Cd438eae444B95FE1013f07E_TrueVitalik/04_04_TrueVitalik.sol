// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC20.sol";

contract TrueVitalik is ERC20 {
    constructor() ERC20("TrueVitalik", "TrueVitalik") {
        _mint(msg.sender, 420690000 * 10 ** decimals());
    }
}