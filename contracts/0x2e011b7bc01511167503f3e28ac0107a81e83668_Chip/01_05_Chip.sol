// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Chip is ERC20 {
    uint256 private _totalSupply = 88000000 * (10 ** 18);

    constructor() ERC20("Chip", "CHIP") {
        _mint(msg.sender, _totalSupply);
    }

    receive() external payable {}
}