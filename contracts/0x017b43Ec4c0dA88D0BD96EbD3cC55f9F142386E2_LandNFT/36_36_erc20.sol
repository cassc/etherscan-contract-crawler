// contracts/TestERC20.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract usdtTest is ERC20 {
    uint8 private _decimals = 6;    // Tether USD decimals

    constructor(uint256 initialSupply) ERC20("usdtTest", "USDT") {
        _mint(msg.sender, initialSupply  * 10**_decimals);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}