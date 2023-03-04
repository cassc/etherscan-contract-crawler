// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract YIQToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("YIQI Token", "YIQ") {
        _mint(msg.sender, initialSupply);
    }
}