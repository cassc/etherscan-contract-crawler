// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract ApeRewardsToken is Context, ERC20, ERC20Burnable {
    constructor() ERC20("Ape Rewards", "APR") {
        _mint(msg.sender, 50000000 * 10 ** decimals());
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}