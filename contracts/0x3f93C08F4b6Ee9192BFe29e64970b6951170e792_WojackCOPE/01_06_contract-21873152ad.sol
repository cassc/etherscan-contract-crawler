// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.8.3/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.8.3/contracts/access/Ownable.sol";

contract WojackCOPE is ERC20, Ownable {
    constructor() ERC20("WojackCOPE", "WCOPE") {
        _mint(msg.sender, 420000000000 * 10 ** decimals());
    }
}