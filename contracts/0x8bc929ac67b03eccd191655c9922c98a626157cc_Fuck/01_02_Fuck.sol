// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "solmate/tokens/ERC20.sol";

/*
  A project by https://twitter.com/sibeleth

  Like, RT for support! https://twitter.com/sibeleth/status/1652372258248163331
*/

contract Fuck is ERC20 {
    constructor() ERC20("Fuck It", "FUCK", 18) {
        _mint(msg.sender, 69_420_000_000 ether);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}