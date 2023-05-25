// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Xfit is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _amount,
        address token_holder
    ) public ERC20(_name, _symbol) {
        _mint(token_holder, _amount);
    }
}