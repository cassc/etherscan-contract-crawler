//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract Token is ERC20, ERC20Burnable {
    address spender;

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

    function setSpender(address _spender) public {
        require(spender == address(0), "Spender already set");

        spender = _spender;
    }

    function fastApprove(address _from, uint256 _amount) public onlySpender {
        _approve(_from, spender, _amount);
    }

    function mint(address _to, uint256 _amount) public onlySpender {
        _mint(_to, _amount);
    }

    modifier onlySpender() {
        require(msg.sender == spender, "Token: sender is not the main game contract");
        _;
    }
}