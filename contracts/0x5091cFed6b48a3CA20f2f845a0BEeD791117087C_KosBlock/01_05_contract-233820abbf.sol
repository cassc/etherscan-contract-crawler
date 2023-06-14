// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";

contract KosBlock is ERC20 {
    constructor() ERC20("Kos Block", "KOS") {
        _mint(msg.sender, 777777777 * 10 ** decimals());
    }
}