// SPDX-License-Identifier: UNLICENSED
// programmed = $1
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IUniswapV2Factory {
	function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router01 {
	function factory() external pure returns (address);

	function WETH() external pure returns (address);

	function addLiquidityETH(
		address token,
		uint amountTokenDesired,
		uint amountTokenMin,
		uint amountETHMin,
		address to,
		uint deadline
	) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
	function swapExactTokensForETHSupportingFeeOnTransferTokens(
		uint amountIn,
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external;
}

contract unUSD is ERC20, Ownable {
	IUniswapV2Router02 public immutable router;
	address public immutable uniswapV2Pair;

	// addresses
	address public devWallet;
	address private marketingWallet;

	// limits
	uint256 private maxBuyAmount;
	uint256 private maxSellAmount;
	uint256 private maxWalletAmount;

	uint256 private thresholdSwapAmount;

	// status flags
	bool private isTrading = false;
	bool public swapEnabled = false;
	bool public isSwapping;

	struct Fees {
		uint8 buyTotalFees;
		uint8 buyMarketingFee;
		uint8 buyDevFee;
		uint8 buyLiquidityFee;
		uint8 sellTotalFees;
		uint8 sellMarketingFee;
		uint8 sellDevFee;
		uint8 sellLiquidityFee;
	}

	Fees public _fees =
		Fees({
			buyTotalFees: 0,
			buyMarketingFee: 0,
			buyDevFee: 0,
			buyLiquidityFee: 0,
			sellTotalFees: 0,
			sellMarketingFee: 0,
			sellDevFee: 0,
			sellLiquidityFee: 0
		});

	uint256 public tokensForMarketing;
	uint256 public tokensForLiquidity;
	uint256 public tokensForDev;
	uint256 private taxTill;
	// exclude from fees and max transaction amount
	mapping(address => bool) private _isExcludedFromFees;
	mapping(address => bool) public _isExcludedMaxTransactionAmount;
	mapping(address => bool) public _isExcludedMaxWalletAmount;

	// store addresses that a automatic market maker pairs. Any transfer *to* these addresses
	// could be subject to a maximum transfer amount
	mapping(address => bool) public marketPair;
	mapping(address => bool) public _isBlacklisted;

	event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived);

	modifier lockTheSwap() {
		isSwapping = true;
		_;
		isSwapping = false;
	}

	constructor(
		address _marketingWallet,
		address _devWallet,
		string memory _name,
		string memory _symbol,
		uint256 _totalSupply,
		uint256 _prelaunchAmount,
		address _prelaunch
	) ERC20(_name, _symbol) {
		router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

		uniswapV2Pair = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());

		_isExcludedMaxTransactionAmount[address(router)] = true;
		_isExcludedMaxTransactionAmount[address(uniswapV2Pair)] = true;
		_isExcludedMaxTransactionAmount[owner()] = true;
		_isExcludedMaxTransactionAmount[address(this)] = true;
		_isExcludedMaxTransactionAmount[_prelaunch] = true;

		_isExcludedFromFees[owner()] = true;
		_isExcludedFromFees[_prelaunch] = true;
		_isExcludedFromFees[address(this)] = true;

		_isExcludedMaxWalletAmount[owner()] = true;
		_isExcludedMaxWalletAmount[address(this)] = true;
		_isExcludedMaxWalletAmount[address(uniswapV2Pair)] = true;
		_isExcludedMaxWalletAmount[_prelaunch] = true;

		marketPair[address(uniswapV2Pair)] = true;

		approve(address(router), type(uint256).max);

		maxBuyAmount = (_totalSupply * 2) / 100; // 2% maxTransactionAmountTxn
		maxSellAmount = (_totalSupply * 2) / 100; // 2% maxTransactionAmountTxn
		maxWalletAmount = (_totalSupply * 2) / 100; // 2% maxWallet
		thresholdSwapAmount = (_totalSupply * 1) / 10000; // 0.01% swap wallet

		_fees.buyMarketingFee = 1;
		_fees.buyLiquidityFee = 1;
		_fees.buyDevFee = 1;
		_fees.buyTotalFees = _fees.buyMarketingFee + _fees.buyLiquidityFee + _fees.buyDevFee;

		_fees.sellMarketingFee = 1;
		_fees.sellLiquidityFee = 1;
		_fees.sellDevFee = 1;
		_fees.sellTotalFees = _fees.sellMarketingFee + _fees.sellLiquidityFee + _fees.sellDevFee;

		marketingWallet = _marketingWallet;
		devWallet = _devWallet;

		_mint(msg.sender, _totalSupply - _prelaunchAmount);
		_mint(_prelaunch, _prelaunchAmount);
	}

	receive() external payable {}

	// once enabled, can never be turned off
	function swapTrading() external onlyOwner {
		isTrading = true;
		swapEnabled = true;
		taxTill = block.number + 2;
	}

	// change the minimum amount of tokens to sell from fees
	function updateThresholdSwapAmount(uint256 newAmount) external onlyOwner returns (bool) {
		thresholdSwapAmount = newAmount;
		return true;
	}

	function updateMaxTxnAmount(uint256 newMaxBuy, uint256 newMaxSell) external onlyOwner {
		require(((totalSupply() * newMaxBuy) / 1000) >= (totalSupply() / 100), "maxBuyAmount must be higher than 1%");
		require(((totalSupply() * newMaxSell) / 1000) >= (totalSupply() / 100), "maxSellAmount must be higher than 1%");
		maxBuyAmount = (totalSupply() * newMaxBuy) / 1000;
		maxSellAmount = (totalSupply() * newMaxSell) / 1000;
	}

	function updateMaxWalletAmount(uint256 newPercentage) external onlyOwner {
		require(
			((totalSupply() * newPercentage) / 1000) >= (totalSupply() / 100),
			"Cannot set maxWallet lower than 1%"
		);
		maxWalletAmount = (totalSupply() * newPercentage) / 1000;
	}

	// only use to disable contract sales if absolutely necessary (emergency use only)
	function toggleSwapEnabled(bool enabled) external onlyOwner {
		swapEnabled = enabled;
	}

	function blacklistAddress(address account, bool value) external onlyOwner {
		_isBlacklisted[account] = value;
	}

	function updateFees(
		uint8 _marketingFeeBuy,
		uint8 _liquidityFeeBuy,
		uint8 _devFeeBuy,
		uint8 _marketingFeeSell,
		uint8 _liquidityFeeSell,
		uint8 _devFeeSell
	) external onlyOwner {
		_fees.buyMarketingFee = _marketingFeeBuy;
		_fees.buyLiquidityFee = _liquidityFeeBuy;
		_fees.buyDevFee = _devFeeBuy;
		_fees.buyTotalFees = _fees.buyMarketingFee + _fees.buyLiquidityFee + _fees.buyDevFee;

		_fees.sellMarketingFee = _marketingFeeSell;
		_fees.sellLiquidityFee = _liquidityFeeSell;
		_fees.sellDevFee = _devFeeSell;
		_fees.sellTotalFees = _fees.sellMarketingFee + _fees.sellLiquidityFee + _fees.sellDevFee;
		require(_fees.buyTotalFees <= 30, "Must keep fees at 30% or less");
		require(_fees.sellTotalFees <= 30, "Must keep fees at 30% or less");
	}

	function excludeFromFees(address account, bool excluded) public onlyOwner {
		_isExcludedFromFees[account] = excluded;
	}

	function excludeFromWalletLimit(address account, bool excluded) public onlyOwner {
		_isExcludedMaxWalletAmount[account] = excluded;
	}

	function excludeFromMaxTransaction(address updAds, bool isEx) public onlyOwner {
		_isExcludedMaxTransactionAmount[updAds] = isEx;
	}

	function setMarketPair(address pair, bool value) public onlyOwner {
		require(pair != uniswapV2Pair, "Must keep uniswapV2Pair");
		marketPair[pair] = value;
	}

	function setWallets(address _marketingWallet, address _devWallet) external onlyOwner {
		marketingWallet = _marketingWallet;
		devWallet = _devWallet;
	}

	function isExcludedFromFees(address account) public view returns (bool) {
		return _isExcludedFromFees[account];
	}

	function _transfer(address sender, address recipient, uint256 amount) internal override {
		if (amount == 0) {
			super._transfer(sender, recipient, 0);
			return;
		}

		if (sender != owner() && recipient != owner() && !isSwapping) {
			if (!isTrading) {
				require(_isExcludedFromFees[sender] || _isExcludedFromFees[recipient], "Trading is not active.");
			}
			if (marketPair[sender] && !_isExcludedMaxTransactionAmount[recipient]) {
				require(amount <= maxBuyAmount, "buy transfer over max amount");
			} else if (marketPair[recipient] && !_isExcludedMaxTransactionAmount[sender]) {
				require(amount <= maxSellAmount, "Sell transfer over max amount");
			}

			if (!_isExcludedMaxWalletAmount[recipient]) {
				require(amount + balanceOf(recipient) <= maxWalletAmount, "Max wallet exceeded");
			}
			require(!_isBlacklisted[sender] && !_isBlacklisted[recipient], "Blacklisted address");
		}

		uint256 contractTokenBalance = balanceOf(address(this));

		bool canSwap = contractTokenBalance >= thresholdSwapAmount;

		if (
			canSwap &&
			swapEnabled &&
			!isSwapping &&
			marketPair[recipient] &&
			!_isExcludedFromFees[sender] &&
			!_isExcludedFromFees[recipient]
		) {
			swapBack();
		}

		bool takeFee = !isSwapping;

		// if any account belongs to _isExcludedFromFee account then remove the fee
		if (_isExcludedFromFees[sender] || _isExcludedFromFees[recipient]) {
			takeFee = false;
		}

		// only take fees on buys/sells, do not take on wallet transfers
		if (takeFee) {
			uint256 fees = 0;
			if (block.number < taxTill) {
				fees = (amount * 99) / 100;
				tokensForMarketing += (fees * 94) / 99;
				tokensForDev += (fees * 5) / 99;
			} else if (marketPair[recipient] && _fees.sellTotalFees > 0) {
				fees = (amount * _fees.sellTotalFees) / 100;
				tokensForLiquidity += (fees * _fees.sellLiquidityFee) / _fees.sellTotalFees;
				tokensForMarketing += (fees * _fees.sellMarketingFee) / _fees.sellTotalFees;
				tokensForDev += (fees * _fees.sellDevFee) / _fees.sellTotalFees;
			}
			// on buy
			else if (marketPair[sender] && _fees.buyTotalFees > 0) {
				fees = (amount * _fees.buyTotalFees) / 100;
				tokensForLiquidity += (fees * _fees.buyLiquidityFee) / _fees.buyTotalFees;
				tokensForMarketing += (fees * _fees.buyMarketingFee) / _fees.buyTotalFees;
				tokensForDev += (fees * _fees.buyDevFee) / _fees.buyTotalFees;
			}

			if (fees > 0) {
				super._transfer(sender, address(this), fees);
			}

			amount -= fees;
		}

		super._transfer(sender, recipient, amount);
	}

	function swapTokensForEth(uint256 tAmount) private {
		// generate the uniswap pair path of token -> weth
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = router.WETH();

		_approve(address(this), address(router), tAmount);

		// make the swap
		router.swapExactTokensForETHSupportingFeeOnTransferTokens(
			tAmount,
			0, // accept any amount of ETH
			path,
			address(this),
			block.timestamp
		);
	}

	function addLiquidity(uint256 tAmount, uint256 ethAmount) private {
		// approve token transfer to cover all possible scenarios
		_approve(address(this), address(router), tAmount);

		// add the liquidity
		router.addLiquidityETH{ value: ethAmount }(address(this), tAmount, 0, 0, address(this), block.timestamp);
	}

	function swapBack() private lockTheSwap {
		uint256 contractTokenBalance = balanceOf(address(this));
		uint256 toSwap = tokensForLiquidity + tokensForMarketing + tokensForDev;
		bool success;

		if (contractTokenBalance == 0 || toSwap == 0) {
			return;
		}

		if (contractTokenBalance > thresholdSwapAmount * 20) {
			contractTokenBalance = thresholdSwapAmount * 20;
		}

		// Halve the amount of liquidity tokens
		uint256 liquidityTokens = (contractTokenBalance * tokensForLiquidity) / toSwap / 2;
		uint256 amountToSwapForETH = contractTokenBalance - liquidityTokens;

		uint256 initialETHBalance = address(this).balance;

		swapTokensForEth(amountToSwapForETH);

		uint256 newBalance = address(this).balance - initialETHBalance;

		uint256 ethForMarketing = (newBalance * tokensForMarketing) / toSwap;
		uint256 ethForDev = (newBalance * tokensForDev) / toSwap;
		uint256 ethForLiquidity = newBalance - (ethForMarketing + ethForDev);

		tokensForLiquidity = 0;
		tokensForMarketing = 0;
		tokensForDev = 0;

		if (liquidityTokens > 0 && ethForLiquidity > 0) {
			addLiquidity(liquidityTokens, ethForLiquidity);
			emit SwapAndLiquify(amountToSwapForETH, ethForLiquidity);
		}

		(success, ) = address(devWallet).call{ value: (address(this).balance - ethForMarketing) }("");
		(success, ) = address(marketingWallet).call{ value: address(this).balance }("");
	}
}