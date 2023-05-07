// Twitter: https://twitter.com/wagdie_eth

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "solmate/tokens/ERC20.sol";

contract Danny is ERC20 {
    uint private constant _numTokens = 6969696969696969;

    constructor() ERC20("Danny DeVito", "DANNY", 18) {
        _mint(msg.sender, _numTokens * (10 ** 18));
    }

    function eggIt(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}