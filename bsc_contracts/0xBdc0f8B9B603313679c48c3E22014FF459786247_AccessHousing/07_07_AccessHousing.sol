// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AccessHousing is ERC20, ERC20Burnable, Ownable {
    constructor(address _account) ERC20("Access Housing", "AhouZ") {
        _mint(_account, 10000000000000000000000000 * 10 ** decimals());
    }
}