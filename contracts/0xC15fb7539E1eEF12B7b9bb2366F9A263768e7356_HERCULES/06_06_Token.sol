// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HERCULES is Ownable, ERC20 {

    constructor() ERC20("Hercules", "HERCULES") {
        _mint(msg.sender, 7_777_777_777_777 * 10**18);
    }
}