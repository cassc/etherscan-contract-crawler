// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract Zoomer is ERC20, ERC20Burnable {
    constructor() ERC20("Zoomer Coin", "ZOOMER") {
        _mint(msg.sender, 69000000000 * 10 ** decimals());
    }
}