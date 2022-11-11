// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./BoringMath.sol";

contract ZeroxZeroToken is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    // Used to track reflected balances
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;

    mapping (address => mapping (address => uint256)) private _allowances;

    // Excludes an address from being subject to any fees when sending or receiving ZeroxZero
    mapping (address => bool) private _isExcludedFromFee;

    // Excludes an address from receiving a proportional amount of the transfer tax
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 200000000 * 10**18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 private zeroBalance = 10**(39 + 18) - _tTotal;

    string private _name = "0x0 Token";
    string private _symbol = "0x0";
    uint8 private _decimals = 18;

    // Fees have a denominator of 10**6
    uint256 public constant DEFAULT_TAX_FEE = 5*10**3; //0.5%

    uint256 public _burnFee = 5*10**3; //0.5%

    uint256 public _stakingFee = 5*10**3; //0.5%
    address public _stakingWallet;

    uint256 public _devFee = 5*10**3; //0.5%
    address public _devWallet;

    constructor (address devWallet, address stakingWallet, address owner) {

        _devWallet = devWallet;
        _stakingWallet = stakingWallet;
        _rOwned[_msgSender()] = _rTotal;

        //exclude staking contract from fee
        _isExcludedFromFee[stakingWallet] = true;
        //exclude this contract from fee
        _isExcludedFromFee[address(this)] = true;
        //exclude dev wallet from fee
        _isExcludedFromFee[devWallet] = true;
        //exclude staking contract from rewards
        excludeFromReward(stakingWallet);

        transferOwnership(owner);
        emit Transfer(address(0), _msgSender(), _tTotal);

        // Add a balance to 0x0 for cosmetic purposes
        emit Transfer(address(0), address(0), zeroBalance);
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
        if (_isExcluded[account]) return _tOwned[account];
        if (account == address(0)) {
          return tokenFromReflection(_rOwned[account]).add(zeroBalance);
        }
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
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    // Returns reflection without accounting for burn, dev & staking fees (upfront fees)
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,) = _getValues(tAmount, 0, DEFAULT_TAX_FEE);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,) = _getValues(tAmount, 0, DEFAULT_TAX_FEE);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        require(_excluded.length < 5, "Too many excluded accounts");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        (, uint256 tSupply) = _getCurrentSupply();
        require(tSupply > 0, "Cannot exclude all holders");
        _excluded.push(account);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount, uint256 upfrontFee, uint256 taxFee) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount, upfrontFee, taxFee);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
    }

    function _getTValues(uint256 tAmount, uint256 upfrontFee, uint256 taxFee) private pure returns (uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount, upfrontFee, taxFee);
        uint256 tTransferAmount = tAmount.sub(tFee);
        return (tTransferAmount, tFee);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);
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
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function calculateTaxFee(uint256 amount, uint256 upfrontFee, uint256 taxFee) private pure returns (uint256) {
        return amount.add(upfrontFee).mul(taxFee).div(
            10**6
        );
    }

    function calculateStakingFee(uint256 amount) private view returns (uint256) {
        return amount.mul(_stakingFee).div(
            10**6
        );
    }

    function calculateDevFee(uint256 amount) private view returns (uint256) {
        return amount.mul(_devFee).div(
            10**6
        );
    }

    function calculateBurnFee(uint256 amount) private view returns (uint256) {
        return amount.mul(_burnFee).div(
            10**6
        );
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

        uint256 burnAmt = 0;
        uint256 devAmt = 0;
        uint256 stakingAmt = 0;

        uint256 upfrontFee = 0;
        uint256 taxFee = 0;

        if (!_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            burnAmt = calculateBurnFee(amount);
            devAmt = calculateDevFee(amount);
            stakingAmt = calculateStakingFee(amount);
            upfrontFee = burnAmt.add(devAmt).add(stakingAmt);
            taxFee = DEFAULT_TAX_FEE;
        }

        if (_isExcluded[from] && !_isExcluded[to]) {
            _transferFromExcluded(from, to, amount, upfrontFee, taxFee);
        } else if (!_isExcluded[from] && _isExcluded[to]) {
            _transferToExcluded(from, to, amount, upfrontFee, taxFee);
        } else if (_isExcluded[from] && _isExcluded[to]) {
            _transferBothExcluded(from, to, amount, upfrontFee, taxFee);
        } else {
            _transferStandard(from, to, amount, upfrontFee, taxFee);
        }

        // Distribute fees
        _transferStandard(from, address(0), burnAmt, 0, 0);
        _transferStandard(from, _devWallet, devAmt, 0, 0);
        _transferToExcluded(from, _stakingWallet, stakingAmt, 0, 0);

    }

    function _transferStandard(address sender, address recipient, uint256 tAmount, uint256 upfrontFee, uint256 taxFee) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount.sub(upfrontFee), upfrontFee, taxFee);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount, uint256 upfrontFee, uint256 taxFee) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount.sub(upfrontFee), upfrontFee, taxFee);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount, uint256 upfrontFee, uint256 taxFee) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount.sub(upfrontFee), upfrontFee, taxFee);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount, uint256 upfrontFee, uint256 taxFee) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount.sub(upfrontFee), upfrontFee, taxFee);
        _tOwned[sender] = _tOwned[sender].sub(tAmount.sub(upfrontFee));
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setDevWallet(address newWallet) external onlyOwner() {
        _devWallet = newWallet;
    }

}