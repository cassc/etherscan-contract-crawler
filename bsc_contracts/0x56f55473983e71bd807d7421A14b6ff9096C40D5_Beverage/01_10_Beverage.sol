// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./BEP20/BEP20Feeable.sol";

contract Beverage is BEP20Feeable, ERC20Burnable {
    string private _name = "Beverage";
    string private _symbol = "BEV";
    uint8 private _decimals = 8;

    constructor() BEP20Feeable(_name, _symbol) {}

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function mint(uint256 amount) public onlyOwner {
        _mint(_msgSender(), amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfer(from, to, amount);

        if (_shouldTakeFee(from, to)) {
            uint256 onePercent = amount / 100;
            uint256 burnFee = onePercent * 10;
            uint256 totalFee = burnFee;
            require(
                balanceOf(from) >= amount + totalFee,
                "BEV: transfer amount with fees exceeds balance"
            );
            // burn
            _burn(from, burnFee);
            emit Fee(from, totalFee);
        }
    }
}