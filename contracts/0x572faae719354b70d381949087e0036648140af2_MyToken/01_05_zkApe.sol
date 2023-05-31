// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyToken is ERC20 {
    address public owner;

    constructor() ERC20("zkAPE", "ZKAPE") {
        _mint(msg.sender, 1000000000 * 10 ** 18);
        owner = msg.sender;
    }
}