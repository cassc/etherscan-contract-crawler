// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract GooseCoin is ERC20 {
    constructor(uint256 initialSupply) ERC20("Goose Coin", "GOOSE") {
        _mint(msg.sender, initialSupply);
    }
    
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
}