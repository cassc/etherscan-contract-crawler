//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0 .0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract GTAVI is ERC20 {
    constructor(
    ) ERC20("GTAgang", "GTA") {
        _mint(msg.sender, 10000000000 * 10**18);
    }
}