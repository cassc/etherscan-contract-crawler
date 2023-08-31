// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";

contract Token is ERC20, ERC20Burnable, Ownable {

	address public xtaxAddress;
	uint16[3] public xtaxFees;

	mapping (address => bool) public isExcludedFromFees;

	uint16[3] public totalFees;
	bool private _swapping;

	// Disabled as the default and will be activated prior to the token launch.
	bool tradingActive = false;

	address addrOwner = 0x489Cec81305F6dDc71A11354b6286612aa21817c;
	address addrTaxes = 0xdf196D7F12C79c65fdAf5dEF71B290c78C8A79f9;
	address uniswapRouterV2 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

	IUniswapV2Router02 public routerV2;
	address public pairV2;
	mapping (address => bool) public AMMPairs;
 
	event xtaxAddressUpdated(address xtaxAddress);
	event xtaxFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
	event xtaxFeeSent(address recipient, uint256 amount);

	event ExcludeFromFees(address indexed account, bool isExcluded);

	event RouterV2Updated(address indexed routerV2);
	event AMMPairsUpdated(address indexed AMMPair, bool isPair);
 
	constructor()
		ERC20(unicode"John Doe", unicode"JOHN") 
	{
		// Taxes Buy & Sell 1%
		// No Transfer Fee
		xtaxAddressSetup(addrTaxes);
		xtaxFeesSetup(100, 100, 0);

		_excludeFromFees(addrOwner, true);
		_excludeFromFees(address(this), true); 

		_updateRouterV2(uniswapRouterV2);
	
		_mint(addrOwner, 10000000000 * (10 ** decimals()) / 10);
		_transferOwnership(addrOwner);

	}

	receive() external payable {}

	function enableTrading(bool _tradingActive) public onlyOwner {
		tradingActive = _tradingActive;
	}

	function decimals() public pure override returns (uint8) {
		return 18;
	}
	
	function _sendInTokens(address from, address to, uint256 amount) private {
		super._transfer(from, to, amount);
	}

	function xtaxAddressSetup(address _newAddress) public onlyOwner {
		xtaxAddress = _newAddress;

		_excludeFromFees(_newAddress, true);

		emit xtaxAddressUpdated(_newAddress);
	}

	function xtaxFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
		xtaxFees = [_buyFee, _sellFee, _transferFee];

		totalFees[0] = 0 + xtaxFees[0];
		totalFees[1] = 0 + xtaxFees[1];
		totalFees[2] = 0 + xtaxFees[2];
		require(totalFees[0] <= 2500 && totalFees[1] <= 2500 && totalFees[2] <= 2500, "TaxesDefaultRouter: Cannot exceed max total fee of 25%");

		emit xtaxFeesUpdated(_buyFee, _sellFee, _transferFee);
	}

	function _excludeFromFees(address account, bool isExcluded) private  {
		isExcludedFromFees[account] = isExcluded;
		
		emit ExcludeFromFees(account, isExcluded);
	}

	function excludeFromFees(address[] calldata _accounts) public onlyOwner {

		require(_accounts.length > 0, "Cannot be empty");

		for (uint256 i = 0; i < _accounts.length; i++) {
			_excludeFromFees(_accounts[i], true);
		}
	}

	function _transfer(
		address from,
		address to,
		uint256 amount
	) internal override {
		
		if (!_swapping && amount > 0 && to != address(routerV2) && !isExcludedFromFees[from] && !isExcludedFromFees[to]) {
			uint256 fees = 0;
			uint8 txType = 3;
			
			if (AMMPairs[from]) {
				if (totalFees[0] > 0) txType = 0;
			}
			else if (AMMPairs[to]) {
				if (totalFees[1] > 0) txType = 1;
			}
			else if (totalFees[2] > 0) txType = 2;
			
			if (txType < 3) {
				
				uint256 xtaxPortion = 0;

				fees = amount * totalFees[txType] / 10000;
				amount -= fees;
				
				if (xtaxFees[txType] > 0) {
					xtaxPortion = fees * xtaxFees[txType] / totalFees[txType];
					_sendInTokens(from, xtaxAddress, xtaxPortion);
					emit xtaxFeeSent(xtaxAddress, xtaxPortion);
				}

				fees = fees - xtaxPortion;
			}

			if (fees > 0) {
				super._transfer(from, address(this), fees);
			}
		}
		
		super._transfer(from, to, amount);
		
	}

	function _updateRouterV2(address router) private {
		routerV2 = IUniswapV2Router02(router);
		pairV2 = IUniswapV2Factory(routerV2.factory()).createPair(address(this), routerV2.WETH());
		
		_setAMMPair(pairV2, true);

		emit RouterV2Updated(router);
	}

	function setAMMPair(address pair, bool isPair) public onlyOwner {
		require(pair != pairV2, "DefaultRouter: Cannot remove initial pair from list");

		_setAMMPair(pair, isPair);
	}

	function _setAMMPair(address pair, bool isPair) private {
		AMMPairs[pair] = isPair;

		if (isPair) { 
		}

		emit AMMPairsUpdated(pair, isPair);
	}

	function _beforeTokenTransfer(address from, address to, uint256 amount)
		internal
		override
	{
		require(tradingActive || (to == addrOwner) || (from == addrOwner), "Trading Not Active");
		super._beforeTokenTransfer(from, to, amount);
	}

	function _afterTokenTransfer(address from, address to, uint256 amount)
		internal
		override
	{
		super._afterTokenTransfer(from, to, amount);
	}
}