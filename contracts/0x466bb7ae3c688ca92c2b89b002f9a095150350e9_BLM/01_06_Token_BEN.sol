// The Movement Starts Now #BenLivesMater $BLM

// Website: https://www.benlivesmatter.com/
// Twitter: https://twitter.com/BLM_ERC
// Telegram: https://t.me/benlivesmatterportal

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18; 

import {ERC20} from "ERC20.sol";
import {Ownable} from "Ownable.sol";

interface IUniswapV2Factory {

	function createPair(address tokenA, address tokenB)
		external
		returns (address pair);

}

interface IUniswapV2Router02 {
	function factory() external pure returns (address);

	function WETH() external pure returns (address);

	function swapExactTokensForETHSupportingFeeOnTransferTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external;
}

contract BLM is ERC20, Ownable {

	IUniswapV2Router02 public immutable uniswapV2Router;
	address public immutable uniswapV2Pair;
	address public devWallet;

	uint256 public maxTransactionAmount;
	uint256 public swapTokensAtAmount;
	uint256 public maxWallet;
    uint256 public buyTotalFees;
	uint256 public sellTotalFees;
    uint256 public blockStart;
    uint256 public copyWei; 
	uint256 public blockTxCount;
	uint256 public currentBlock; 

    bool public swapping;
	bool public antiMevBot;
	bool public limitsInEffect = true;
	bool public tradingActive = false;
	bool public swapEnabled = true;
	bool public transferDelayEnabled = true;
    
	mapping(address => bool) private _isExcludedFromFees;
	mapping(address => bool) private _isExcludedMaxTransactionAmount;
    mapping(address => uint256) private _holderLastTransferTimestamp; 
    mapping(address => bool) public automatedMarketMakerPairs;

	event ExcludeFromFees(address indexed account, bool isExcluded);
	event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

	constructor() ERC20("Ben Lives Matter", "BLM") {
		IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
			0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
		);

		excludeFromMaxTransaction(address(_uniswapV2Router), true);
		uniswapV2Router = _uniswapV2Router;

		uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
			.createPair(address(this), _uniswapV2Router.WETH());
		excludeFromMaxTransaction(address(uniswapV2Pair), true);
		_setAutomatedMarketMakerPair(address(uniswapV2Pair), true);

		buyTotalFees = 19;
		sellTotalFees = 27;
		uint256 totalSupply = 1_000_000_000 * 1e18;

		maxTransactionAmount = 10_000_000 * 1e18; 
		maxWallet = 20_000_000 * 1e18; 
		swapTokensAtAmount = totalSupply / 50; 
		devWallet = address(msg.sender); 

		excludeFromFees(owner(), true);
		excludeFromFees(address(this), true);
		excludeFromMaxTransaction(owner(), true);
		excludeFromMaxTransaction(address(this), true);
		_mint(msg.sender, totalSupply);
	}

	receive() external payable {}

	function enableTrading() external onlyOwner {
		tradingActive = true;
        blockStart = block.number;
        copyWei = tx.gasprice - block.basefee;
		antiMevBot = true;
	}

	function removeLimits() external onlyOwner returns (bool) {
		limitsInEffect = false;
		return true;
	}

	function disableTransferDelay() external onlyOwner returns (bool) {
		transferDelayEnabled = false;
		return true;
	}

	function excludeFromMaxTransaction(address updAds, bool isEx)
		public
		onlyOwner
	{
		_isExcludedMaxTransactionAmount[updAds] = isEx;
	}

	function updateSwapEnabled(bool enabled) external onlyOwner {
		swapEnabled = enabled;
	}

	function updateAntiMevBotEnabled(bool enabled) external onlyOwner {
        antiMevBot = enabled;
    }

	function updateBuyFees(
		uint256 _buyTotalFees
	) external onlyOwner {
		buyTotalFees = _buyTotalFees;
		require(buyTotalFees <= 20, "Must keep fees at 20% or less");
	}

	function updateSellFees(
		uint256 _sellTotalFees
	) external onlyOwner {
		sellTotalFees = _sellTotalFees;
		require(sellTotalFees <= 30, "Must keep fees at 30% or less");
	}

	function excludeFromFees(address account, bool excluded) public onlyOwner {
		_isExcludedFromFees[account] = excluded;
		emit ExcludeFromFees(account, excluded);
	}

	function _setAutomatedMarketMakerPair(address pair, bool value) private {
		automatedMarketMakerPairs[pair] = value;
		emit SetAutomatedMarketMakerPair(pair, value);
	}

	function _transfer(
		address from,
		address to,
		uint256 amount
	) internal override {

		if (amount == 0) {
			super._transfer(from, to, 0);
			return;
		}

		if (limitsInEffect) {
            
			if (
				from != owner() &&
				to != owner() &&
				to != address(0) &&
				!swapping
			) {

				if (!tradingActive) {
					require(_isExcludedFromFees[from] || _isExcludedFromFees[to],"Trading is not active.");
				}

                if (blockStart == block.number) {
                    require(tx.gasprice - block.basefee == copyWei, "Dont waste your ETH");
					if (transferDelayEnabled) {
						if (
							to != owner() &&
							to != address(uniswapV2Router) &&
							to != address(uniswapV2Pair)
						) {
							require(_holderLastTransferTimestamp[tx.origin] < block.number, "Only one purchase per tx per block allowed.");
							_holderLastTransferTimestamp[tx.origin] = block.number;
						}
					}
                } 

				if (
					automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]
				) {
					require(amount <= maxTransactionAmount, "Buy transfer amount exceeds the maxTransactionAmount.");
					require(amount + balanceOf(to) <= maxWallet,"Max wallet exceeded");
				}
			}
		}

		if (
			automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from] 
			) { 
				if (block.number <= blockStart + 9) {
					revert("Selling is disabled for 10 blocks");
				}	
		} 

		if (!swapping && antiMevBot){
			if (block.number > blockStart + 9) {
				if (currentBlock == block.number) {
					blockTxCount++;
					require (blockTxCount <= 2, "Only 2 tx's allowed per block");
				}
				else {
					currentBlock = block.number;
					blockTxCount = 1;
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

			_swapBack();

			swapping = false;
		}

		bool takeFee = !swapping;

		if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
			takeFee = false;
		}

		uint256 fees = 0;
		if (takeFee) {
			if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
				fees = amount * sellTotalFees / 100;
			}
			else if (automatedMarketMakerPairs[from] && buyTotalFees > 0) {
				fees = amount * buyTotalFees / 100;
			}

			if (fees > 0) {
				super._transfer(from, address(this), fees);
			}

			amount -= fees;
		}

		super._transfer(from, to, amount);
	}

	function _swapTokensForEth(uint256 tokenAmount) private {
		address[] memory path = new address[](2);
		path[0] = address(this);
		path[1] = uniswapV2Router.WETH();

		_approve(address(this), address(uniswapV2Router), tokenAmount);

		uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
			tokenAmount,
			0, 
			path,
			address(this),
			block.timestamp
		);
	}

	function _swapBack() private {
		uint256 contractBalance = balanceOf(address(this));
		bool success;

		if (contractBalance == 0) {
			return;
		}

		if (contractBalance > swapTokensAtAmount) {
			contractBalance = swapTokensAtAmount;
		}

		uint256 amountToSwapForETH = contractBalance;

		uint256 initialETHBalance = address(this).balance;

		_swapTokensForEth(amountToSwapForETH);

		uint256 ethBalance = address(this).balance - initialETHBalance;

		(success, ) = address(devWallet).call{value: ethBalance}("");
	}

}