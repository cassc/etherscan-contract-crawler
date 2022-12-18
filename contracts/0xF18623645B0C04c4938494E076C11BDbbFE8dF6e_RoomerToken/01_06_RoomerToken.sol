// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract RoomerToken is ERC20Burnable {
    constructor(uint256 _mintAmount, address _recipient) ERC20("Artrooms.app Roomer Token", "ROOMER") {
        _mint(_recipient, _mintAmount * 10 ** decimals());
    }
}