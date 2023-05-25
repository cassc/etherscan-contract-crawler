// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract HIGH is ERC20 {
    constructor(address minter) ERC20("Highstreet token", "HIGH"){
        uint256 amount = 100000000 * 1e18; //decimals 18
        _mint(minter, amount);
    }
}