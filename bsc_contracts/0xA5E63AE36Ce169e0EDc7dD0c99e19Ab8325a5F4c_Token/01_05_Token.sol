pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(0xF5b0ed82a0b3e11567081694cC66c3df133f7C8F, 128000000 ether);
    }
}