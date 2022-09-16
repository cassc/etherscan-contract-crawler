pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract Ranshi is ERC20, Ownable {
	using SafeMath for uint256;

	uint256 private TOTAL_SUPPLY = 1000000 * 1e18;

	IUniswapV2Router02 public uniswapV2Router;
	address public uniswapV2Pair;

	mapping(address => bool) private _isExcludedFromFees;
	mapping(address => bool) private _isExcludedMaxTransactionAmount;
	bool public tradingOpen = false;

	uint256 public buyMarketingFee = 2;
	uint256 public buyAutoBurnFee = 0;
	uint256 public sellMarketingFee = 2;
	uint256 public sellAutoBurnFee = 0;

	uint256 public maxTransactionAmount;
	uint256 public maxWalletAmount;

	bool private inSwap = false;
	modifier lockSwap() {
		inSwap = true;
		_;
		inSwap = false;
	}

	constructor() ERC20("Ranshi", "RSH") {
		setupUniswap();

		maxTransactionAmount = TOTAL_SUPPLY / 100; // Max 1% from total supply
		maxWalletAmount = TOTAL_SUPPLY * 5 / 100; // Max 5% from total supply

		_isExcludedFromFees[owner()] = true;
		_isExcludedFromFees[address(this)] = true;

		_isExcludedMaxTransactionAmount[owner()] = true;
		_isExcludedMaxTransactionAmount[address(this)] = true;
		
        _mint(msg.sender, TOTAL_SUPPLY);
	}

	function _transfer(address from, address to, uint256 amount) internal override {
		require(from != address(0), "ERC20: transfer from the zero address");
		require(to != address(0), "ERC20: transfer to the zero address");
		require(amount > 0, 'Transfer amount must be greater than zero');
		require(tradingOpen || _isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active.");
		if (!_isExcludedMaxTransactionAmount[from] && !_isExcludedMaxTransactionAmount[to]) {
			require(amount <= maxTransactionAmount, "Amount invalid." );
			require(balanceOf(to) + amount <= maxWalletAmount, 'Amount invalid.');
		}

		if (inSwap) {
			super._transfer(from, to, amount);
			return;
		}

		amount = takeTaxes(from, to, amount);

		super._transfer(from, to, amount);
	}

	function takeTaxes(address from, address to, uint256 amount) internal returns (uint256) {
		// Buy
		if (from == uniswapV2Pair && !_isExcludedFromFees[to]) {
			if (buyMarketingFee > 0) {
				uint256 marketingFee = amount * buyMarketingFee / 100;
				amount = amount - marketingFee;
			}
			if (buyAutoBurnFee > 0) {
				uint256 burnFee = amount * buyAutoBurnFee / 100;
				super._burn(from, burnFee);
				amount = amount - burnFee;
			}
		}
		// Sell
		else if (to == uniswapV2Pair && !_isExcludedFromFees[from]) {
			if (sellMarketingFee > 0) {
				uint256 marketingFee = amount * sellMarketingFee / 100;
				amount = amount - marketingFee;
			}
			if (sellAutoBurnFee > 0) {
				uint256 burnFee = amount * sellAutoBurnFee / 100;
				super._burn(from, burnFee);
				amount = amount - burnFee;
			}
		}

		return amount;
	}

	function setupUniswap() private {
		uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
		uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
				address(this),
				uniswapV2Router.WETH()
			);
		_approve(address(this), address(uniswapV2Router), type(uint256).max);
	}

	function openTrading() public onlyOwner {
		tradingOpen = true;
	}

	function removeLimits() public onlyOwner {
		maxTransactionAmount = TOTAL_SUPPLY;
		maxWalletAmount = TOTAL_SUPPLY;
	}

	function updateExcludedFromFees(address _address, bool value) public onlyOwner {
		_isExcludedFromFees[_address] = value;
	}

	function updateExcludedMaxTransactionAmount(address _address, bool value) public onlyOwner {
		_isExcludedMaxTransactionAmount[_address] = value;
	}

	function mintMarketingToken(address marketingWallet) public lockSwap onlyOwner {
		uint256 contractTokenBalance = balanceOf(address(this));
		super._transfer(address(this), marketingWallet, contractTokenBalance);
	}
}