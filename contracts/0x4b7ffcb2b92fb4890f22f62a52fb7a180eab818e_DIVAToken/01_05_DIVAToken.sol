// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DIVAToken is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        address _recipient
    ) ERC20(_name, _symbol) {
        _mint(_recipient, _totalSupply);
    }
}