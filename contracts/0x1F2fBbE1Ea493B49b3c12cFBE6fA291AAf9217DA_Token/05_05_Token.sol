// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }

    function mint(address _addr, uint256 _amount) external {
        _mint(_addr, _amount);
    }

    function burn(address _addr, uint256 _amount) external {
        _burn(_addr, _amount);
    }
}