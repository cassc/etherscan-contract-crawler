// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

abstract contract Base is Context, IERC20, Ownable {
    using SafeMath for uint256;

    uint256 private constant MAX = ~uint256(0);

    uint256 internal immutable _txPercentageFee;
    uint256 private immutable _tTotal;

    uint8 private _decimals = 9;
    string private _name;
    string private _symbol;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;
    bool private _canReflect = true;
    mapping(address => bool) private _isExcluded;
    mapping(address => mapping(address => uint256)) private _allowances;
    address[] private _excluded;

    mapping(address => uint256) internal _rOwned;
    mapping(address => uint256) internal _tOwned;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 tTotal_,
        uint256 txPercentageFee_
    ) {
        _tTotal = tTotal_;
        _txPercentageFee = txPercentageFee_;

        _name = name_;
        _symbol = symbol_;
        _rTotal = (MAX - (MAX % tTotal_));
        _rOwned[_msgSender()] = _rTotal;
        _isExcluded[address(0)] = true;

        _excluded.push(address(0));

        emit Transfer(address(0), _msgSender(), tTotal_);
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

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    ///////////// BALANCEOF LOGIC /////////////

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];

        return tokenFromReflection(_rOwned[account]);
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            'Amount must be less than total reflections'
        );

        // The number of total reflections per token
        uint256 currentRate = _getRate();

        // Number of tokens per reflection based on the global rate
        return rAmount.div(currentRate);
    }

    ///////////// TRANSFER LOGIC /////////////

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), 'ERC20: transfer from the zero address');
        require(recipient != address(0), 'ERC20: transfer to the zero address');
        require(amount > 0, 'Transfer amount must be greater than zero');

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) internal virtual;

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) internal virtual;

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) internal virtual;

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) internal virtual;

    function _reflectFee(uint256 rFee, uint256 tFee) internal {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                'ERC20: transfer amount exceeds allowance'
            )
        );

        return true;
    }

    ///////////// ALLOWANCE LOGIC /////////////

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);

        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), 'ERC20: approve from the zero address');
        require(spender != address(0), 'ERC20: approve to the zero address');

        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );

        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                'ERC20: decreased allowance below zero'
            )
        );

        return true;
    }

    ///////////// INCLUDE EXCLUDD LOGIC /////////////

    function includeAccount(address account) external onlyOwner() {
        require(_isExcluded[account], 'Account is already excluded');

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

    function excludeAccount(address account) external onlyOwner() {
        require(!_isExcluded[account], 'Account is already excluded');

        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }

        _isExcluded[account] = true;

        _excluded.push(account);
    }

    ///////////// PUBLIC REFLECTION LOGIC /////////////

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        public
        view
        returns (uint256)
    {
        require(tAmount <= _tTotal, 'Amount must be less than supply');

        if (!deductTransferFee) {
            (uint256 rAmount, , , , ) = _getValues(tAmount);

            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , ) = _getValues(tAmount);

            return rTransferAmount;
        }
    }

    function disableReflection() public onlyOwner() {
        _canReflect = false;
    }

    ///////////// SHARED /////////////

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();

        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;

        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) {
                return (_rTotal, _tTotal);
            }

            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }

        if (rSupply < _rTotal.div(_tTotal)) {
            return (_rTotal, _tTotal);
        }

        return (rSupply, tSupply);
    }

    function _getValues(uint256 tAmount)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) =
            _getRValues(tAmount, tFee, currentRate);

        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
    }

    function _getTValues(uint256 tAmount)
        private
        view
        returns (uint256, uint256)
    {
        uint256 tFee = _canReflect ? tAmount.mul(_txPercentageFee).div(100) : 0;
        uint256 tTransferAmount = tAmount.sub(tFee);

        return (tTransferAmount, tFee);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);

        return (rAmount, rTransferAmount, rFee);
    }

    event Debug(string text, uint256 value);
}