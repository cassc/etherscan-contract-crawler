// contracts/TestERC20.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestSHF is ERC20 {
    uint8 private _decimals = 9;

    constructor(uint256 initialSupply) ERC20("SHIBAFRIEND_TEST", "SHFT") {
        _mint(msg.sender, initialSupply  * 10**9);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}