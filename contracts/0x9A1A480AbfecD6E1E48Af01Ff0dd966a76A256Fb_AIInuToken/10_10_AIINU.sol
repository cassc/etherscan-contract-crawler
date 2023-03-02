//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract AIInuToken is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcludedFromMaxTxAmount;
    mapping (address => bool) private _isExcludedFromMaxHoldAmount;

    mapping (address => bool) private _isExcludedFromReward;
    address[] private _excludedFromReward;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1_000_000_000 * 10**6 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    // 0.5% 
    uint256 private _maxTxAmount = 5_000_000 * 10**6 * 10**9;

    // 2%
    uint256 private _maxHoldAmount = 20_000_000 * 10**6 * 10**9;

    string private _name = "AI Inu";
    string private _symbol = "AIINU";
    uint8 private _decimals = 9;
    
    uint256 private _taxFee = 200;
    uint256 private _previousTaxFee = _taxFee;
    
    uint256 private _treasuryFee = 300;
    uint256 private _previousTreasuryFee = _treasuryFee;

    address public immutable uniswapV2Pair;

    address private _dao;
    event DAOChanged(address previousDAO, address newDAO);

    modifier onlyDAO() {
        require(_dao == _msgSender(), "AIINU: Caller is not the DAO");
        _;
    }
    
    constructor () {
        _changeDAO(owner());

        _rOwned[_msgSender()] = _rTotal;
        
         // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f)
            .createPair(
                address(this),
                0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 // WETH
                );

        //exclude owner and this contract from fee and max tx/hold amount
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        _isExcludedFromMaxTxAmount[owner()] = true;
        _isExcludedFromMaxTxAmount[address(this)] = true;

        // also exclude the pair and the black hole from max hold amount
        _isExcludedFromMaxHoldAmount[owner()] = true;
        _isExcludedFromMaxHoldAmount[address(this)] = true;
        _isExcludedFromMaxHoldAmount[uniswapV2Pair] = true;
        _isExcludedFromMaxHoldAmount[address(0xdead)] = true;
        
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcludedFromReward[account];
    }

    function changeDAO(address newDAO) external onlyOwner {
        _changeDAO(newDAO);
    }

    function _changeDAO(address newDAO) private {
        address prevDao = _dao;
        _dao = newDAO;
        emit DAOChanged(prevDao, _dao);
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function taxFee() public view returns (uint256) {
        return _taxFee;
    }

    function treasuryFee() public view returns (uint256) {
        return _treasuryFee;
    }

    function maxTxAmount() public view returns (uint256) {
        return _maxTxAmount;
    }

    function maxHoldAmount() public view returns (uint256) {
        return _maxHoldAmount;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcludedFromReward[sender], "AIINU: Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "AIINU: Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "AIINU: Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcludedFromReward[account], "AIINU: Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcludedFromReward[account] = true;
        _excludedFromReward.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcludedFromReward[account], "AIINU: Account is not excluded");
        for (uint256 i = 0; i < _excludedFromReward.length; i++) {
            if (_excludedFromReward[i] == account) {
                _excludedFromReward[i] = _excludedFromReward[_excludedFromReward.length - 1];
                _tOwned[account] = 0;
                _isExcludedFromReward[account] = false;
                _excludedFromReward.pop();
                break;
            }
        }
    }
    
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setIsExcludedFromMaxTxAmount(address account, bool excluded) public onlyOwner {
        _isExcludedFromMaxTxAmount[account] = excluded;
    }

    function isExcludedFromMaxTxAmount(address account) public view returns (bool) {
        return _isExcludedFromMaxTxAmount[account];
    }

    function setIsExcludedFromMaxHoldAmount(address account, bool excluded) public onlyOwner {
        _isExcludedFromMaxHoldAmount[account] = excluded;
    }

    function isExcludedFromMaxHoldAmount(address account) public view returns (bool) {
        return _isExcludedFromMaxHoldAmount[account];
    }
    
    // rate in basis points. Eg: 200 - 2.0% of total supply (100% = 10000)
    function setTaxFeePercent(uint256 taxFee_) external onlyOwner() {
        _taxFee = taxFee_;
    }
    
    // rate in basis points. Eg: 300 - 3.0% of total supply (100% = 10000)
    function setTreasuryFeePercent(uint256 treasuryFee_) external onlyOwner() {
        _treasuryFee = treasuryFee_;
    }
   
    // rate in basis points. Eg: 50 - 0.5% of total supply (100% = 10000)
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(
            10**4
        );
    }

    // rate in basis points. Eg: 200 - 2.0% of total supply (100% = 10000)
    function setMaxHoldPercent(uint256 maxHoldPercent) external onlyOwner() {
        _maxHoldAmount = _tTotal.mul(maxHoldPercent).div(
            10**4
        );
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tTreasury) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tTreasury, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTreasury);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tTreasury = calculateTreasuryFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tTreasury);
        return (tTransferAmount, tFee, tTreasury);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tTreasury, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTreasury = tTreasury.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rTreasury);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excludedFromReward.length; i++) {
            if (_rOwned[_excludedFromReward[i]] > rSupply || _tOwned[_excludedFromReward[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excludedFromReward[i]]);
            tSupply = tSupply.sub(_tOwned[_excludedFromReward[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    function _takeTreasury(uint256 tTreasury) private {
        uint256 currentRate =  _getRate();
        uint256 rTreasury = tTreasury.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTreasury);
        if(_isExcludedFromReward[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tTreasury);
    }
    
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10**4
        );
    }

    function calculateTreasuryFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_treasuryFee).div(
            10**4
        );
    }
    
    function removeAllFee() private {
        if(_taxFee == 0 && _treasuryFee == 0) return;
        
        _previousTaxFee = _taxFee;
        _previousTreasuryFee = _treasuryFee;
        _taxFee = 0;
        _treasuryFee = 0;
    }
    
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _treasuryFee = _previousTreasuryFee;
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
        require(amount > 0, "ERC20: Transfer amount must be greater than zero");
        if(!_isExcludedFromMaxTxAmount[from])
            require(amount <= _maxTxAmount, "AIINU: Transfer amount exceeds the maxTxAmount.");

        if(!_isExcludedFromMaxHoldAmount[to])
            require(balanceOf(to).add(amount) <= _maxHoldAmount, "AIINU: Balance exceeds the maxHoldAmount.");
        
        //indicates if fee should be deducted from transfer
        bool takeFee = true;
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        
        _tokenTransfer(from,to,amount,takeFee);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(!takeFee)
            removeAllFee();
        
        if (_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcludedFromReward[sender] && !_isExcludedFromReward[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcludedFromReward[sender] && _isExcludedFromReward[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        
        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTreasury) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeTreasury(tTreasury);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTreasury) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeTreasury(tTreasury);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTreasury) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeTreasury(tTreasury);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTreasury) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeTreasury(tTreasury);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function withdrawTreasury() external onlyDAO {
        uint256 balance = balanceOf(address(this));
        require(balance > 0, "AIINU: Nothing to withdraw");
        SafeERC20.safeTransfer(IERC20(address(this)), _msgSender(), balance);
    }

    // to recieve ETH
    receive() external payable {}

    // withdraw ETH 
    function withdrawETH() external onlyDAO returns (bool) {
        require(address(this).balance > 0, "AIINU: Nothing to withdraw");
        (bool success,) = address(msg.sender).call{value: address(this).balance}("");
        return success;
    }
    

}