// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "ERC20.sol";

contract Connex is ERC20 {
    constructor() ERC20("Connex", "CONX") {
        _mint(msg.sender, 100_000_000 * (10**uint256(decimals())));
    }
}