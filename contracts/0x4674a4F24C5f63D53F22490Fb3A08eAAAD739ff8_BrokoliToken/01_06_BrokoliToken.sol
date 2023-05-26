// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract BrokoliToken is ERC20Burnable {

    constructor(
        address owner,
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) {
        _mint(owner, 125e6 ether);
    }
}