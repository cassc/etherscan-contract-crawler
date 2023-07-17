// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Baanx 2021
// BXX Token

contract BXXToken is ERC20 {
    using SafeMath for uint256;

    uint256 constant private INITIAL_AMOUNT_WHOLE_TOKENS = 250e6;

    constructor (string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(
            msg.sender,
            INITIAL_AMOUNT_WHOLE_TOKENS * (10 ** uint256(decimals()))
        );
    }

    function burn(address account, uint256 amount) external {
        _burn(account, amount);
    }
}