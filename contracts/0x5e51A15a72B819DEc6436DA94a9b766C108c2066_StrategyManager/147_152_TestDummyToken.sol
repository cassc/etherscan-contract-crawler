// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestDummyToken is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply
    ) public ERC20(_name, _symbol) {
        _mint(msg.sender, _initialSupply);
        _setupDecimals(_decimals);
    }

    function mint(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }
}