// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract NFTToken is ERC20 {
    address public admin;
    uint256 public sellTaxRate = 1;
    address public taxReceiver;

    event AdminChanged(address indexed newAdmin);
    event TaxRatesChanged(uint256 sellTaxRate);
    event TaxReceiverChanged(address indexed newTaxReceiver);

    constructor(address _admin, address _taxReceiver) ERC20("Original Mate NFT", "OMN") {
        admin = _admin;
        taxReceiver = _taxReceiver;
        _mint(msg.sender, 39 * 10 ** 8);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    function setAdmin(address newAdmin) external onlyAdmin {
        admin = newAdmin;
        emit AdminChanged(newAdmin);
    }

    function setTaxRates(uint256 _sellTaxRate) external onlyAdmin {
        sellTaxRate = _sellTaxRate;
        emit TaxRatesChanged(_sellTaxRate);
    }

    function setTaxReceiver(address newTaxReceiver) external onlyAdmin {
        taxReceiver = newTaxReceiver;
        emit TaxReceiverChanged(newTaxReceiver);
    }

    function transfer(address to, uint256 value) public virtual override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public virtual override returns (bool) {
        _transfer(from, to, value - value * sellTaxRate / 100);
        _transfer(from, taxReceiver, value * sellTaxRate / 100);
        uint256 currentAllowance = allowance(from, msg.sender);
        require(currentAllowance >= value, "ERC20: transfer amount exceeds allowance");
        _approve(from, msg.sender, currentAllowance - value);
        return true;
    }

}
