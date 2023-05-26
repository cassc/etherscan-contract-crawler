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

contract BasedBezos is ERC20, Ownable {

	uint256[] public marketingFee;
	uint256[] public shareList;
	address[] public marketingWallet;
	
	uint256 public maxTokenPerWallet;
	uint256 public maxTokenPerTxn;
	uint256 public swapTokensAtAmount;
	
	IUniswapV2Router public uniswapV2Router;
    address public uniswapV2Pair;
	
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
	event MarketingFeeUpdated(uint256 buy, uint256 sell, uint256 p2p);
	event MarketingWalletUpdated(address walletOne, address walletTwo, address walletThree);
	event WalletShareUpdated(uint256 walletOneShare, uint256 walletTwoShare, uint256 walletThreeShare);
	
	constructor(address owner) ERC20("Based Bezos", "$BEZOS") {
	
	   uniswapV2Router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
       uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
	   
	   marketingFee.push(1000);
	   marketingFee.push(2000);
	   marketingFee.push(0);
	   
	   shareList.push(3333);
	   shareList.push(3333);
	   shareList.push(3333);
	   
	   marketingWallet.push(0x0A7B3C8e4Ac2bdDC2941f6A6c105a9BA2BFbfAd8);
	   marketingWallet.push(0x77c7bA1124994Fb02E4bd874F17289A24C8f29a7);
	   marketingWallet.push(0x7e924F7475FED8dC45D11446F61B9f9A274676a7);
	   
	   isExcludedFromFee[owner] = true;
       isExcludedFromFee[address(this)] = true;
	   
	   isExcludedFromMaxTokenPerWallet[owner] = true;
       isExcludedFromMaxTokenPerWallet[address(this)] = true;
	   isExcludedFromMaxTokenPerWallet[address(uniswapV2Pair)] = true;
	   
	   isAutomatedMarketMakerPairs[address(uniswapV2Pair)] = true;   
	   
	   maxTokenPerWallet = 2760000 * (10**18);
	   maxTokenPerTxn = 2760000 * (10**18);
	   swapTokensAtAmount = 13800 * (10**18);
	   
	   swapAndLiquifyEnabled = true;
	   _mint(owner, 69000000 * (10**18));
	   _transferOwnership(owner);
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
	
	function setMarketingWallet(address walletOne, address walletTwo, address walletThree) external onlyOwner{
	   require(walletOne != address(0), "Zero address");
	   require(walletTwo != address(0), "Zero address");
	   require(walletThree != address(0), "Zero address");
	   
	   marketingWallet[0] = walletOne;
	   marketingWallet[1] = walletTwo;
	   marketingWallet[2] = walletThree;
	   emit MarketingWalletUpdated(walletOne, walletTwo, walletThree);
    }
	
	function updateWalletShare(uint256 walletOneShare, uint256 walletTwoShare, uint256 walletThreeShare) external onlyOwner {
		require(walletOneShare + walletTwoShare + walletThreeShare == 9999, "Incorrect values");
		
		shareList[0] = walletOneShare;
		shareList[1] = walletTwoShare;
		shareList[2] = walletThreeShare;
		emit WalletShareUpdated(walletOneShare, walletTwoShare, walletTwoShare);
	}
	
	function setMaxTokenPerWallet(uint256 amount) external onlyOwner {
		require(amount <= totalSupply(), "Amount cannot be over the total supply.");
		require(amount >= 500 * (10**18), "Minimum `500` token per wallet required");
		
		maxTokenPerWallet = amount;
		emit MaxTokenPerWalletUpdated(amount);
	}
	
	function setMaxTokenPerTxn(uint256 amount) external onlyOwner {
		require(amount <= totalSupply(), "Amount cannot be over the total supply.");
		require(amount >= 500 * (10**18), "Minimum `500` token per txn required");
		
		maxTokenPerTxn = amount;
		emit MaxTokenPerTxnUpdated(amount);
	}
	
	function setSwapTokensAtAmount(uint256 amount) external onlyOwner {
  	    require(amount <= totalSupply(), "Amount cannot be over the total supply.");
		require(amount >= 100 * (10**18), "Minimum `100` token per swap required");
		
		swapTokensAtAmount = amount;
		emit SwapTokensAmountUpdated(amount);
  	}
	
	function setMarketingFee(uint256 buy, uint256 sell, uint256 p2p) external onlyOwner {
	    require(buy  <= 2000 , "Max fee limit reached for 'BUY'");
		require(sell <= 2000 , "Max fee limit reached for 'SELL'");
		require(p2p  <= 2000 , "Max fee limit reached for 'P2P'");
		
		marketingFee[0] = buy;
		marketingFee[1] = sell;
		marketingFee[2] = p2p;
		
		emit MarketingFeeUpdated(buy, sell, p2p);
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
		
		uint256 contractTokenBalance = balanceOf(address(this));
		bool canSwap = contractTokenBalance >= swapTokensAtAmount;
		
		if (canSwap && !swapping && isAutomatedMarketMakerPairs[recipient] && swapAndLiquifyEnabled) 
		{
			swapping = true;
			swapTokensForETH(swapTokensAtAmount);
			uint256 ethBalance = address(this).balance;
			
			for (uint256 i = 0; i < marketingWallet.length; i++) 
			{
			   uint256 payableETH = ethBalance * shareList[i] / 10000;
			   if(payableETH > 0 )
			   {
			       payable(marketingWallet[i]).transfer(payableETH);
			   }
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
			if(!isExcludedFromMaxTokenPerWallet[recipient])
		    {
		       require((balanceOf(recipient) + amount - allFee) <= maxTokenPerWallet, "Transfer amount exceeds the `maxTokenPerWallet`.");   
		    }
			if(allFee > 0) 
			{
			   super._transfer(sender, address(this), allFee);
			}
			super._transfer(sender, recipient, amount - allFee);
        }
    }
	
	function collectFee(uint256 amount, bool sell, bool p2p) private view returns (uint256) {
        uint256 newMarketingFee = amount * (p2p ? marketingFee[2] : sell ? marketingFee[1] : marketingFee[0]) / 10000;
        return  newMarketingFee;
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
	
	function migrateETH(address payable recipient) external onlyOwner {
	   require(recipient != address(0), "Zero address");
       recipient.transfer(address(this).balance);
    }
	
	function migrateToken(address token, address recipient, uint256 amount) external onlyOwner {
       require(recipient != address(0), "Zero address");
	   IERC20(token).transfer(recipient, amount);
    }
}