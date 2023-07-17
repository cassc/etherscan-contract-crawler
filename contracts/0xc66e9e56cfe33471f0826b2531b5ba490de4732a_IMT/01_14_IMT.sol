// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IMTRewardToken.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract IMT is ERC20, Ownable {
	using SafeMath for uint256;

	IUniswapV2Router02 public uniswapV2Router;
	address public uniswapV2Pair;

	bool private swapping;
	bool private reinvesting;
	bool private tradingEnabled;

	IMTRewardToken public rewardTracker;
	address payable developmentAddress = payable(0x410a8dA09dB8a550436653F0834E33743F4Cf647);

	uint256 public swapTokensAtAmount = 200000 * (10**18);

	uint256 public rewardFee = 5;
	uint256 public developmentFee = 6;
	uint256 public totalFee = 11;

	// exlcude from fees and max transaction amount
	mapping(address => bool) private _isExcludedFromFees;

	// store addresses that a automatic market maker pairs. Any transfer *to* these addresses
	// could be subject to a maximum transfer amount
	mapping(address => bool) public automatedMarketMakerPairs;

	event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);
	event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
	event ExcludeFromFees(address indexed account, bool isExcluded);
	event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
	event SendDividends(uint256 amount);

	constructor() ERC20("Infinity Mining Token", "IMT") {
		rewardTracker = new IMTRewardToken("IMT Reward Tracker", "rIMT", address(this));
		IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
		// Create a uniswap pair for this new token
		address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

		uniswapV2Router = _uniswapV2Router;
		uniswapV2Pair = _uniswapV2Pair;

		_setAutomatedMarketMakerPair(_uniswapV2Pair, true);

		// exclude from receiving dividends
		rewardTracker.excludeFromDividends(address(rewardTracker));
		rewardTracker.excludeFromDividends(address(this));
		rewardTracker.excludeFromDividends(owner());
		rewardTracker.excludeFromDividends(address(_uniswapV2Router));
		rewardTracker.excludeFromDividends(address(_uniswapV2Pair));
		rewardTracker.transferOwnership(msg.sender);

		// exclude from paying fees or having max transaction amount
		excludeFromFees(address(this), true);
		excludeFromFees(owner(), true);

		_mint(owner(), 5_000_000_000 * (10**18));
	}

	receive() external payable {}

	function setDevelopmentFee(uint256 _developmentFee) external onlyOwner {
		developmentFee = _developmentFee;
	}

	function setRewardFee(uint256 _rewardFee) external onlyOwner {
		rewardFee = _rewardFee;
	}

	function setTotalFee() internal {
		totalFee = rewardFee + developmentFee;
	}

	function setDevelopmentAddress(address payable _developmentAddress) external onlyOwner {
		developmentAddress = _developmentAddress;
	}

	function enableTrading() external onlyOwner {
		tradingEnabled = true;
	}

	function updateDividendTracker(address newAddress) public onlyOwner {
		require(newAddress != address(rewardTracker), "IMT: The dividend tracker already has that address");

		IMTRewardToken newDividendTracker = IMTRewardToken(payable(newAddress));
		emit UpdateDividendTracker(newAddress, address(rewardTracker));
		rewardTracker = newDividendTracker;
	}

	function updateUniswapV2Router(address newAddress) public onlyOwner {
		require(newAddress != address(uniswapV2Router), "IMT: The router already has that address");
		emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
		uniswapV2Router = IUniswapV2Router02(newAddress);
	}

	function excludeFromFees(address account, bool excluded) public onlyOwner {
		require(_isExcludedFromFees[account] != excluded, "IMT: Account is already the value of 'excluded'");
		_isExcludedFromFees[account] = excluded;

		emit ExcludeFromFees(account, excluded);
	}

	function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
		require(pair != uniswapV2Pair, "IMT: The UniSwap pair cannot be removed from automatedMarketMakerPairs");

		_setAutomatedMarketMakerPair(pair, value);
	}

	function _setAutomatedMarketMakerPair(address pair, bool value) private {
		require(automatedMarketMakerPairs[pair] != value, "IMT: Automated market maker pair is already set to that value");
		automatedMarketMakerPairs[pair] = value;
		emit SetAutomatedMarketMakerPair(pair, value);
	}

	function isExcludedFromFees(address account) public view returns (bool) {
		return _isExcludedFromFees[account];
	}

	function reinvestReflections(address account, uint256 minTokens) external payable {
		require(msg.sender == address(rewardTracker), "IMT: Only callable by dividend tracker");
		reinvesting = true;
		swapEthForTokens(msg.value, minTokens, account);
		reinvesting = false;
	}

	function _transfer(
		address from,
		address to,
		uint256 amount
	) internal override {
		require(from != address(0), "ERC20: transfer from the zero address");
		require(to != address(0), "ERC20: transfer to the zero address");

		if (!tradingEnabled) {
			require(from == owner(), "IMT: Cannot transfer before trading enabled");
		}

		if (amount == 0) {
			super._transfer(from, to, 0);
			return;
		}

		if (totalFee > 0) {
			bool isExcluded = _isExcludedFromFees[from] || _isExcludedFromFees[to];
			bool thresholdReached = balanceOf(address(this)) > swapTokensAtAmount;

			bool canSwap = thresholdReached && !swapping && !reinvesting && automatedMarketMakerPairs[to] && !isExcluded;
			if (canSwap) {
				swapping = true;
				swapAndDistribute();
				swapping = false;
			}

			bool takeFee = (!swapping && !reinvesting && !isExcluded) && (automatedMarketMakerPairs[from] || automatedMarketMakerPairs[to]);
			if (takeFee) {
				uint256 fees = amount.mul(totalFee).div(100);
				amount = amount.sub(fees);
				super._transfer(from, address(this), fees);
			}
		}

		super._transfer(from, to, amount);

		try rewardTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
		try rewardTracker.setBalance(payable(to), balanceOf(to)) {} catch {}
	}

	function swapTokensForEth(uint256 tokenAmount) private {
		// generate the uniswap pair path of token -> weth
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = uniswapV2Router.WETH();

		_approve(address(this), address(uniswapV2Router), tokenAmount);

		// make the swap
		uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
			tokenAmount,
			0, // accept any amount of ETH
			path,
			address(this),
			block.timestamp
		);
	}

	function swapEthForTokens(
		uint256 ethAmount,
		uint256 minTokens,
		address account
	) internal returns (uint256) {
		address[] memory path = new address[](2);
		path[0] = uniswapV2Router.WETH();
		path[1] = address(this);

		uint256 balanceBefore = balanceOf(account);

		uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: ethAmount }(minTokens, path, account, block.timestamp);

		uint256 tokenAmount = balanceOf(account).sub(balanceBefore);
		return tokenAmount;
	}

	function swapAndDistribute() private {
		uint256 tokenBalance = balanceOf(address(this));
		swapTokensForEth(tokenBalance);

		uint256 ethBalance = address(this).balance;
		uint256 devPortion = ethBalance.mul(developmentFee).div(totalFee);
		developmentAddress.transfer(devPortion);
		uint256 rewards = address(this).balance;
		(bool success, ) = address(rewardTracker).call{ value: rewards }("");

		if (success) {
			emit SendDividends(rewards);
		}
	}

	function burn(uint256 amount) external {
		_burn(msg.sender, amount);
		rewardTracker.setBalance(payable(msg.sender), balanceOf(msg.sender));
	}
}