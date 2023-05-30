// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BebePepeToken is ERC20 {
    constructor() ERC20("Bebe Pepe Coin", "BEBEPEPE") {
        _mint(msg.sender, 69420694206942 * 10 ** decimals());
    }
}