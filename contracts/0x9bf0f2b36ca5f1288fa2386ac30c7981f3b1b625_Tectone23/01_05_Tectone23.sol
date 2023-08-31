// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Tectone23 is ERC20 {
    constructor() ERC20("Tectone23", "TECHT") {
        _mint(msg.sender, 369_000_000 * 10 ** 18);
    }
}