// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/draft-ERC20Permit.sol";

contract xFlash is ERC20, Ownable, ERC20Permit {
    constructor()
        ERC20("Flash KPI (May 1st 2024)", "xFlash")
        ERC20Permit("Flash KPI (May 1st 2024)")
    {
        _mint(msg.sender, 1500000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}