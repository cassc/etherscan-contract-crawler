// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract Arpa is ERC20 {
    constructor() ERC20("Arpa Token", "ARPA") {
        _mint(msg.sender, 1e10 * 1e18);
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}