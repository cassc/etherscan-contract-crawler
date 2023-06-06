// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PiggyCoin is ERC20, Ownable {
    constructor() ERC20("PiggyCoin", "$PIGGY") {
        _mint(msg.sender, 21000000000 * 10 ** decimals());
    }
}