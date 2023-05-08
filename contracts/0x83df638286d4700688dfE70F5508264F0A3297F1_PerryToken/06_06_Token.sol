// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PerryToken is Ownable, ERC20 {

    constructor() ERC20("Perry", "PERRY") {
        _mint(msg.sender, 3_647_777_777_777 * 10**uint(decimals()));
    }
}