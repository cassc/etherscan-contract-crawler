// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @custom:security-contact [email protected]
contract Dogggo is ERC20, Ownable {
    uint256 public constant MAX_TRADING_FEE = 30; // 3%
    uint256 public tradingFee;
    address public feeManager;
    bool public isFeeEnabled = true;
    mapping(address => bool) public taxedAddresses;

    event FeeManagerUpdated(address newFeeManager);
    event FeeEnabled(bool isFeeEnabled);
    event TradingFeeUpdated(uint256 tradingFee);
    event TaxedAddressesUpdated(address taxedAddress, bool isTaxed);

    constructor(
        address _feeManager,
        uint256 _tradingFee
    ) ERC20("Dogggo", "DOGGGO") {
        require(_tradingFee <= MAX_TRADING_FEE, "Fee too high");
        require(_feeManager != address(0), "Address invalid");

        tradingFee = _tradingFee;
        feeManager = _feeManager;
        _mint(msg.sender, 10 ** 8 * 10 ** decimals());
    }

    function setTradingFee(uint256 _tradingFee) external onlyOwner {
        require(_tradingFee <= MAX_TRADING_FEE, "Fee too high");

        tradingFee = _tradingFee;
        emit TradingFeeUpdated(_tradingFee);
    }

    function setFeeManager(address _feeManager) external onlyOwner {
        require(_feeManager != address(0), "Address invalid");

        feeManager = _feeManager;
        emit FeeManagerUpdated(_feeManager);
    }

    function toggleFee(bool _isFeeEnabled) external onlyOwner {
        isFeeEnabled = _isFeeEnabled;
        emit FeeEnabled(_isFeeEnabled);
    }

    function manageTaxedAddress(
        address _taxedAddress,
        bool _isTaxed
    ) external onlyOwner {
        require(_taxedAddress != address(0), "Address invalid");

        taxedAddresses[_taxedAddress] = _isTaxed;
        emit TaxedAddressesUpdated(_taxedAddress, _isTaxed);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        uint256 feeAmount = 0;

        if (
            (taxedAddresses[from] || taxedAddresses[to]) &&
            isFeeEnabled &&
            from != owner() &&
            from != feeManager
        ) {
            feeAmount = (amount * tradingFee) / 1000;
            super._transfer(from, feeManager, feeAmount);
        }

        super._transfer(from, to, amount - feeAmount);
    }
}