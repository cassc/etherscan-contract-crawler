// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract UnKnownToken is ERC20, Ownable {
    constructor() ERC20("UnKnownToken", "unknown2.0") {
        _mint(msg.sender, 10000000 * 10 ** decimals());
    }
}