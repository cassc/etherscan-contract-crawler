// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract GFTOKEN is ERC20 {
    constructor() ERC20("GongFu TOKEN", "GF") {
        _mint(msg.sender, 2666 * (10 ** 18));
    }
}