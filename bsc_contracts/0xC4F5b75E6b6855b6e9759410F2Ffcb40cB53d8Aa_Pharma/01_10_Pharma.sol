// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./BEP20/BEP20Feeable.sol";

contract Pharma is BEP20Feeable, ERC20Burnable {
    string private _name = "Pharma";
    string private _symbol = "RXT";
    uint8 private _decimals = 8;
    address public vault;
    address public dividend;

    constructor(
        uint256 initialSupply_,
        address vault_,
        address dividend_
    ) BEP20Feeable(_name, _symbol) {
        _mint(_msgSender(), initialSupply_);
        vault = vault_;
        _isExcludedFromOutgoingFee[vault] = true;
        _isExcludedFromIncomingFee[vault] = true;
        dividend = dividend_;
        _isExcludedFromOutgoingFee[dividend] = true;
        _isExcludedFromIncomingFee[dividend] = true;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfer(from, to, amount);

        if (_shouldTakeFee(from, to)) {
            uint256 onePercent = amount / 100;
            uint256 vaultFee = onePercent * 5;
            uint256 dividendFee = onePercent * 5;
            uint256 totalFee = vaultFee + dividendFee;
            require(
                balanceOf(from) >= amount + totalFee,
                "RXT: transfer amount with fees exceeds balance"
            );
            // vault fees
            _transfer(from, vault, vaultFee);
            // dividend fees
            _transfer(from, dividend, dividendFee);
            emit Fee(from, totalFee);
        }
    }

    /**
     * @dev Sets the vault address and excludes it from fees
     */
    function setVault(address newVault) external onlyOwner {
        require(vault != newVault, "RXT: vault address cannot be the same");
        _isExcludedFromOutgoingFee[vault] = false;
        _isExcludedFromIncomingFee[vault] = false;
        _isExcludedFromOutgoingFee[newVault] = true;
        _isExcludedFromIncomingFee[newVault] = true;
        vault = newVault;
    }

    /**
     * @dev Sets the dividend address and excludes it from fees
     */
    function setDividend(address newDividend) external onlyOwner {
        require(
            dividend != newDividend,
            "RXT: dividend address cannot be the same"
        );
        _isExcludedFromOutgoingFee[dividend] = false;
        _isExcludedFromIncomingFee[dividend] = false;
        _isExcludedFromOutgoingFee[newDividend] = true;
        _isExcludedFromIncomingFee[newDividend] = true;
        dividend = newDividend;
    }
}