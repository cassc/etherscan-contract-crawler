// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MustarToken is ERC20, Ownable{
    constructor() ERC20("MustarToken", "MUSTART"){}


}