// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

contract BlockchainSpaceToken is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _amount
    ) public ERC20(_name, _symbol) {
        _mint(msg.sender, _amount);
    }
}