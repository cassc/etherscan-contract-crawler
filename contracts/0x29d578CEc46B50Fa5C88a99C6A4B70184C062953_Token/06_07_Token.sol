// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./interfaces/IERC20Mintable.sol";


contract Token is Ownable, ERC20, IERC20Mintable {
    uint8 _decimals;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 __decimals
    ) ERC20(_name, _symbol) {
        _decimals = __decimals;
    }

    function decimals() public override view returns(uint8) {
        return _decimals;
    }

    function mint(
        address account,
        uint256 amount
    ) external override onlyOwner {
        _mint(account, amount);
    }

    function burn(
        address account,
        uint256 amount
    ) external override onlyOwner {
        _burn(account, amount);
    }
}