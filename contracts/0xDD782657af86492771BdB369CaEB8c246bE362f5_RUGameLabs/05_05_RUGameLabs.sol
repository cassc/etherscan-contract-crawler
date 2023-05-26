// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC20} from "@openzeppelin/token/ERC20/ERC20.sol";

contract RUGameLabs is ERC20 {
    constructor() ERC20("RUGame Labs", "RUG") {
        _mint(msg.sender, 100000000000e12);
    }

    function decimals() public view virtual override returns (uint8) {
        return 12;
    }
}