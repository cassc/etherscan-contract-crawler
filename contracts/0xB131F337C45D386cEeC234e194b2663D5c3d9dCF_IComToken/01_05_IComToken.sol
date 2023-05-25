// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract IComToken is ERC20 {
    constructor() ERC20("iCommunity", "ICOM") {
        _mint(msg.sender, 100000000 * 10**18);
    }

    function burn(uint256 _amount) external {
        _burn(msg.sender, _amount);
    }
}