pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Metagarden is ERC20 {
    constructor(string memory name, string memory symbol, uint256 amount) ERC20(name, symbol) {
        _mint(0xD83C3A324Fad184b2D6beaB1A00165c2F91fCF77, amount);
    }
}