// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Fair is ERC20 {
    constructor(uint256 _supply) ERC20("fair", "Fair") {
        _mint(msg.sender, _supply);
    }

    receive() external payable {}

}