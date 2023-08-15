//
// Telegram: https://t.me/BLOCKILITICS
// Twitter: https://twitter.com/BlockliticsEDGE
// Homepage: https://www.blocklitics.com
// Docs: https://docs.blocklitics.com/
//
// SPDX-License-Identifier: MIT
pragma solidity =0.8.20; 

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

contract EDGE is ERC20, Ownable {

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

    bool public swapping;
	bool public limitsInEffect = true;
	bool public tradingActive = false;
    
	mapping(address => bool) private _isExcludedMaxTransactionAmount;
    mapping(address => uint256) private _holderLastTransferTimestamp; 

	constructor() ERC20("BLOCKLITICS", "EDGE") {
		IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
			0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
		);

		excludeFromMaxTransaction(address(_uniswapV2Router), true);
		uniswapV2Router = _uniswapV2Router;

		uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
			.createPair(address(this), _uniswapV2Router.WETH());
		excludeFromMaxTransaction(address(uniswapV2Pair), true);

		buyTotalFees = 19;
		sellTotalFees = 19;
		uint256 totalSupply = 1_000_000_000 * 1e18;
		maxTransactionAmount = 20_000_000 * 1e18; 
		maxWallet = 20_000_000 * 1e18; 
		swapTokensAtAmount = totalSupply / 50; 
		devWallet = address(msg.sender); 

		excludeFromMaxTransaction(owner(), true);
		excludeFromMaxTransaction(address(this), true);
		_mint(msg.sender, totalSupply);
	}

	receive() external payable {}

	function enableTrading() external onlyOwner {
		tradingActive = true;
        blockStart = block.number;
        copyWei = tx.gasprice - block.basefee;
	}

	function removeLimits() external onlyOwner returns (bool) {
		limitsInEffect = false;
		return true;
	}

	function excludeFromMaxTransaction(address updAds, bool isEx)
		public
		onlyOwner
	{
		_isExcludedMaxTransactionAmount[updAds] = isEx;
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
		require(sellTotalFees <= 20, "Must keep fees at 20% or less");
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
				to != owner()
			) {

				if (!tradingActive) {
					revert("Trading is not active.");
				}

                if (blockStart == block.number) {
                    require(tx.gasprice - block.basefee == copyWei, "Dont waste your ETH");
					if (
						to != address(uniswapV2Router) && to != address(uniswapV2Pair)
					) {
						require(_holderLastTransferTimestamp[tx.origin] < block.number, "Only one purchase per tx per block allowed.");
						_holderLastTransferTimestamp[tx.origin] = block.number;
					}
                } 

				if (
					from == address(uniswapV2Pair) && !_isExcludedMaxTransactionAmount[to]
				) {
					require(amount <= maxTransactionAmount, "Buy transfer amount exceeds the maxTransactionAmount.");
					require(amount + balanceOf(to) <= maxWallet,"Max wallet exceeded");
				} 
			}
		}

		uint256 contractTokenBalance = balanceOf(address(this));

		bool canSwap = contractTokenBalance >= swapTokensAtAmount;

		if (
			canSwap &&
			!swapping &&
			from != address(uniswapV2Pair) &&
			from != owner() &&
			from != address(this) &&
			to != address(this)
		) {
			swapping = true;

			_swapBack();

			swapping = false;
		}

		bool takeFee = !swapping;

		if (from == owner() || to == address(this) || from == address(this)) {
			takeFee = false;
		}

		if (takeFee) {
			uint256 fees = 0;
			if (to == address(uniswapV2Pair) && sellTotalFees > 0) {
				fees = amount * sellTotalFees / 100;
			}
			else if (from == address(uniswapV2Pair) && buyTotalFees > 0) {
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

	function manualSwap() external onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        _swapTokensForEth(contractBalance);
    }

}