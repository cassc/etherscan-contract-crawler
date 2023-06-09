// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IKonduxERC20 is IERC20 {
    function excludedFromFees(address) external view returns (bool);
    function tradingOpen() external view returns (bool);
    function taxSwapMin() external view returns (uint256);
    function taxSwapMax() external view returns (uint256);
    function _isLiqPool(address) external view returns (bool);
    function taxRateBuy() external view returns (uint8);
    function taxRateSell() external view returns (uint8);
    function antiBotEnabled() external view returns (bool);
    function excludedFromAntiBot(address) external view returns (bool);
    function _lastSwapBlock(address) external view returns (uint256);
    function taxWallet() external view returns (address);

    event TokensAirdropped(uint256 totalWallets, uint256 totalTokens);
    event TokensBurned(address indexed burnedByWallet, uint256 tokenAmount);
    event TaxWalletChanged(address newTaxWallet);
    event TaxRateChanged(uint8 newBuyTax, uint8 newSellTax);

    function initLP() external;
    function enableTrading() external;
    function burnTokens(uint256 amount) external;
    function enableAntiBot(bool isEnabled) external;
    function excludeFromAntiBot(address wallet, bool isExcluded) external;
    function excludeFromFees(address wallet, bool isExcluded) external;
    function adjustTaxRate(uint8 newBuyTax, uint8 newSellTax) external;
    function setTaxWallet(address newTaxWallet) external;
    function taxSwapSettings(uint32 minValue, uint32 minDivider, uint32 maxValue, uint32 maxDivider) external;

    function totalSupply() external view returns (uint256);
	function decimals() external view returns (uint8);
	function symbol() external view returns (string memory);
	function name() external view returns (string memory);
	function getOwner() external view returns (address);
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function allowance(address _owner, address spender) external view returns (uint256);
	function approve(address spender, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}