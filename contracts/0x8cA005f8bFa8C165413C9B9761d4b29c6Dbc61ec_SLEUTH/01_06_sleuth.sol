pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// slothereum.io (SLEUTH)
// SLEUTH is a deflationary score based currency model
// Up to to 5% burn reflection on every transaction
// Earn up to 10% reflection reward on every transaction if the score reached 100 -
// Only max. 5% transaction fee

contract SLEUTH is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _scoreOf;
    mapping(address => uint256) private _rFeeTotalByAddress;
    mapping(address => uint256) private _rFeeTotalLastByAddress;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcluded;
    address[] private _excluded;

    string private constant _NAME = "Slothereum";
    string private constant _SYMBOL = "SLEUTH";
    uint8 private constant _DECIMALS = 9;

    uint256 private constant _MAX = ~uint256(0);
    uint256 private constant _DECIMALFACTOR = 10**uint256(_DECIMALS);
    uint256 private constant _GRANULARITY = 100;

    uint256 private _tTotal = 200000000 * _DECIMALFACTOR; // 200 Millions Tokens
    uint256 private _rTotal = (_MAX - (_MAX % _tTotal));
    uint256 private _rGrossTotal = (_MAX - (_MAX % _tTotal));
    uint256 private _rFeeTotal = 0;

    uint256 private _tFeeTotal;
    uint256 private _tBurnTotal;
    uint256 private _taxFee = 200; // starting with 2% tax
    uint256 private _burnFee = 100; // starting with 1% burn

    uint256 private constant _MAX_BURN_FEE = 500; // max. 5% burn possible
    uint256 private constant _MAX_TAX_FEE = 500; // max. 5% tax possible
    uint256 private constant _MAX_TX_SIZE = 200000000 * _DECIMALFACTOR;

    bool private _isScoreSystemDisabled = false; // break free from score system

    // Only for launch purpose
    bool private _limitsInEffect = true;
    uint256 private _maxTransactionAmount = (_tTotal * 5) / 1000;
    uint256 private _maxWalletAmount = (_tTotal * 5) / 1000;

    constructor() {
        _rOwned[_msgSender()] = _rTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _NAME;
    }

    function symbol() public pure returns (string memory) {
        return _SYMBOL;
    }

    function decimals() public pure returns (uint8) {
        return _DECIMALS;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account], account);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
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
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
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
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function totalBurn() public view returns (uint256) {
        return _tBurnTotal;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(
            !_isExcluded[sender],
            "Excluded addresses cannot call this function"
        );
        (uint256 rAmount, , , , , ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        public
        view
        returns (uint256)
    {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , , ) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount, address account)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );

        uint256 currentRate = _getRateByAddress(account);
        return rAmount.div(currentRate);
    }

    function excludeAccount(address account) external onlyOwner {
        require(
            account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D,
            "We can not exclude Uniswap router."
        );
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account], account);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccount(address account) external onlyOwner {
        require(_isExcluded[account], "Account is already excluded");
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

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "approve from the zero address");
        require(spender != address(0), "approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "transfer from the zero address");
        require(recipient != address(0), "transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (sender != owner() && recipient != owner())
            require(
                amount <= _MAX_TX_SIZE,
                "Transfer amount exceeds the maxTxAmount."
            );

        checkTransferLimits(recipient, amount);

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
    ) private {
        uint256 currentRate = _getRate();
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tBurn
        ) = _getValues(tAmount);
        uint256 rBurn = tBurn.mul(currentRate);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee(rFee, rBurn, tFee, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        uint256 currentRate = _getRate();
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tBurn
        ) = _getValues(tAmount);
        uint256 rBurn = tBurn.mul(currentRate);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee(rFee, rBurn, tFee, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        uint256 currentRate = _getRate();
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tBurn
        ) = _getValues(tAmount);
        uint256 rBurn = tBurn.mul(currentRate);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee(rFee, rBurn, tFee, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        uint256 currentRate = _getRate();
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tBurn
        ) = _getValues(tAmount);
        uint256 rBurn = tBurn.mul(currentRate);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee(rFee, rBurn, tFee, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(
        uint256 rFee,
        uint256 rBurn,
        uint256 tFee,
        uint256 tBurn
    ) private {
        _rGrossTotal = _rGrossTotal.sub(rBurn);
        _rTotal = _rTotal.sub(rFee).sub(rBurn);
        _tFeeTotal = _tFeeTotal.add(tFee);
        _tBurnTotal = _tBurnTotal.add(tBurn);
        _tTotal = _tTotal.sub(tBurn);
        _rFeeTotal = _rFeeTotal.add(rFee);
    }

    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 tTransferAmount, uint256 tFee, uint256 tBurn) = _getTValues(
            tAmount,
            _taxFee,
            _burnFee
        );
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tBurn,
            currentRate
        );
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tBurn);
    }

    function _getTValues(
        uint256 tAmount,
        uint256 taxFee,
        uint256 burnFee
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = ((tAmount.mul(taxFee)).div(_GRANULARITY)).div(100);
        uint256 tBurn = ((tAmount.mul(burnFee)).div(_GRANULARITY)).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tBurn);
        return (tTransferAmount, tFee, tBurn);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tBurn,
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
        uint256 rBurn = tBurn.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rBurn);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() public view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply(
            _rTotal,
            _tTotal
        );
        return rSupply.div(tSupply);
    }

    function _getRateByAddress(address adr) private view returns (uint256) {
        if (_isScoreSystemDisabled) {
            (uint256 rSupply, uint256 tSupply) = _getCurrentSupply(
                _rTotal,
                _tTotal
            );
            return rSupply.div(tSupply);
        }

        uint256 feeSum = _getReflectionRewards(adr) + _rFeeTotalByAddress[adr];
        uint256 netTotal = _rGrossTotal.sub(feeSum);

        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply(
            netTotal,
            _tTotal
        );
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply(uint256 rTotal, uint256 tTotal)
        private
        view
        returns (uint256, uint256)
    {
        uint256 rSupply = rTotal;
        uint256 tSupply = tTotal;

        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < rTotal.div(tTotal)) return (rTotal, tTotal);
        return (rSupply, tSupply);
    }

    function disableScoreSystem(bool isScoreSystemDisabled) external onlyOwner {
        _isScoreSystemDisabled = isScoreSystemDisabled;
    }

    function setTaxValue(uint256 taxFee) external onlyOwner {
        require(taxFee <= _MAX_TAX_FEE, "Fee value must be smaller than 5%");
        require(taxFee >= 0, "Burn must be min. 0 ");
        _taxFee = taxFee;
    }

    function setBurnValue(uint256 burnFee) external onlyOwner {
        require(burnFee <= _MAX_BURN_FEE, "Burn value must be smaller than 5%");
        require(burnFee >= 0, "Burn must be min. 0 ");
        require(
            burnFee <= _taxFee,
            "Burn must be smaller or same as tax the value"
        );
        _burnFee = burnFee;
    }

    function _applyScore(uint256 score, address addr) private {
        require(score <= 100, "Score must be smaller than 100");
        require(score >= 0, "Score must be min. 0 ");

        _applyRewardsOfRange(addr);
        _scoreOf[addr] = score;
    }

    function setScore(uint256 score, address addr) external onlyOwner {
        _applyScore(score, addr);
    }

    function bulkSetScore(uint256[] memory scores, address[] memory addresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            _applyScore(scores[i], addresses[i]);
        }
    }

    function scoreOf(address addr) public view returns (uint256) {
        return _scoreOf[addr];
    }

    function rFeeTotalOf(address addr) public view returns (uint256) {
        return _rFeeTotalByAddress[addr];
    }

    function rFeeTotalLastOf(address addr) public view returns (uint256) {
        return _rFeeTotalLastByAddress[addr];
    }

    function _getReflectionRewards(address addr)
        private
        view
        returns (uint256)
    {
        uint256 rFeeTotalRange = _rFeeTotal - _rFeeTotalLastByAddress[addr];
        uint256 pct = _scoreOf[addr];

        // Double the reward on perfect score of 100
        if (pct == 100) {
            pct = 200;
        }

        uint256 calcedReflectionFeeRewards = rFeeTotalRange.mul(pct).div(100);

        return calcedReflectionFeeRewards;
    }

    function _applyRewardsOfRange(address addr) private {
        _rFeeTotalByAddress[addr] =
            _rFeeTotalByAddress[addr] +
            _getReflectionRewards(addr);
        _rFeeTotalLastByAddress[addr] = _rFeeTotal;
    }

    function removeLimits() external onlyOwner returns (bool) {
        _limitsInEffect = false;
        return true;
    }

    function checkTransferLimits(address to, uint256 amount) private view {
        if (_limitsInEffect) {
            if (to != owner() && to != address(0) && to != address(0xdead)) {
                require(
                    amount <= _maxTransactionAmount,
                    "Transfer amount exceeds the maxTransactionAmount."
                );
                require(
                    amount + balanceOf(to) <= _maxWalletAmount,
                    "Unable to exceed Max Wallet"
                );
            }
        }
    }
}