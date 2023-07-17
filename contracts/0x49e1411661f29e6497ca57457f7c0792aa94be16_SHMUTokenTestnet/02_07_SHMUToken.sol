// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "./openzeppelin/token/ERC20/ERC20.sol";
import "./openzeppelin/access/Ownable.sol";

contract SHMUToken is ERC20, Ownable {
    constructor(uint256 _initialSupply) ERC20("ShibaMemu", "SHMU") Ownable() {
        _mint(msg.sender, _initialSupply * 10 ** decimals());
    }

    function burn(uint256 _amount) public {
        _burn(msg.sender, _amount);
    }
}