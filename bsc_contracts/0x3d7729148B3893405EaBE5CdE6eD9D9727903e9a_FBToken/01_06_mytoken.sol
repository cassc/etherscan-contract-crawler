// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


import "ERC20.sol";
import "Ownable.sol";

contract FBToken is ERC20, Ownable {
    constructor() ERC20("FrenchBrazilianToken", "FBT") {}
}