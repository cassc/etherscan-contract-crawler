// contracts/OurToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC20.sol";

contract FckBen is ERC20 {
    constructor(uint256 initialSupply) ERC20("FckBenDotETH", "FckBen") {
        _mint(msg.sender, initialSupply);
    }
}