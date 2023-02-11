// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "ERC20.sol";

contract LotteryToken is ERC20 {
    constructor(uint256 initialSupply)
        ERC20("LotteryHost.com", "LotteryHost.com")
    {
        _mint(msg.sender, initialSupply);
    }
}