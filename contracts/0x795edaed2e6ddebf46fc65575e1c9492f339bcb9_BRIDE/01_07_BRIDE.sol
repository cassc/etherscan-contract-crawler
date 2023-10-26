pragma solidity 0.8.2;

// SPDX-License-Identifier: Unlicensed

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IUniswapV2Factory {
   function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router {
   function factory() external pure returns (address);
   function WETH() external pure returns (address);
}

contract BRIDE is Ownable, ERC20 {
	using SafeMath for uint256;
	
    mapping(address => uint256) public rOwned;
    mapping(address => uint256) public tOwned;
	
    mapping(address => bool) public isExcludedFromFee;
	mapping(address => bool) public isExcludedFromMaxTokenPerWallet;
    mapping(address => bool) public isExcludedFromReward;
	mapping(address => bool) public isAutomatedMarketMakerPairs;
	
    address[] private _excluded;
	address public constant burnWallet = address(0x000000000000000000000000000000000000dEaD);
	
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1_000_000_000_000 * (10**18);
	
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
	
	uint256[] public reflectionFee;
	uint256[] public burnFee;
	
	uint256 public maxTokenPerWallet;
	uint256 public maxTokenPerTxn;
	
	uint256 private _reflectionFee;
	uint256 private _burnFee;
	
    IUniswapV2Router public uniswapV2Router;
    address public uniswapV2Pair;
	
    constructor (address owner) ERC20("Bridecoin", "BRIDE") {
        rOwned[address(owner)] = _rTotal;
		
        uniswapV2Router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
		
		reflectionFee.push(200);
		reflectionFee.push(200);
		reflectionFee.push(200);
		
		burnFee.push(200);
		burnFee.push(200);
		burnFee.push(200);
		
		maxTokenPerWallet = 10_000_000_000 * (10**18);
		maxTokenPerTxn = 10_000_000_000 * (10**18);
		
		_setAutomatedMarketMakerPair(uniswapV2Pair, true);
		
        isExcludedFromFee[address(owner)] = true;
        isExcludedFromFee[address(this)] = true;
		
		isExcludedFromMaxTokenPerWallet[address(uniswapV2Pair)] = true;
		isExcludedFromMaxTokenPerWallet[address(this)] = true;
		isExcludedFromMaxTokenPerWallet[address(owner)] = true;
		
		_excludeFromReward(address(burnWallet));
		_excludeFromReward(address(uniswapV2Pair));
		_excludeFromReward(address(this));
		
        emit Transfer(address(0), address(owner), _tTotal);
    }
	
	receive() external payable {}

    function totalSupply() public override pure returns (uint256) {
        return _tTotal;
    }
	
    function balanceOf(address account) public override view returns (uint256) {
        if (isExcludedFromReward[account]) return tOwned[account];
        return tokenFromReflection(rOwned[account]);
    }
	
    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }
	
	function excludeFromReward(address account) external onlyOwner() {
       require(!isExcludedFromReward[account], "Account is already excluded");
	   require(address(account) != address(0), "Zero Address");
	   
       _excludeFromReward(account);
    }
	
	function _excludeFromReward(address account) internal {
        if(rOwned[account] > 0) {
            tOwned[account] = tokenFromReflection(rOwned[account]);
        }
        isExcludedFromReward[account] = true;
        _excluded.push(account);
    }
	
    function includeInReward(address account) external onlyOwner() {
        require(isExcludedFromReward[account], "Account is already included");
		require(address(account) != address(0), "Zero Address");
		
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                tOwned[account] = 0;
                isExcludedFromReward[account] = false;
                _excluded.pop();
                break;
            }
        }
    }
	
	function excludeFromFee(address account) external onlyOwner {
	   require(!isExcludedFromFee[account], "Account is already the value of 'true'");
	   require(address(account) != address(0), "Zero Address");
	   
	   isExcludedFromFee[account] = true;
	}

	function includeInFee(address account) external onlyOwner {
		require(isExcludedFromFee[account], "Account is already the value of 'false'");
		require(address(account) != address(0), "Zero Address");
		
		isExcludedFromFee[account] = false;
	}
	
	function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        require(pair != uniswapV2Pair, "The pair cannot be removed from automatedMarketMakerPairs");
		require(address(pair) != address(0), "Zero Address");
		
        _setAutomatedMarketMakerPair(pair, value);
    }
	
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(isAutomatedMarketMakerPairs[pair] != value, "Automated market maker pair is already set to that value");
        isAutomatedMarketMakerPairs[pair] = value;
    }
	
	function setMaxTokenPerTxn(uint256 amount) external onlyOwner() {
	   require(amount <= totalSupply(), "Amount cannot be over the total supply.");
	   require(amount >= 500 * 10**18, "Amount cannot be less than 500 Token.");
	   
       maxTokenPerTxn = amount;
    }
	
	function setMaxTokenPerWallet(uint256 amount) external onlyOwner() {
	   require(amount <= totalSupply(), "Amount cannot be over the total supply.");
	   require(amount >= 500 * 10**18, "Amount cannot be less than 500 Token.");
	   
       maxTokenPerWallet = amount;
    }
	
	function excludeFromMaxTokenPerWallet(address account) external onlyOwner {
		require(!isExcludedFromMaxTokenPerWallet[account], "Account is already the value of 'true'");
		require(address(account) != address(0), "Zero Address");
		
		isExcludedFromMaxTokenPerWallet[account] = true;
	}

    function includeInMaxTokenPerWallet(address account) external onlyOwner {
		require(isExcludedFromMaxTokenPerWallet[account], "Account is already the value of 'false'");
		require(address(account) != address(0), "Zero Address");
		
		isExcludedFromMaxTokenPerWallet[account] = false;
	}
	
	function setBurnFee(uint256 buy, uint256 sell, uint256 p2p) external onlyOwner {
	    require(reflectionFee[0].add(buy)  <= 2000 , "Max fee limit reached for 'BUY'");
		require(reflectionFee[1].add(sell) <= 2000 , "Max fee limit reached for 'SELL'");
		require(reflectionFee[2].add(p2p)  <= 2000 , "Max fee limit reached for 'P2P'");
		
		burnFee[0] = buy;
		burnFee[1] = sell;
		burnFee[2] = p2p;
	}
	
	function setReflectionFee(uint256 buy, uint256 sell, uint256 p2p) external onlyOwner {
	    require(burnFee[0].add(buy)  <= 2000 , "Max fee limit reached for 'BUY'");
		require(burnFee[1].add(sell) <= 2000 , "Max fee limit reached for 'SELL'");
		require(burnFee[2].add(p2p)  <= 2000 , "Max fee limit reached for 'P2P'");
		
		reflectionFee[0] = buy;
		reflectionFee[1] = sell;
		reflectionFee[2] = p2p;
	}
	
	function airdropToken(uint256 amount) external {
       require(amount > 0, "Transfer amount must be greater than zero");
	   require(balanceOf(msg.sender) >= amount, "transfer amount exceeds balance");
	   
	   _tokenTransfer(msg.sender, address(this), amount, true, true);
	}
	
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }
	
	function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tBurn) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tBurn, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tBurn);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = _calculateReflectionFee(tAmount);
        uint256 tBurn = _calculateBurnFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tBurn);
        return (tTransferAmount, tFee, tBurn);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tBurn, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rBurn = tBurn.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rBurn);
        return (rAmount, rTransferAmount, rFee);
    }
	
    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }
	
    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (rOwned[_excluded[i]] > rSupply || tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(rOwned[_excluded[i]]);
            tSupply = tSupply.sub(tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
	
	function _takeBurn(uint256 tBurn) private {
        uint256 currentRate =  _getRate();
        uint256 rBurn = tBurn.mul(currentRate);
        rOwned[burnWallet] = rOwned[burnWallet].add(rBurn);
        if(isExcludedFromReward[burnWallet])
            tOwned[burnWallet] = tOwned[burnWallet].add(tBurn);
    }
	
    function _calculateReflectionFee(uint256 amount) private view returns (uint256) {
       return amount.mul(_reflectionFee).div(10000);
    }
	
	function _calculateBurnFee(uint256 amount) private view returns (uint256) {
       return amount.mul(_burnFee).div(10000);
    }
	
    function removeAllFee() private {
       _reflectionFee = 0;
	   _burnFee = 0;
    }
	
    function applyBuyFee() private {
	   _reflectionFee = reflectionFee[0];
	   _burnFee = burnFee[0];
    }
	
	function applySellFee() private {
	   _reflectionFee = reflectionFee[1];
	   _burnFee = burnFee[1];
    }
	
	function applyP2PFee() private {
	   _reflectionFee = reflectionFee[2];
	   _burnFee = burnFee[2];
    }
	
	function applyAirdropFee() private {
	   _reflectionFee = 10000;
	   _burnFee = 0;
    }
	
    function _transfer(address from, address to, uint256 amount) internal override{
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
		require(balanceOf(from) >= amount, "transfer amount exceeds balance");
		
		if(from != owner() && to != owner()) 
		{
		    require(amount <= maxTokenPerTxn, "Exceeds maximum token per txn limit");
		}
		
		if(!isExcludedFromMaxTokenPerWallet[to] && isAutomatedMarketMakerPairs[from]) 
		{
            uint256 balanceRecepient = balanceOf(to);
            require(balanceRecepient + amount <= maxTokenPerWallet, "Exceeds maximum token per wallet limit");
        }
        bool takeFee = true;
        if(isExcludedFromFee[from] || isExcludedFromFee[to]) 
		{
           takeFee = false;
        }
        _tokenTransfer(from, to, amount, takeFee, false);
    }
	
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee, bool airdrop) private {
	
		if(!takeFee)
		{
		   removeAllFee();
		}
		else if(airdrop) 
		{
		   applyAirdropFee();
		}
		else if(!isAutomatedMarketMakerPairs[sender] && !isAutomatedMarketMakerPairs[recipient]) 
		{
		   applyP2PFee();
		}
		else if(isAutomatedMarketMakerPairs[recipient]) 
		{
		   applySellFee();
		}
		else 
		{
		   applyBuyFee();
		}
		
        if (isExcludedFromReward[sender] && !isExcludedFromReward[recipient]) 
		{
            _transferFromExcluded(sender, recipient, amount);
        } 
		else if (!isExcludedFromReward[sender] && isExcludedFromReward[recipient]) 
		{
            _transferToExcluded(sender, recipient, amount);
        } 
		else if (!isExcludedFromReward[sender] && !isExcludedFromReward[recipient]) 
		{
            _transferStandard(sender, recipient, amount);
        } 
		else if (isExcludedFromReward[sender] && isExcludedFromReward[recipient]) 
		{
            _transferBothExcluded(sender, recipient, amount);
        } 
		else 
		{
            _transferStandard(sender, recipient, amount);
        }
    }
	
    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn) = _getValues(tAmount);
        
		rOwned[sender] = rOwned[sender].sub(rAmount);
        rOwned[recipient] = rOwned[recipient].add(rTransferAmount);
        
		_takeBurn(tBurn);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn) = _getValues(tAmount);
        
		rOwned[sender] = rOwned[sender].sub(rAmount);
        tOwned[recipient] = tOwned[recipient].add(tTransferAmount);
        rOwned[recipient] = rOwned[recipient].add(rTransferAmount);           
        
		_takeBurn(tBurn);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn) = _getValues(tAmount);
        
		tOwned[sender] = tOwned[sender].sub(tAmount);
        rOwned[sender] = rOwned[sender].sub(rAmount);
        rOwned[recipient] = rOwned[recipient].add(rTransferAmount);   
		
        _takeBurn(tBurn);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
	
	function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tBurn) = _getValues(tAmount);
        
		tOwned[sender] = tOwned[sender].sub(tAmount);
        rOwned[sender] = rOwned[sender].sub(rAmount);
        tOwned[recipient] = tOwned[recipient].add(tTransferAmount);
        rOwned[recipient] = rOwned[recipient].add(rTransferAmount);        
		
		_takeBurn(tBurn);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
}