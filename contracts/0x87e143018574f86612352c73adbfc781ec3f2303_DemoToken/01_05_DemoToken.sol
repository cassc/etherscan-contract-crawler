// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DemoToken is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }

    function mint(address _addr, uint _amount) external {
         _mint(_addr, _amount);
    }

    function burn(address _addr, uint _amount) external {
         _burn(_addr, _amount);
    }
}