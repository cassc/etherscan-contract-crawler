/*

// SPDX-License-Identifier: MIT

/*

Website: Senzubeans.trade
Twitter: https://x.com/senzubeanseth
TG: https://t.me/SenzuBeanETH

*/


pragma solidity ^0.8.20;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Permit.sol";

contract Senzu is ERC20, Ownable, ERC20Permit {
    constructor(address initialOwner)
        ERC20("Senzu", "SENZU")
        Ownable(initialOwner)
        ERC20Permit("Senzu")
    {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}