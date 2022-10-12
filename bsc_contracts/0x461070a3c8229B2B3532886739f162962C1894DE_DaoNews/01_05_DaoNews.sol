// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.16;

import "./DaoNewsLib.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DaoNews is IERC20, Ownable {
    string public name;
    string public symbol;
    uint8 public decimals;
    
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcludedFromReward;
    address[] private _excludedFromReward;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;
    
    uint256 public liquidityFee;
    uint256 public marketingFee; 
    uint256 public rewardFee;
    uint256 public burnFee; 
    uint256 private _feeBase;                             
    
    address public marketingWallet;
    address public liquidityWallet;
        
    uint256 private _liquidityFeeCurrent;
    uint256 private _marketingFeeCurrent;
    uint256 private _rewardFeeCurrent;
    uint256 private _burnFeeCurrent;
    uint256 private _totalFeeCurrent;
    
    address public uniswapV2Pair;
         
    constructor (uint256 _totalSupply, uint8 _decimals, address _router, address _marketingWallet, address _liquidityWallet, address _owner) {
        name = "dao-news";
        symbol = "NWS";
        decimals = _decimals;

        liquidityFee = 25;                         
        marketingFee = 25; 
        rewardFee = 30;         
        burnFee = 20;    
        _feeBase = 10**3;                         

        marketingWallet = _marketingWallet;
        liquidityWallet = _liquidityWallet;
        
        _tTotal = _totalSupply;  
        _rTotal = (MAX - (MAX % _tTotal));
        _rOwned[_owner] = _rTotal;        
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);
        // Create a pancakeswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        _isExcludedFromReward[uniswapV2Pair] = true;
        _excludedFromReward.push(uniswapV2Pair);

        _isExcludedFromReward[_owner] = true;
        _excludedFromReward.push(_owner);

        //exclude owner and this contract from fee
        _isExcludedFromFee[_owner] = true;
        _isExcludedFromFee[address(this)] = true;
        
        emit Transfer(address(0), _owner, _tTotal);

        transferOwnership(_owner);
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcludedFromReward[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        require(_allowances[sender][_msgSender()] >= amount, "Transfer amount exceeds allowance");
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        require(_allowances[spender][_msgSender()] >= subtractedValue, "Decreased allowance below zero");
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcludedFromReward[account];
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcludedFromReward[sender], "Excluded addresses cannot call this function");
        uint256 currentRate = _getRate();
        uint256 rAmount = tAmount * currentRate;
        require(_rOwned[sender] >= rAmount, "ERC20: insufficient balance");
        _rOwned[sender] -= rAmount;
        _rTotal -= rAmount;
        _tFeeTotal += tAmount;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            uint256 currentRate = _getRate();
            uint256 rAmount = tAmount * currentRate;
            return rAmount;
        } else {
            (, uint256 tFee, uint256 tReward) = _getTValues(tAmount);
            (, uint256 rTransferAmount,) = _getRValues(tAmount, tFee, tReward);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }

    function totalRewards() public view returns(uint256) {
        return _tFeeTotal;
    }
    
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal -= rFee;
        _tFeeTotal += tFee;        
        emit Transfer(msg.sender, address(this), tFee);
    } 
    
    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = tAmount * _totalFeeCurrent / _feeBase;
        uint256 tReward = tAmount * _rewardFeeCurrent / _feeBase;
        uint256 tTransferAmount = tAmount - tFee;
        return (tTransferAmount, tFee, tReward);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tReward) private view returns (uint256, uint256, uint256) {
        uint256 currentRate = _getRate();
        uint256 rAmount = tAmount * currentRate;
        uint256 rFee = tFee * currentRate;
        uint256 rReward = tReward * currentRate;
        uint256 rTransferAmount = rAmount - rFee;
        return (rAmount, rTransferAmount, rReward);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excludedFromReward.length; i++) {
            if (_rOwned[_excludedFromReward[i]] > rSupply || _tOwned[_excludedFromReward[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply -= _rOwned[_excludedFromReward[i]];
            tSupply -= _tOwned[_excludedFromReward[i]];
        }
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _incureFee(address sender, uint256 tAmount, address recipient, uint256 fee, uint256 currentRate ) private {
        uint256 tFee = _calculateFee(tAmount, fee);
        uint256 rFee = tFee * currentRate;
        _rOwned[recipient] += rFee;
        if (_isExcludedFromReward[recipient])
            _tOwned[recipient] += tFee;

        emit Transfer(sender, recipient, tFee);
    }

    function _incureBurn(address sender, uint256 tAmount, uint256 currentRate) private {
        uint256 tBurn = _calculateFee(tAmount, _burnFeeCurrent);
        uint256 rBurn = tBurn * currentRate;

        _tTotal -= tBurn;    
        _rTotal -= rBurn;

        emit Transfer(sender, address(0), tBurn);
    }
    
    function _calculateFee(uint256 _amount, uint256 _fee) internal view returns (uint256) {
        if (_fee == 0) return 0;
        return _amount * _fee / _feeBase;
    }
    
    function setFees() private {
        _rewardFeeCurrent = rewardFee;
        _liquidityFeeCurrent = liquidityFee;
        _marketingFeeCurrent = marketingFee;
        _burnFeeCurrent = burnFee;
        _totalFeeCurrent = _rewardFeeCurrent + _liquidityFeeCurrent + _marketingFeeCurrent + _burnFeeCurrent;
    }

    function removeFee() private {
        _rewardFeeCurrent = 0;
        _liquidityFeeCurrent = 0;
        _marketingFeeCurrent = 0;
        _burnFeeCurrent = 0;
        _totalFeeCurrent = 0;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        if (!_isExcludedFromFee[from] && !_isExcludedFromFee[to] 
            && _msgSender() != owner()
            ) { 
            setFees();
        } else {
            removeFee();
        }
        
        //transfer amount, it will take tax, burn, liquidity, marketing fee
        _tokenTransfer(from,to,amount);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tReward) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rReward) = _getRValues(tAmount, tFee, tReward);

        require(_rOwned[sender] >= rAmount, "ERC20: insufficient balance");

        _rOwned[sender] -= rAmount;
        _rOwned[recipient] += rTransferAmount;
        
        if (_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]) {
            // _transferFromExcluded            
            _tOwned[sender] -= tAmount;  
        } else if (!_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
            // _transferToExcluded
            _tOwned[recipient] += tTransferAmount;
        } else if (_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
            // _transferBothExcluded
            _tOwned[sender] -= tAmount;        
            _tOwned[recipient] += tTransferAmount;
        } 

        if (_totalFeeCurrent > 0) {
            uint256 currentRate = _getRate();
            _incureFee(sender, tAmount, marketingWallet, _marketingFeeCurrent, currentRate);
            _incureFee(sender, tAmount, liquidityWallet, _liquidityFeeCurrent, currentRate);
            _incureBurn(sender, tAmount, currentRate);
        }

        _reflectFee(rReward, tReward);

        emit Transfer(sender, recipient, tTransferAmount);
    }
}