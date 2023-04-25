// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract GaryClown is ERC20 {
    constructor() ERC20("Gary Clown", "GaryCL") {
        _mint(msg.sender, 1_000_000_000 ether);
    }
}