// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HeDz is ERC20, ERC20Burnable, Ownable {
    uint256 public tax;
    string private constant _name = 'HeDz';
    string private constant _symbol = 'HeDz';

    uint256 private constant TOTAL_SUPPLY = 10000000000 * 10 ** 18;
    constructor() ERC20(_name, _symbol) {
        tax = 1; 
        _mint(msg.sender, TOTAL_SUPPLY);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        if (sender != owner() && recipient != owner()) {

            uint256 taxAmount = (amount * tax) / 100;
            uint256 transferAmount = amount - taxAmount;

            super._transfer(sender, recipient, transferAmount);

            super._transfer(sender, address(this), taxAmount);
        } else {
            super._transfer(sender, recipient, amount);
        }
    }
}