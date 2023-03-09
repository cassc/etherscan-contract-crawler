// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../contracts/interfaces/IPancakeFactory.sol";
import "../contracts/interfaces/IPancakeRouter01.sol";
import "../contracts/interfaces/IPancakeRouter02.sol";
import "../contracts/interfaces/IPancakePair.sol";

contract KET is Context, IERC20, Ownable {
    string private constant _name = "KAILI ENTERTAINMENT TECHNOLOGY";
    string private constant _symbol = "KET";
    uint8 private constant _decimals = 18;

    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 100000000 * 10**18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    IPancakeRouter02 public pancakeRouter;
    address public pancakePair;

    address[] private _excluded;
    address public teamFeeReceiver;
    address public genesisNodeFeeReceiver;

    uint256 public teamFee = 5; 
    uint256 public genesisNodeFee = 2; 
    uint256 public taxFee = 3; // reflection
    uint256 public swapThreshold = _tTotal * 1/1000; //0.1%;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isBlacklisted;

    constructor (address _teamFeeReceiver, address _genesisNodeFeeReceiver, address _pairToken, address _router) {
        _rOwned[_msgSender()] = _rTotal;

        // Create a new pair
        pancakeRouter = IPancakeRouter02(_router);
        pancakePair = IPancakeFactory(pancakeRouter.factory()).createPair(address(this), _pairToken);
        
        // exclude system contracts
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_teamFeeReceiver] = true;
        _isExcludedFromFee[_genesisNodeFeeReceiver] = true;

        teamFeeReceiver = _teamFeeReceiver;
        genesisNodeFeeReceiver = _genesisNodeFeeReceiver;
        
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() external pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!_isBlacklisted[from] && !_isBlacklisted[to], "Blacklisted");

        uint256 _newAmount = amount;
        bool takeFee = true;
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        } else {
            
            uint256 _teamFeeAmt = amount * teamFee / 100;
            uint256 _genesisNodeFeeAmt = amount * genesisNodeFee / 100;
            tokenTransfer(from, teamFeeReceiver, _teamFeeAmt, false);
            tokenTransfer(from, genesisNodeFeeReceiver, _genesisNodeFeeAmt, false);

            _newAmount = amount - _teamFeeAmt - _genesisNodeFeeAmt;
        }

        tokenTransfer(from, to, _newAmount, takeFee);
        
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");

        uint256 currentRate = getRate();
        return rAmount / currentRate;
    }

    function tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) internal {
        uint256 previousTaxFee = taxFee;
        
        if (!takeFee) {
            taxFee = 0;
        } 

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            transferBothExcluded(sender, recipient, amount);
        } else {
            transferStandard(sender, recipient, amount);
        }
        
        if (!takeFee) {
            taxFee = previousTaxFee;
        }
    }

    function transferStandard(address sender, address recipient, uint256 tAmount) internal {
        (uint256 tTransferAmount, uint256 tFee) = getTValues(tAmount);
        uint256 currentRate = getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = getRValues(tAmount, tFee, currentRate);

        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;

        reflectFee(rFee, tFee);

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function transferBothExcluded(address sender, address recipient, uint256 tAmount) internal {
        (uint256 tTransferAmount, uint256 tFee) = getTValues(tAmount);
        uint256 currentRate = getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = getRValues(tAmount, tFee, currentRate);

        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;

        reflectFee(rFee, tFee);

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function transferToExcluded(address sender, address recipient, uint256 tAmount) internal {
        (uint256 tTransferAmount, uint256 tFee) = getTValues(tAmount);
        uint256 currentRate = getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = getRValues(tAmount, tFee, currentRate);

        _rOwned[sender] = _rOwned[sender] - rAmount;
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;

        reflectFee(rFee, tFee);

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function transferFromExcluded(address sender, address recipient, uint256 tAmount) internal {
        (uint256 tTransferAmount, uint256 tFee) = getTValues(tAmount);
        uint256 currentRate = getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = getRValues(tAmount, tFee, currentRate);

        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;

        reflectFee(rFee, tFee);

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function reflectFee(uint256 rFee, uint256 tFee) internal {
        _rTotal    = _rTotal - rFee;
        _tFeeTotal = _tFeeTotal + tFee;
    }

    function takeTransactionFee(address to, uint256 tAmount, uint256 currentRate) internal {
        if (tAmount <= 0) { return; }

        uint256 rAmount = tAmount * currentRate;
        _rOwned[to] = _rOwned[to] + rAmount;
        if (_isExcluded[to]) {
            _tOwned[to] = _tOwned[to] + tAmount;
        }

        emit Transfer(address(this), to, tAmount);
    }
    
    function calculateFee(uint256 amount, uint256 fee) internal pure returns (uint256) {
        return amount * fee / 100;
    }

    function totalFees() external view returns (uint256) {
        return _tFeeTotal;
    }
    
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function isBlacklisted(address account) public view returns(bool) {
        return _isBlacklisted[account];
    }

    function isExcludedFromReward(address account) external view returns (bool) {
        return _isExcluded[account];
    }

    function rescueToken(address tokenAddress, address to) external onlyOwner {
        uint256 contractBalance = IERC20(tokenAddress).balanceOf(address(this));
        IERC20(tokenAddress).transfer(to, contractBalance);
    }

    receive() external payable {}

    // ===================================================================
    // GETTERS
    // ===================================================================

    function getTValues(uint256 tAmount) internal view returns (uint256, uint256) {
        uint256 tFee = calculateFee(tAmount, taxFee);
        uint256 tTransferAmount = tAmount - tFee;

        return (tTransferAmount, tFee);
    }

    function getRValues(uint256 tAmount, uint256 tFee, uint256 currentRate) 
    internal pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount * currentRate;
        uint256 rFee = tFee * currentRate;
        uint256 rTransferAmount = rAmount - rFee;

        return (rAmount, rTransferAmount, rFee);
    }

    function getRate() internal view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = getCurrentSupply();
        return rSupply / tSupply;
    }

    function getCurrentSupply() internal view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply - _rOwned[_excluded[i]];
            tSupply = tSupply - _tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    // ===================================================================
    // SETTERS
    // ===================================================================

    function setBlacklist(address[] memory addr, bool _boolValue) external onlyOwner {
        require(addr.length > 0, "Array length zero");
        for(uint i=0; i<addr.length; i++) {
            _isBlacklisted[addr[i]] = _boolValue;
        }

        emit SetBlacklist(addr, _boolValue);
    }

    function setExcludeFromReward(address account) external onlyOwner {
        require(account != address(0), "Address zero");
        require(!_isExcluded[account], "Account is already excluded");

        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);

        emit SetExcludeFromReward(account);
    }

    function setIncludeInReward(address account) external onlyOwner {
        require(account != address(0), "Address zero");
        require(_isExcluded[account], "Account is not excluded");

        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }

        emit SetIncludeInReward(account);
    }

    function setMarketingFeeReceiver(address _feeReceiver) external onlyOwner {
        require(_feeReceiver != address(0), "Address zero");
        teamFeeReceiver = _feeReceiver;

        emit SetMarketingFeeReceiver(_feeReceiver);
    }

    function setGenesisNodeFeeReceiver(address _feeReceiver) external onlyOwner {
        require(_feeReceiver != address(0), "Address zero");
        genesisNodeFeeReceiver = _feeReceiver;

        emit SetGenesisNodeFeeReceiver(_feeReceiver);
    }

    function setExcludedFromFee(address _addr, bool _boolValue) external onlyOwner {
        require(_addr != address(0), "Address zero");
        _isExcludedFromFee[_addr] = _boolValue;

        emit SetExcludedFromFee(_addr, _boolValue);
    }
    
    function setMarketingFeePercent(uint256 _fee) external onlyOwner {
        require(_fee <= 5, "Exceeded required percentage");
        teamFee = _fee;

        emit SetMarketingFeePercent(_fee);
    }

    function setGenesisNodeFeePercent(uint256 _fee) external onlyOwner {
        require(_fee <= 5, "Exceeded required percentage");
        genesisNodeFee = _fee;

        emit SetGenesisNodeFeePercent(_fee);
    }

    function setTaxFeePercent(uint256 _fee) external onlyOwner {
        require(_fee <= 5, "Exceeded required percentage");
        taxFee = _fee;

        emit SetTaxFeePercent(_fee);
    }

    function setUniswapRouter(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "Address zero");
        pancakeRouter = IPancakeRouter02(_newAddress);

        emit SetUniswapRouter(_newAddress);
    }

    function setUniswapPair(address _newAddress) external onlyOwner {
        require(_newAddress != address(0), "Address zero");
        pancakePair = _newAddress;

        emit SetUniswapPair(_newAddress);
    }

    // ===================================================================
    // EVENTS
    // ===================================================================

    event EnableTrading(bool boolValue);
    event SetBlacklist(address[] addr, bool boolValue);
    event SetExcludeFromReward(address account);
    event SetIncludeInReward(address account);
    event SetMarketingFeeReceiver(address feeReceiver);
    event SetGenesisNodeFeeReceiver(address feeReceiver);
    event SetExcludedFromFee(address account, bool boolValue);
    event SetMarketingFeePercent(uint256 _fee);
    event SetGenesisNodeFeePercent(uint256 _fee);
    event SetBurnFeePercent(uint256 _fee);
    event SetTaxFeePercent(uint256 _fee);
    event SetUniswapRouter(address newAddress);
    event SetUniswapPair(address newAddress);
    event RescueToken(address tokenAddress, address to);
}