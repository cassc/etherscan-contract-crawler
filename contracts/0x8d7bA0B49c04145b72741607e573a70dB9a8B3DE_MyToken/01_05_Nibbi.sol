// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyToken is ERC20 {
    address public owner;

    constructor() ERC20("NibbiCoin", "NIBBI") {
        _mint(msg.sender, 100000000000 * 10 ** 18);
        owner = msg.sender;
    }
}