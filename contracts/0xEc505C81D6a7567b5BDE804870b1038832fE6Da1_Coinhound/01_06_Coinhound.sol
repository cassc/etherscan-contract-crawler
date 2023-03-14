/**


     Meet Coinhound - A Web 3.0 dApp for a smarter and safer decentralized world
       
     Coinhound is a dApp and your digital companion in the decentralized world of Web 3.0
     that scans, classifies and tracks blockchain data that can help anyone become smarter
     and more educated about blockchain.        
        
     Website: coinhound.io
     Twitter: twitter.com/coinhoundio
     Telegram: t.me/coinhoundportal
     Medium: medium.com/@coinhoundio
     
       
**/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IUniswapV2Factory {
   function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router {
   function factory() external pure returns (address);
   function WETH() external pure returns (address);
   function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
   function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

contract Coinhound is ERC20, Ownable {

	uint256[] public liquidityFee;
	uint256[] public developmentFee;
	
	uint256 public maxTokenPerWallet;
	uint256 public maxTokenPerTxn;
	uint256 public swapTokensAtAmount;
	
	IUniswapV2Router public uniswapV2Router;
    address public uniswapV2Pair;
	address public developmentWallet;
	
	bool private swapping;
    bool public swapAndLiquifyEnabled;
	
	mapping (address => bool) public isExcludedFromFee;
	mapping (address => bool) public isExcludedFromMaxTokenPerWallet;
	mapping (address => bool) public isAutomatedMarketMakerPairs;
	
	event MaxTokenPerWalletUpdated(uint256 amount);
	event MaxTokenPerTxnUpdated(uint256 amount);
	event SwapTokensAmountUpdated(uint256 amount);
	event AutomatedMarketMakerPairUpdated(address pair, bool value);
	event SwapAndLiquifyStatusUpdated(bool status);
	event LiquidityFeeUpdated(uint256 buy, uint256 sell, uint256 p2p);
    event DevelopmentFeeUpdated(uint256 buy, uint256 sell, uint256 p2p);
	event DevelopmentWalletUpdated(address newWallet);
	
	constructor() ERC20("Coinhound", "CND") {
	
	   uniswapV2Router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
       uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
	   
	   liquidityFee.push(100);
	   liquidityFee.push(100);
	   liquidityFee.push(0);
	   
	   developmentFee.push(400);
	   developmentFee.push(400);
	   developmentFee.push(0);
	   
	   isExcludedFromFee[owner()] = true;
       isExcludedFromFee[address(this)] = true;
	   
	   isExcludedFromMaxTokenPerWallet[owner()] = true;
       isExcludedFromMaxTokenPerWallet[address(this)] = true;
	   isExcludedFromMaxTokenPerWallet[address(uniswapV2Pair)] = true;
	   
	   isAutomatedMarketMakerPairs[address(uniswapV2Pair)] = true;   
	   
	   maxTokenPerWallet = 5000000 * (10 ** 18);
	   maxTokenPerTxn = 10000000 * (10 ** 18);
	   swapTokensAtAmount = 100000 * (10 ** 18);
	   
	   developmentWallet = address(0x242397E665c452e2741257c4B765DEC892827c53);
	   swapAndLiquifyEnabled = true;
	   
	   _mint(msg.sender, 1000000000 * (10 ** 18));
    }
	
	receive() external payable {}
	
	function excludeFromFee(address account, bool status) external onlyOwner {
	   require(isExcludedFromFee[account] != status, "Account is already the value of 'status'");
	   isExcludedFromFee[account] = status;
	}
	
	function excludeFromMaxTokenPerWallet(address account, bool status) external onlyOwner {
	   require(isExcludedFromMaxTokenPerWallet[account] != status, "Account is already the value of 'status'");
	   isExcludedFromMaxTokenPerWallet[account] = status;
	}
	
	function setDevelopmentWallet(address newWallet) external onlyOwner{
	   require(newWallet != address(0), "Zero address");
	   
	   developmentWallet = newWallet;
	   emit DevelopmentWalletUpdated(newWallet);
    }
	
	function setMaxTokenPerWallet(uint256 amount) external onlyOwner {
		require(amount <= totalSupply(), "Amount cannot be over the total supply.");
		require(amount >= 500 * (10 ** 18), "Minimum `500` token per wallet required");
		
		maxTokenPerWallet = amount;
		emit MaxTokenPerWalletUpdated(amount);
	}
	
	function setMaxTokenPerTxn(uint256 amount) external onlyOwner {
		require(amount <= totalSupply(), "Amount cannot be over the total supply.");
		require(amount >= 500 * (10 ** 18), "Minimum `500` token per txn required");
		
		maxTokenPerTxn = amount;
		emit MaxTokenPerTxnUpdated(amount);
	}
	
	function setSwapTokensAtAmount(uint256 amount) external onlyOwner {
  	    require(amount <= totalSupply(), "Amount cannot be over the total supply.");
		require(amount >= 500 * (10 ** 18), "Minimum `500` token per swap required");
		
		swapTokensAtAmount = amount;
		emit SwapTokensAmountUpdated(amount);
  	}
	
	function setliquidityFee(uint256 buy, uint256 sell, uint256 p2p) external onlyOwner {
	    require(developmentFee[0] + buy  <= 2000 , "Max fee limit reached for 'BUY'");
		require(developmentFee[1] + sell <= 2000 , "Max fee limit reached for 'SELL'");
		require(developmentFee[2] + p2p  <= 2000 , "Max fee limit reached for 'P2P'");
		
		liquidityFee[0] = buy;
		liquidityFee[1] = sell;
		liquidityFee[2] = p2p;
		
		emit LiquidityFeeUpdated(buy, sell, p2p);
	}
	
	function setDevelopmentFee(uint256 buy, uint256 sell, uint256 p2p) external onlyOwner {
	    require(liquidityFee[0] + buy  <= 2000 , "Max fee limit reached for 'BUY'");
		require(liquidityFee[1] + sell <= 2000 , "Max fee limit reached for 'SELL'");
		require(liquidityFee[2] + p2p  <= 2000 , "Max fee limit reached for 'P2P'");
		
		developmentFee[0] = buy;
		developmentFee[1] = sell;
		developmentFee[2] = p2p;
		
		emit DevelopmentFeeUpdated(buy, sell, p2p);
	}
	
	function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        require(pair != address(0), "Zero address");
		require(isAutomatedMarketMakerPairs[pair] != value, "Automated market maker pair is already set to that value");
        require(pair != address(uniswapV2Pair), "The pair cannot be removed from automatedMarketMakerPairs");
		
		isExcludedFromMaxTokenPerWallet[address(pair)] = value;
		isAutomatedMarketMakerPairs[address(pair)] = value;
		emit AutomatedMarketMakerPairUpdated(pair, value);
    }
	
	function setSwapAndLiquifyEnabled(bool status) external onlyOwner {
		require(swapAndLiquifyEnabled != status, "`swapAndLiquifyEnabled` is already the value of 'status'");
		
		swapAndLiquifyEnabled = status;
		emit SwapAndLiquifyStatusUpdated(status);
    }
	
	function _transfer(address sender, address recipient, uint256 amount) internal override(ERC20){      
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
		
		if(sender != owner() && recipient != owner()) 
		{
		    require(amount <= maxTokenPerTxn, "Transfer amount exceeds the `maxTokenPerTxn`.");   
		}
		
		if(!isExcludedFromMaxTokenPerWallet[recipient] && sender != owner())
		{
		    require((balanceOf(recipient) + amount) <= maxTokenPerWallet, "Transfer amount exceeds the `maxTokenPerWallet`.");   
		}
		
		uint256 contractTokenBalance = balanceOf(address(this));
		bool canSwap = contractTokenBalance >= swapTokensAtAmount;
		
		if (canSwap && !swapping && isAutomatedMarketMakerPairs[recipient] && swapAndLiquifyEnabled) 
		{
			swapping = true;
			
			uint256 fromLiquidityFee = swapTokensAtAmount * liquidityFee[0] / (liquidityFee[0] + developmentFee[0]);
		    uint256 fromdevelopmentFee = swapTokensAtAmount - fromLiquidityFee;
			
			uint256 half = fromLiquidityFee / 2;
		    uint256 otherHalf = fromLiquidityFee - half;
			
			swapTokensForETH(half + fromdevelopmentFee);
			uint256 ethBalance = address(this).balance;
			
			uint256 liquidityPart = ethBalance * liquidityFee[0] / (liquidityFee[0] + developmentFee[0]);
		            liquidityPart = liquidityPart / 2;
			uint256 developmentPart = ethBalance - liquidityPart;
			
			if(liquidityPart > 0)
			{
				addLiquidity(otherHalf, liquidityPart);
			}
			if(developmentPart > 0) 
			{
			    payable(developmentWallet).transfer(developmentPart);
			}
			swapping = false;
        }
		
		if(isExcludedFromFee[sender] || isExcludedFromFee[recipient]) 
		{
            super._transfer(sender, recipient, amount);
        }
		else 
		{
		    uint256 allFee = collectFee(amount, isAutomatedMarketMakerPairs[recipient], !isAutomatedMarketMakerPairs[sender] && !isAutomatedMarketMakerPairs[recipient]);
			if(allFee > 0) 
			{
			   super._transfer(sender, address(this), allFee);
			}
			super._transfer(sender, recipient, amount - allFee);
        }
    }
	
	function collectFee(uint256 amount, bool sell, bool p2p) private view returns (uint256) {
        uint256 newDevelopmentFee = amount * (p2p ? developmentFee[2] : sell ? developmentFee[1] : developmentFee[0]) / 10000;
		uint256 newLiquidityFee = amount * (p2p ? liquidityFee[2] : sell ? liquidityFee[1] : liquidityFee[0]) / 10000;
		
        return (newDevelopmentFee + newLiquidityFee);
    }
	
	function swapTokensForETH(uint256 tokenAmount) private {
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
	
	function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0, 
            0,
            owner(),
            block.timestamp
        );
    }
	
	function migrateETH(address payable recipient) public onlyOwner {
	   require(recipient != address(0), "Zero address");
       recipient.transfer(address(this).balance);
    }
}