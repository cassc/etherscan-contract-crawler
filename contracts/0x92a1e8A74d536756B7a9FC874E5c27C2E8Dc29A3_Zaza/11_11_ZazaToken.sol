// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/VestingWallet.sol";

contract Zaza is ERC20, ERC20Burnable, Ownable, VestingWallet {
    constructor(address _vestingAddress, uint64 _startTime, uint64 _duration) ERC20("Zaza", "ZAZA") VestingWallet(_vestingAddress, _startTime, _duration) 
    {
        _mint(msg.sender, 420000 * 10 ** decimals());
    }
}