// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
// author [email protected]
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CannalandToken is ERC20 {
    constructor() ERC20("Cannaland Token", "CNLT") {
        _mint(msg.sender, 600000000 * 10 ** decimals());
    }
}