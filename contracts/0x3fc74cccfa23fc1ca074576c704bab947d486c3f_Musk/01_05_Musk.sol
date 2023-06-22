// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Musk is ERC20 {
    constructor(uint256 _totalSupply) ERC20("musk", "Musk") {
        _mint(msg.sender, _totalSupply);
    }

    receive() external payable {}
}