// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract XFAToken is ERC20 {
    constructor() ERC20("XFA Token", "XFA") {
        _mint(msg.sender, 500000000 * 10**18);
    }

    function burn(uint256 _amount) external {
        _burn(msg.sender, _amount);
    }
}