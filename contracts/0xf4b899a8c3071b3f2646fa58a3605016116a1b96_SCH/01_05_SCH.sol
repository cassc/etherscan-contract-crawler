// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SCH is ERC20 {
    constructor () ERC20("Schwap", "SCH") {
        _mint(msg.sender, 1_000_000 * (10 ** 18));
    }

    receive() external payable {}
}