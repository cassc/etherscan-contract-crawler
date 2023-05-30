// SPDX-License-Identifier: MIT
// NIFTSY protocol ERC20
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./MinterRole.sol";


contract TechToken is ERC20, MinterRole {

    constructor()
    ERC20("Virtual Envelop Transfer Fee Token", "vENVLP")
    MinterRole(msg.sender)
    { 
    }

    function mint(address _to, uint256 _value) external onlyMinter {
        _mint(_to, _value);
    }

}