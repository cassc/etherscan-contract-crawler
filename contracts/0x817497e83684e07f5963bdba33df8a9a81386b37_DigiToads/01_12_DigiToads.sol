// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IUniswapV2Factory.sol";
import "./airdropDistributor.sol";

interface IStaking {
   function updatePool(uint256 amount) external;
}

contract DigiToads is ERC20, Ownable {
    using SafeMath for uint256;
	
	address public treasury;
	address public staking;
	address public distributorAddress;
	
    bool private swapping;
	bool public swapEnable;
	bool public distributionEnabled;
	
	uint256 public swapTokensAtAmount;
	uint256 public distributorGas;
	IERC20 USDT;
	
	uint256[] public liqudityFee;
	uint256[] public stakingPoolFee;
	uint256[] public treasuryFee;
	uint256[] public burnFee;
	
	IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
	AirDrop distributor;
	
	mapping(address => bool) isDividendExempt;
    mapping(address => bool) public whitelistedAddress;
	mapping(address => bool) public automatedMarketMakerPairs;

    event TreasuryAddressUpdated(address newTreasury);
	event StakingAddressUpdated(address newStaking);
    event WhitelistAddressUpdated(address whitelistAccount, bool value);
	event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
	event ExcludeFromMaxWalletToken(address indexed account, bool isExcluded);
	event SwapTokenAmountUpdated(uint256 indexed amount);
	event SwapStatusUpdated(bool indexed status);
	
    constructor(address _owner) ERC20("DigiToads", "$TOADS") {
	
        _mint(_owner, 585000000 * (10**18));
		
		IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair   = _uniswapV2Pair;
		
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

		whitelistedAddress[address(this)] = true;
		whitelistedAddress[_owner] = true;
		
		isDividendExempt[_uniswapV2Pair] = true;
        isDividendExempt[address(this)] = true;
       
	    burnFee.push(200);
		burnFee.push(200);
		burnFee.push(200);
		
		treasuryFee.push(200);
		treasuryFee.push(200);
		treasuryFee.push(200);
		
		stakingPoolFee.push(200);
		stakingPoolFee.push(200);
		stakingPoolFee.push(200);
		
		liqudityFee.push(100);
		liqudityFee.push(100);
		liqudityFee.push(100);
		
		swapEnable = true;
		swapTokensAtAmount = 100000 * (10**18);
		distributorGas = 250000;
		
		distributor = new AirDrop();
		distributorAddress = address(distributor);
		USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
		treasury = address(0x860cEE971686c6b349C13ddde2fDe483aD955418);
    }
	
	receive() external payable {}
	
    function setTreasuryAddress(address _treasury) external onlyOwner{
        require(_treasury != address(0), "setTreasuryAddress: Zero address");
		
        treasury = _treasury;
        whitelistedAddress[_treasury] = true;
        emit TreasuryAddressUpdated(_treasury);
    }
	
	function setStakingPoolAddress(address _staking) external onlyOwner{
        require(_staking != address(0), "setStakingPoolAddress: Zero address");
		
        staking = _staking;
        whitelistedAddress[_staking] = true;
        emit StakingAddressUpdated(_staking);
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
	    require(burnFee[0].add(stakingPoolFee[0]).add(treasuryFee[0]).add(buy)  <= 2500 , "Max fee limit reached for 'BUY'");
		require(burnFee[1].add(stakingPoolFee[1]).add(treasuryFee[0]).add(sell) <= 2500 , "Max fee limit reached for 'SELL'");
		require(burnFee[2].add(stakingPoolFee[2]).add(treasuryFee[0]).add(p2p)  <= 2500 , "Max fee limit reached for 'P2P'");
		
		liqudityFee[0] = buy;
		liqudityFee[1] = sell;
		liqudityFee[2] = p2p;
	}
	
	function setBurnFee(uint256 buy, uint256 sell, uint256 p2p) external onlyOwner {
	    require(liqudityFee[0].add(stakingPoolFee[0]).add(treasuryFee[0]).add(buy)  <= 2500 , "Max fee limit reached for 'BUY'");
		require(liqudityFee[1].add(stakingPoolFee[1]).add(treasuryFee[1]).add(sell) <= 2500 , "Max fee limit reached for 'SELL'");
		require(liqudityFee[2].add(stakingPoolFee[2]).add(treasuryFee[2]).add(p2p)  <= 2500 , "Max fee limit reached for 'P2P'");
		
		burnFee[0] = buy;
		burnFee[1] = sell;
		burnFee[2] = p2p;
	}
	
	function setStakingPoolFee(uint256 buy, uint256 sell, uint256 p2p) external onlyOwner {
	    require(liqudityFee[0].add(treasuryFee[0]).add(burnFee[0]).add(buy)  <= 2500 , "Max fee limit reached for 'BUY'");
		require(liqudityFee[1].add(treasuryFee[1]).add(burnFee[1]).add(sell) <= 2500 , "Max fee limit reached for 'SELL'");
		require(liqudityFee[2].add(treasuryFee[2]).add(burnFee[2]).add(p2p)  <= 2500 , "Max fee limit reached for 'P2P'");
		
		stakingPoolFee[0] = buy;
		stakingPoolFee[1] = sell;
		stakingPoolFee[2] = p2p;
	}
	
	function setTreasuryFee(uint256 buy, uint256 sell, uint256 p2p) external onlyOwner {
	    require(liqudityFee[0].add(stakingPoolFee[0]).add(burnFee[0]).add(buy)  <= 2500 , "Max fee limit reached for 'BUY'");
		require(liqudityFee[1].add(stakingPoolFee[1]).add(burnFee[1]).add(sell) <= 2500 , "Max fee limit reached for 'SELL'");
		require(liqudityFee[2].add(stakingPoolFee[2]).add(burnFee[2]).add(p2p)  <= 2500 , "Max fee limit reached for 'P2P'");
		
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
			swapping = true;
			uint256 half = swapTokensAtAmount.div(2);
			uint256 otherHalf = swapTokensAtAmount.sub(half);
			
			swapTokensForETH(half);
			uint256 newBalance = address(this).balance;
			
			if(newBalance > 0) {
			   addLiquidity(otherHalf, newBalance);
			}
			swapping = false;
		}
		
		if(whitelistedAddress[sender] || whitelistedAddress[recipient]) 
		{
             super._transfer(sender, recipient, amount);
        }
		else 
		{
		    (uint256 burnAmount, uint256 treasuryAmount, uint256 stakingAmount, uint256 liqudityAmount) = collectFee(amount, automatedMarketMakerPairs[recipient], !automatedMarketMakerPairs[sender] && !automatedMarketMakerPairs[recipient]);
			
			if(burnAmount > 0)  
			{
			   super._burn(sender, burnAmount);
			}
			if(treasuryAmount > 0)  
			{
			   super._transfer(sender, address(treasury), treasuryAmount);
			}
			if(stakingAmount > 0)  
			{
			   super._transfer(sender, address(staking), stakingAmount);
			   IStaking(staking).updatePool(stakingAmount);
			}
			if(liqudityAmount > 0)  
			{
			   super._transfer(sender, address(this), liqudityAmount);
			}
			uint256 allFee = burnAmount.add(treasuryAmount).add(stakingAmount).add(liqudityAmount);
			super._transfer(sender, recipient, amount.sub(allFee));
        }
		
		if(!isDividendExempt[sender]){ try distributor.setShare(sender, balanceOf(sender)) {} catch {} }
        if(!isDividendExempt[recipient]){ try distributor.setShare(recipient, balanceOf(recipient)) {} catch {} }
		
		if(distributionEnabled) 
		{
		   try distributor.process(distributorGas) {} catch {}
		}
    }
	
	function collectFee(uint256 amount, bool sell, bool p2p) private view returns (uint256, uint256, uint256, uint256) {
        uint256 _burnFee = amount.mul(p2p ? burnFee[2] : sell ? burnFee[1] : burnFee[0]).div(10000);
		uint256 _treasuryFee = amount.mul(p2p ? treasuryFee[2] : sell ? treasuryFee[1] : treasuryFee[0]).div(10000);
		uint256 _stakingFee = amount.mul(p2p ? stakingPoolFee[2] : sell ? stakingPoolFee[1] : stakingPoolFee[0]).div(10000);
		uint256 _liqudityFee = amount.mul(p2p ? liqudityFee[2] : sell ? liqudityFee[1] : liqudityFee[0]).div(10000);
		
        return (_burnFee, _treasuryFee, _stakingFee, _liqudityFee);
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
	
	function depositAirDropUSDT(uint256 amount) public{
	   require(USDT.balanceOf(msg.sender) >= amount, "USDT balance not found on sender address");
	   
	   USDT.transferFrom(msg.sender, distributorAddress, amount);
	   distributor.depositUSDT(amount);
    }
}