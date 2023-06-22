// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract God is ERC20 {
    constructor(uint256 supply) ERC20("God", "GOD") {
        _mint(msg.sender, supply);
    }

    receive() external payable {}
}