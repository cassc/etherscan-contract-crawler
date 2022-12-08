// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IDividendDistributor.sol";

contract SmarterWorx is ERC20, Pausable, Ownable {
	using SafeMath for uint256;
    address public treasury;
	address public marketing;
	address public distributorAddress;
	
    bool private swapping;
	bool public swapEnable;
	bool public distributionEnabled;
	
	uint256 public swapTokensAtAmount;
	uint256 public distributorGas;
	
	uint256[] public liqudityFee;
	uint256[] public marketingFee;
	uint256[] public treasuryFee;
	uint256[] public burnFee;
	
	uint256 private liqudityFeeTotal;
	uint256 private marketingFeeTotal;
	uint256 private treasuryFeeTotal;
	
	IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
	DividendDistributor distributor;
	
    mapping(address => bool) public whitelistedAddress;
	mapping(address => bool) public automatedMarketMakerPairs;
	mapping (address => bool) isDividendExempt;

    event TreasuryAddressUpdated(address newTreasury);
	event MarketingAddressUpdated(address newMarketing);
    event WhitelistAddressUpdated(address whitelistAccount, bool value);
    event TaxUpdated(uint256 taxAmount);
	event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
	event ExcludeFromMaxWalletToken(address indexed account, bool isExcluded);
	event SwapTokenAmountUpdated(uint256 indexed amount);
	event MaxWalletAmountUpdated(uint256 indexed amount);
	event SwapStatusUpdated(bool indexed status);
	
    constructor() ERC20("SmarterWorx", "ARTX"){
	
        _mint(msg.sender, 1000000000  * (10**18));
		
		IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
		
		distributor = new DividendDistributor();
		distributorAddress = address(distributor);

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair   = _uniswapV2Pair;
		
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

		whitelistedAddress[address(this)] = true;
		whitelistedAddress[owner()] = true;
		
		isDividendExempt[_uniswapV2Pair] = true;
        isDividendExempt[address(this)] = true;
       
	    burnFee.push(100);
		burnFee.push(100);
		burnFee.push(0);
		
		marketingFee.push(100);
		marketingFee.push(200);
		marketingFee.push(0);
		
		treasuryFee.push(200);
		treasuryFee.push(400);
		treasuryFee.push(0);
		
		liqudityFee.push(200);
		liqudityFee.push(300);
		liqudityFee.push(0);
		
		swapEnable = true;
		distributionEnabled = false;
		
		swapTokensAtAmount = 10000 * (10**18);
		distributorGas = 250000;
    }
	
	receive() external payable {}

	function _mint(address to, uint256 amount) internal override(ERC20) {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount) internal override(ERC20) {
        super._burn(account, amount);
    }
	
    function _afterTokenTransfer(address from, address to, uint256 amount) internal override(ERC20){
        super._afterTokenTransfer(from, to, amount);
    }
	
	function _beforeTokenTransfer(address from, address to, uint256 amount) internal whenNotPaused override {
        super._beforeTokenTransfer(from, to, amount);
    }
	
    function setTreasuryAddress(address _treasury) external onlyOwner{
        require(_treasury != address(0), "setTreasuryAddress: Zero address");
        treasury = _treasury;
        whitelistedAddress[_treasury] = true;
        emit TreasuryAddressUpdated(_treasury);
    }
	
	function setMarketingAddress(address _marketing) external onlyOwner{
        require(_marketing != address(0), "setMarketingAddress: Zero address");
        marketing = _marketing;
        whitelistedAddress[_marketing] = true;
        emit MarketingAddressUpdated(_marketing);
    }

    function setWhitelistAddress(address _whitelist, bool _status) external onlyOwner{
        require(_whitelist != address(0), "setWhitelistAddress: Zero address");
        whitelistedAddress[_whitelist] = _status;
        emit WhitelistAddressUpdated(_whitelist, _status);
    }
	
	function setSwapTokensAtAmount(uint256 amount) external onlyOwner {
  	     require(amount <= totalSupply(), "Amount cannot be over the total supply.");
		 swapTokensAtAmount = amount;
		 
		 emit SwapTokenAmountUpdated(amount);
  	}
	
	function setSwapEnable(bool _enabled) public onlyOwner {
        swapEnable = _enabled;
	    emit SwapStatusUpdated(_enabled);
    }
	
	function setLiqudityFee(uint256 buy, uint256 sell, uint256 p2p) external onlyOwner {
	    require(burnFee[0].add(marketingFee[0]).add(treasuryFee[0]).add(buy)  <= 1500 , "Max fee limit reached for 'BUY'");
		require(burnFee[1].add(marketingFee[1]).add(treasuryFee[0]).add(sell) <= 1500 , "Max fee limit reached for 'SELL'");
		require(burnFee[2].add(marketingFee[2]).add(treasuryFee[0]).add(p2p)  <= 1500 , "Max fee limit reached for 'P2P'");
		
		liqudityFee[0] = buy;
		liqudityFee[1] = sell;
		liqudityFee[2] = p2p;
	}
	
	function setBurnFee(uint256 buy, uint256 sell, uint256 p2p) external onlyOwner {
	    require(liqudityFee[0].add(marketingFee[0]).add(treasuryFee[0]).add(buy)  <= 1500 , "Max fee limit reached for 'BUY'");
		require(liqudityFee[1].add(marketingFee[1]).add(treasuryFee[1]).add(sell) <= 1500 , "Max fee limit reached for 'SELL'");
		require(liqudityFee[2].add(marketingFee[2]).add(treasuryFee[2]).add(p2p)  <= 1500 , "Max fee limit reached for 'P2P'");
		
		burnFee[0] = buy;
		burnFee[1] = sell;
		burnFee[2] = p2p;
	}
	
	function setMarketingFee(uint256 buy, uint256 sell, uint256 p2p) external onlyOwner {
	    require(liqudityFee[0].add(treasuryFee[0]).add(burnFee[0]).add(buy)  <= 1500 , "Max fee limit reached for 'BUY'");
		require(liqudityFee[1].add(treasuryFee[1]).add(burnFee[1]).add(sell) <= 1500 , "Max fee limit reached for 'SELL'");
		require(liqudityFee[2].add(treasuryFee[2]).add(burnFee[2]).add(p2p)  <= 1500 , "Max fee limit reached for 'P2P'");
		
		marketingFee[0] = buy;
		marketingFee[1] = sell;
		marketingFee[2] = p2p;
	}
	
	function setTreasuryFee(uint256 buy, uint256 sell, uint256 p2p) external onlyOwner {
	    require(liqudityFee[0].add(marketingFee[0]).add(burnFee[0]).add(buy)  <= 1500 , "Max fee limit reached for 'BUY'");
		require(liqudityFee[1].add(marketingFee[1]).add(burnFee[1]).add(sell) <= 1500 , "Max fee limit reached for 'SELL'");
		require(liqudityFee[2].add(marketingFee[2]).add(burnFee[2]).add(p2p)  <= 1500 , "Max fee limit reached for 'P2P'");
		
		treasuryFee[0] = buy;
		treasuryFee[1] = sell;
		treasuryFee[2] = p2p;
	}
	
    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "The Uniswap pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }
	
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
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
	
	function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private{
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0, 
            0,
            address(this),
            block.timestamp.add(300)
        );
    }
	
	function transferTokens(address tokenAddress, address to, uint256 amount) public onlyOwner {
        IERC20(tokenAddress).transfer(to, amount);
    }
	
	function migrateETH(address payable recipient) public onlyOwner {
	    require(recipient != address(0), "Zero address");
        recipient.transfer(address(this).balance);
    }
	
    function _transfer(address sender, address recipient, uint256 amount) internal override(ERC20){      
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
		
		uint256 contractTokenBalance = balanceOf(address(this));
		bool canSwap = contractTokenBalance >= swapTokensAtAmount;
		
		if (!swapping && canSwap && swapEnable && automatedMarketMakerPairs[recipient]) 
		{
		    uint256 tokenToLiqudity  = liqudityFeeTotal.div(2);
			uint256 tokenToMarketing = marketingFeeTotal;
			uint256 tokenToTreasury  = treasuryFeeTotal;
			uint256 tokenToSwap = tokenToLiqudity.add(tokenToMarketing).add(tokenToTreasury);
			
			if(tokenToSwap >= swapTokensAtAmount) 
			{
			    swapping = true;
				swapTokensForETH(swapTokensAtAmount);
				uint256 newBalance = address(this).balance;
				
				uint256 liqudityPart = newBalance.mul(tokenToLiqudity).div(tokenToSwap);
				uint256 marketingPart = newBalance.mul(tokenToMarketing).div(tokenToSwap);
				uint256 treasuryPart = newBalance.sub(liqudityPart).sub(marketingPart);
				
				if(liqudityPart > 0) 
				{
				    uint256 liqudityToken = swapTokensAtAmount.mul(tokenToLiqudity).div(tokenToSwap);
				    addLiquidity(liqudityToken, liqudityPart);
				    liqudityFeeTotal = liqudityFeeTotal.sub(swapTokensAtAmount.mul(tokenToLiqudity).div(tokenToSwap)).sub(liqudityToken);
				}
				
				if(marketingPart > 0) 
				{
				    payable(marketing).transfer(marketingPart);
				    marketingFeeTotal = marketingFeeTotal.sub(swapTokensAtAmount.mul(tokenToMarketing).div(tokenToSwap));
				}
				
				if(treasuryPart > 0) 
				{
				    payable(treasury).transfer(treasuryPart);
				    treasuryFeeTotal  = treasuryFeeTotal.sub(swapTokensAtAmount.mul(tokenToTreasury).div(tokenToSwap));
				}
				
				swapping = false;  
			}
		}
		
		if(whitelistedAddress[sender] || whitelistedAddress[recipient]) 
		{
             super._transfer(sender,recipient,amount);
        }
		else 
		{
		    (uint256 _burnFee, uint256 _treasuryFee, uint256 _marketingFee, uint256 _liqudityFee) = collectFee(amount, automatedMarketMakerPairs[recipient], !automatedMarketMakerPairs[sender] && !automatedMarketMakerPairs[recipient]);
			uint256 allFee = _burnFee + _treasuryFee + _marketingFee + _liqudityFee;
			
			liqudityFeeTotal += _liqudityFee;
			marketingFeeTotal += _marketingFee;
			treasuryFeeTotal += _treasuryFee;
			
			super._burn(sender, _burnFee);
			super._transfer(sender, address(this), _treasuryFee.add(_marketingFee).add(_liqudityFee));
			super._transfer(sender, recipient, amount.sub(allFee));
        }
		
		if(!isDividendExempt[sender]){ try distributor.setShare(sender, balanceOf(sender)) {} catch {} }
        if(!isDividendExempt[recipient]){ try distributor.setShare(recipient, balanceOf(recipient)) {} catch {} }
		
		if(distributionEnabled) {
		   try distributor.process(distributorGas) {} catch {}
		}
    }

	function collectFee(uint256 amount, bool sell, bool p2p) private view returns (uint256, uint256, uint256, uint256) {
        uint256 _burnFee = amount.mul(p2p ? burnFee[2] : sell ? burnFee[1] : burnFee[0]).div(10000);
		uint256 _treasuryFee = amount.mul(p2p ? treasuryFee[2] : sell ? treasuryFee[1] : treasuryFee[0]).div(10000);
		uint256 _marketingFee = amount.mul(p2p ? marketingFee[2] : sell ? marketingFee[1] : marketingFee[0]).div(10000);
		uint256 _liqudityFee = amount.mul(p2p ? liqudityFee[2] : sell ? liqudityFee[1] : liqudityFee[0]).div(10000);
		
        return (_burnFee, _treasuryFee, _marketingFee, _liqudityFee);
    }
	
	function setDistributionStatus(bool status) external onlyOwner {
        distributionEnabled = status;
    }
	
	function setDistributionCriteria(uint256 minPeriod, uint256 minDistribution) external onlyOwner {
        distributor.setDistributionCriteria(minPeriod, minDistribution);
    }
	
	function setDistributorGas(uint256 gas) external onlyOwner {
        require(gas < 750000, "Gas is greater than limit");
        distributorGas = gas;
    }
	
	function depositDropToken(uint256 amount) public{
	   require(balanceOf(msg.sender) >= amount, "Balance not found on sender address");
	   
	   super._transfer(msg.sender, distributorAddress, amount);
	   distributor.deposit(amount);
    }
	
	function setIsDividendExempt(address holder, bool exempt) external onlyOwner {
        isDividendExempt[holder] = exempt;
        if(exempt)
		{
            distributor.setShare(holder, 0);
        }
		else
		{
            distributor.setShare(holder, balanceOf(holder));
        }
    }
	
	function pause() public onlyOwner {
        _pause();
    }
	
    function unpause() public onlyOwner {
        _unpause();
    }
	
	function resetFeeTotal() public onlyOwner {
	   liqudityFeeTotal = 0;
	   marketingFeeTotal = 0;
	   treasuryFeeTotal = 0;
	}
}