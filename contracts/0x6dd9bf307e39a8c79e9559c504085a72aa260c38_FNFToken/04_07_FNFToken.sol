// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./Ownable.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";


contract FNFToken is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("MESS", "MESS") {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
