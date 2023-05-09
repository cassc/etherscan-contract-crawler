// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./BEP20/BEP20Feeable.sol";

contract DigitalGold is BEP20Feeable, ERC20Burnable {
    string private _name = "DigitalGold";
    string private _symbol = "DLG";
    uint8 private _decimals = 8;
    uint8 private _burnPercentage = 10;

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
            uint256 burnFee = (amount * _burnPercentage) / 100;
            uint256 totalFee = burnFee;
            require(
                balanceOf(from) >= amount + totalFee,
                "DLG: transfer amount with fees exceeds balance"
            );
            _burn(from, burnFee);
            emit Fee(from, totalFee);
        }
    }
}