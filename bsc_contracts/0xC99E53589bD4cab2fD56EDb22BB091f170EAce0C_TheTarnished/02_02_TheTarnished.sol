// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Libraries.sol";

contract TheTarnished is ERC20, Ownable {
	using SafeMath for uint256;
	
	IUniswapV2Router02 public uniswapV2Router;
	address public uniswapV2Pair;
	
	ERC20 public usdtTokenAddr;
	
	bool private swapping;
	
	address public feeWallet;
	
	uint256 public maxTransactionAmount;
	uint256 public swapTokensAtAmount;
	
	bool public limitsInEffect = true;
	bool public tradingActive = false;
	bool public swapEnabled = false;
	
	// sell fees
	uint256 public transferFee;
	uint256 public businessFee;
	
	uint256 public feeDivisor;
	
	uint256 private _feeTokensToSwap;
	
	/******************/
	
	// exlcude from fees and max transaction amount
	mapping(address => bool) private _isExcludedFromFees;
	mapping(address => bool) public _isExcludedMaxTransactionAmount;
	
	// store addresses that a automatic market maker pairs. Any transfer *to* these addresses
	// could be subject to a maximum transfer amount
	mapping(address => bool) public automatedMarketMakerPairs;
	
	event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
	
	event ExcludeFromFees(address indexed account, bool isExcluded);
	
	event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
	
	event Swap(
		uint256 tokensSwapped,
		uint256 usdtReceived
	);
	
	constructor() ERC20("TheTarnished", "TTD") payable {
		
		uint256 totalSupply = 1_7500_000 * 1e18;
		
		maxTransactionAmount = totalSupply * 5 / 1000;
		// 0.5% maxTransactionAmountTxn
		swapTokensAtAmount = totalSupply * 5 / 10000;
		// 0.05% swap tokens amount
		
		// set fees
		transferFee = 20;
		businessFee = 50;
		
		feeDivisor = 1000;
		
		feeWallet = address(0x684DAcc25961A7d7B2c5E2af49323913447c455B);
		
		IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
		// ROPSTEN or HARDHAT
			0x10ED43C718714eb63d5aA57B78B54704E256024E
		);
		
		ERC20 _usdtTokenAddr = ERC20(0x55d398326f99059fF775485246999027B3197955);
		
		address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
		.createPair(address(this), _uniswapV2Router.WETH());
		
		uniswapV2Router = _uniswapV2Router;
		uniswapV2Pair = _uniswapV2Pair;
		usdtTokenAddr = _usdtTokenAddr;
		
		_setAutomatedMarketMakerPair(_uniswapV2Pair, true);
		
		// exclude from paying fees or having max transaction amount
		excludeFromFees(owner(), true);
		excludeFromFees(address(this), true);
		excludeFromFees(address(0xdead), true);
		
		excludeFromMaxTransaction(owner(), true);
		excludeFromMaxTransaction(address(this), true);
		
		excludeFromMaxTransaction(address(0xdead), true);
		
		/*liquidityWallet
			_mint is an internal function in ERC20.sol that is only called here,
			and CANNOT be called ever again
		*/
		_mint(address(owner()), totalSupply);
	}
	
	receive() external payable {
	
	}
	
	// once enabled, can never be turned off (can be called automatically by launching, but use this with a manual Uniswap add if needed)
	function enableTrading() public onlyOwner {
		tradingActive = true;
		swapEnabled = true;
	}
	
	// remove limits after token is stable
	function removeLimits() external onlyOwner returns (bool){
		limitsInEffect = false;
		return true;
	}
	
	// change the minimum amount of tokens to sell from fees
	function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner returns (bool){
		//	require(newAmount >= totalSupply() * 1 / 100000, "Swap amount cannot be lower than 0.001% total supply.");
		require(newAmount <= totalSupply() * 5 / 1000, "Swap amount cannot be higher than 0.5% total supply.");
		swapTokensAtAmount = newAmount;
		return true;
	}
	
	function updateMaxAmount(uint256 newNum) external onlyOwner {
		require(newNum >= (totalSupply() * 5 / 1000) / 1e18, "Cannot set maxTransactionAmount lower than 0.5%");
		maxTransactionAmount = newNum * (10 ** 18);
	}
	
	
	function updateFees(uint256 _transferFee, uint256 _businessFee) external onlyOwner {
		transferFee = _transferFee;
		businessFee = _businessFee;
		
		require(transferFee + businessFee <= 200, "Must keep fees at 20% or less");
	}
	
	function excludeFromMaxTransaction(address updAds, bool isEx) public onlyOwner {
		_isExcludedMaxTransactionAmount[updAds] = isEx;
	}
	
	// only use to disable contract sales if absolutely necessary (emergency use only)
	function updateSwapEnabled(bool enabled) external onlyOwner() {
		swapEnabled = enabled;
	}
	
	function excludeFromFees(address account, bool excluded) public onlyOwner {
		_isExcludedFromFees[account] = excluded;
		
		emit ExcludeFromFees(account, excluded);
	}
	
	function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
		require(pair != uniswapV2Pair, "The Uniswap pair cannot be removed from automatedMarketMakerPairs");
		
		_setAutomatedMarketMakerPair(pair, value);
	}
	
	function _setAutomatedMarketMakerPair(address pair, bool value) private {
		automatedMarketMakerPairs[pair] = value;
		excludeFromMaxTransaction(pair, value);
		emit SetAutomatedMarketMakerPair(pair, value);
	}
	
	function updateFeeWallet(address newFeeWallet) external onlyOwner {
		excludeFromFees(newFeeWallet, true);
		feeWallet = newFeeWallet;
	}
	
	function updateUSDTWallet(address _udstTokenAddr) external onlyOwner {
		ERC20 _usdtToken = ERC20(_udstTokenAddr);
		usdtTokenAddr = _usdtToken;
	}
	
	function isExcludedFromFees(address account) public view returns (bool) {
		return _isExcludedFromFees[account];
	}
	
	function _transfer(
		address from,
		address to,
		uint256 amount
	) internal override {
		require(from != address(0), "ERC20: transfer from the zero address");
		require(to != address(0), "ERC20: transfer to the zero address");
		
		if (amount == 0) {
			super._transfer(from, to, 0);
			return;
		}
		
		if (!tradingActive) {
			require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active.");
		}
		
		if (limitsInEffect) {
			if (
				from != owner() &&
				to != owner() &&
				to != address(0) &&
				to != address(0xdead) &&
				!swapping
			) {
				
				//when buy
				if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
					require(amount <= maxTransactionAmount, "Buy transfer amount exceeds the maxTransactionAmount.");
				}
				//when sell
				else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
					require(amount <= maxTransactionAmount, "Sell transfer amount exceeds the maxTransactionAmount.");
				}
			}
		}
		
		uint256 contractTokenBalance = balanceOf(address(this));
		
		bool canSwap = contractTokenBalance >= swapTokensAtAmount;
		
		if (
			canSwap &&
			swapEnabled &&
			!swapping &&
			!automatedMarketMakerPairs[from] &&
			!_isExcludedFromFees[from] &&
			!_isExcludedFromFees[to]
		) {
			swapping = true;
			swapBack();
			swapping = false;
		}
		
		bool takeFee = !swapping;
		
		// if any account belongs to _isExcludedFromFee account then remove the fee
		if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
			takeFee = false;
		}
		
		// only take fees on buys/sells, do not take on wallet transfers
		if (takeFee) {
			uint256 fees;
			//buy
			if (automatedMarketMakerPairs[from] || automatedMarketMakerPairs[to]) {
				fees = amount.mul(businessFee).div(feeDivisor);
				_feeTokensToSwap += fees;
			} else {
				fees = amount.mul(transferFee).div(feeDivisor);
				_feeTokensToSwap += fees;
			}
			
			if (fees > 0) {
				amount = amount.sub(fees);
				super._transfer(from, address(this), fees);
			}
		}
		
		super._transfer(from, to, amount);
	}
	
	function swapTokensForUSDT(uint256 tokenAmount) private {
		
		// generate the uniswap pair path of token -> usdt
		address[] memory path = new address[](3);
		path[0] = address(this);
		path[1] = uniswapV2Router.WETH();
		path[2] = address(usdtTokenAddr);
		
		_approve(address(this), address(uniswapV2Router), tokenAmount);
		
		// make the swap
		uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
			tokenAmount,
			0, // accept any amount of usdt
			path,
			address(this),
			block.timestamp
		);
		
	}
	
	function setRouterVersion(address _router) public onlyOwner {
		IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);
		
		uniswapV2Router = _uniswapV2Router;
		// Set the router of the contract variables
		uniswapV2Router = _uniswapV2Router;
		excludeFromMaxTransaction(address(_uniswapV2Router), true);
	}
	
	function swapBack() private {
		uint256 contractBalance = balanceOf(address(this));
		uint256 usdtPreBalance = usdtTokenAddr.balanceOf(address(this));
		
		swapTokensForUSDT(contractBalance);
		
		uint256 usdtBalance = usdtTokenAddr.balanceOf(address(this));
		uint256 swapBalance = usdtBalance.sub(usdtPreBalance);
		
		usdtTokenAddr.transfer(feeWallet, usdtBalance);
		
		emit Swap(contractBalance, swapBalance);
	}
	
	// withdraw USDT if stuck before launch
	function withdrawStuckUSDT() external onlyOwner {
		require(!tradingActive, "Can only withdraw if trading hasn't started");
		uint256 usdtBalance = usdtTokenAddr.balanceOf(address(this));
		usdtTokenAddr.transfer(feeWallet, usdtBalance);
	}
}