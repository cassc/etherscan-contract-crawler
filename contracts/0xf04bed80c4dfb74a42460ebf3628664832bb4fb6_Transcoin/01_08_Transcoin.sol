// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Transcoin is ERC20Upgradeable, OwnableUpgradeable {
    // Mapping to track whitelisted addresses
    mapping(address => bool) private _whitelist;

    // Sell tax rate (5%)
    uint256 private _sellTaxRate;

    // Addresses for Uniswap liquidity pool and router
    address public uniswapLiquidityPool;
    address public uniswapRouter;

    // Events
    event SellTaxRateChanged(uint256 newRate);
    event AddressWhitelisted(address indexed account, bool whitelisted);

    function initialize() initializer public {
        __ERC20_init("Transcoin", "TRNS");
        __Ownable_init();

        // Mint the initial supply to the contract owner
        _mint(_msgSender(), 800057907687 * 10**18); // Total supply with 18 decimals

        // Initialize the sell tax rate (5%)
        _sellTaxRate = 5;
    }

    function setUniswapAddresses(address liquidityPool, address router) external onlyOwner {
        uniswapLiquidityPool = liquidityPool;
        uniswapRouter = router;
    }

    function setSellTaxRate(uint256 newRate) external onlyOwner {
        require(newRate <= 100, "Sell tax rate must be less than or equal to 100%");
        _sellTaxRate = newRate;
        emit SellTaxRateChanged(newRate);
    }

    function whitelistAddress(address account, bool whitelisted) external onlyOwner {
        _whitelist[account] = whitelisted;
        emit AddressWhitelisted(account, whitelisted);
    }

    // ERC-20 transfer function with tax on sell
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        bool isExemptFromTax = (sender == owner() || sender == uniswapRouter || _whitelist[sender]);

        if (!isExemptFromTax) {
            // Sell tax is applied (except for the exempt addresses)
            uint256 sellTax = (amount * _sellTaxRate) / 100;
            uint256 transferAmount = amount - sellTax;

            super._transfer(sender, address(this), sellTax); // Transfer tax to contract

            // Transfer the remaining amount to the recipient
            super._transfer(sender, recipient, transferAmount);
        } else {
            // No tax for the exempt addresses
            super._transfer(sender, recipient, amount);
        }
    }

    // Check if an address is whitelisted (exempt from taxes)
    function isWhitelisted(address account) public view returns (bool) {
        return _whitelist[account];
    }

    // Returns the current sell tax rate
    function getSellTaxRate() public view returns (uint256) {
        return _sellTaxRate;
    }
}