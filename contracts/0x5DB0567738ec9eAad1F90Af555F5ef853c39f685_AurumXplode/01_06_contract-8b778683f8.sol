// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";

contract AurumXplode is ERC20 {
    constructor() ERC20("AurumXplode", "AurumX") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}