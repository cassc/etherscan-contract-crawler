pragma solidity ^0.6.12;

import "./Context.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "../interfaces/IERC20.sol";

abstract contract ReflectToken is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    uint8 private constant _decimals = 18;
    uint256 private _tTotal;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;

    string private _name;
    string private _symbol;

    constructor (string memory name_, string memory symbol_, uint256 tTotal_) public {
        _name = name_;
        _symbol = symbol_;
        _tTotal = tTotal_;
        uint256 MAX = type(uint256).max;
        _rTotal = (MAX - (MAX % _tTotal));
        _rOwned[_msgSender()] = _rTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    /**
     * @dev Amount of tokens to be charged as a reflection fee. Must be in range 0..amount.
     */
    function _calculateReflectionFee(address sender, address recipient, uint256 amount) internal virtual view returns (uint256);

    /**
     * @dev Amount of tokens to be charged and stored in this contract. Must be in range 0..amount.
     */
    function _calculateAccumulationFee(address sender, address recipient, uint256 amount) internal virtual view returns (uint256);

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ReflectToken: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ReflectToken: decreased allowance below zero"));
        return true;
    }

    function getExcluded() external view returns (address[] memory) {
        return _excluded;
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() external view returns (uint256) {
        return _tFeeTotal;
    }

    function reflect(uint256 tAmount) external {
        address sender = _msgSender();
        require(!_isExcluded[sender], "ReflectToken: excluded addresses cannot call this function");
        (uint256 rAmount,,,,,,) = _getValues(sender, address(0), tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external view returns(uint256) {
        require(tAmount <= _tTotal, "ReflectToken: amount must be less than supply");
        address sender = _msgSender();
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,,) = _getValues(sender, address(0), tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,,) = _getValues(sender, address(0), tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "ReflectToken: amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeAccount(address account) public onlyOwner() {
        require(!_isExcluded[account], "ReflectToken: account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccount(address account) public onlyOwner() {
        require(_isExcluded[account], "ReflectToken: account is already included");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ReflectToken: approve from the zero address");
        require(spender != address(0), "ReflectToken: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burn(address from, uint256 tAmount) internal {
        uint256 rAmount = tAmount.mul(_getRate());
        _rOwned[from] = _rOwned[from].sub(rAmount, "ReflectToken: burn amount is more than the balance");
        if (_isExcluded[from]) {
            _tOwned[from] = _tOwned[from].sub(tAmount, "ReflectToken: burn amount is more than the balance");
        }
		_rTotal = _rTotal.sub(rAmount);
		_tTotal = _tTotal.sub(tAmount);
        emit Transfer(_msgSender(), address(0), tAmount);
    }

    function _transfer(address sender, address recipient, uint256 tAmount) internal virtual {
        require(sender != address(0), "ReflectToken: transfer from the zero address");
        require(recipient != address(0), "ReflectToken: transfer to the zero address");
        require(tAmount > 0, "ReflectToken: transfer amount must be greater than zero");

        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rAccumulation, uint256 tTransferAmount, uint256 tFee, uint256 tAccumulation) = _getValues(sender, recipient, tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        if (_isExcluded[sender]) {
            _tOwned[sender] = _tOwned[sender].sub(tAmount);
        }
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        if (_isExcluded[recipient]) {
            _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        }
        if (tFee != 0) {
            _reflectFee(rFee, tFee);
        }
        if (tAccumulation != 0) {
            _accumulateFee(rAccumulation, tAccumulation);
        }
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _accumulateFee(uint256 rAccumulation, uint256 tAccumulation) private {
        _rOwned[address(this)] = _rOwned[address(this)].add(rAccumulation);
        if(_isExcluded[address(this)]) {
            _tOwned[address(this)] = _tOwned[address(this)].add(tAccumulation);
        }
    }

    function _getValues(address sender, address recipient, uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tAccumulation) = _getTValues(sender, recipient, tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rAccumulation) = _getRValues(tAmount, tFee, tAccumulation);
        return (rAmount, rTransferAmount, rFee, rAccumulation, tTransferAmount, tFee, tAccumulation);
    }

    function _getTValues(address sender, address recipient, uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = _calculateReflectionFee(sender, recipient, tAmount);
        uint256 tAccumulation = _calculateAccumulationFee(sender, recipient, tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tAccumulation);
        return (tTransferAmount, tFee, tAccumulation);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tAccumulation) private view returns (uint256, uint256, uint256, uint256) {
        uint256 currentRate = _getRate();
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rAccumulation = tAccumulation.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rAccumulation);
        return (rAmount, rTransferAmount, rFee, rAccumulation);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        uint256 len = _excluded.length;
        for (uint256 i = 0; i < len; i++) {
            address account = _excluded[i];
            uint256 rBalance = _rOwned[account];
            uint256 tBalance = _tOwned[account];
            if (rBalance > rSupply || tBalance > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(rBalance);
            tSupply = tSupply.sub(tBalance);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
}