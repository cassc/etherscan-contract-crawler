// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MintableToken is ERC20 {
    address admin;

    constructor() ERC20('TEST', 'TTT') public {
        _mint(msg.sender, 1000000000 * 10**18);
        admin = msg.sender;
    }

    function mint(uint amount) public {
        _mint(msg.sender, amount * 10**18);
    }

}