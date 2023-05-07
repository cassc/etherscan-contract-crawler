// Twitter: https://twitter.com/wagdie_eth

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "solmate/tokens/ERC20.sol";

contract WAGDIE is ERC20 {
    uint private constant _numTokens = 666666666666669;

    constructor() ERC20("We Are All Going to Die", "WAGDIE", 18) {
        _mint(msg.sender, _numTokens * (10 ** 18));
    }

    function kill(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}