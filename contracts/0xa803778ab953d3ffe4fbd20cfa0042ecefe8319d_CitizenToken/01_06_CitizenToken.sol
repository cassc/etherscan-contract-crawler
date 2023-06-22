// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract CitizenToken is ERC20Burnable {
    constructor() ERC20("Totem Earth Systems", "CTZN") {
        _mint(msg.sender, 1e9 ether);
    }
}