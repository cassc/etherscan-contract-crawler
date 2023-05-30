// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";

contract Iska is ERC20 {
    constructor() ERC20("ISEKAI", "ISKA") {
        _mint(0x5093965B66cEB4e540fC7d066C5Ee377Bd43f0CB, 10000000000 * 10 ** decimals());
    }
}