// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.4;

import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import { IUniswapV2Router02, IUniswapV2Factory, IUniswapV2Pair } from './interfaces/IUniswap.sol';

/// @title DetfReflect smart contract
/// @author D-ETF.com
/// @notice This contract included in the main Detf smart contract
/// @dev Contains the main logic of re-balancing and fees.
/// The contract was forked from reflect.finance project, and includes changes related to AMM swap fees.
contract DetfReflect is Ownable, IERC20, IERC20Metadata {
    using SafeMath for uint256;
    using Address for address;

    string private constant _NAME = 'DETF token';
    string private constant _SYMBOL = 'DETF';
    uint8 private constant  _DECIMALS = 18;

    uint256 private constant _MAX = ~uint256(0);
    uint256 private constant _HOLD_FEE = 150; // 1.5% of tokens goes to existing holders
    uint256 private _holdFee = _HOLD_FEE;
    uint256 private constant _TREASURE_FEE = 150; // 1.5% of tokens goes to treasury contract
    uint256 private _treasureFee = _TREASURE_FEE;
    uint256 private constant _HUNDRED_PERCENT = 10000; // 100%
    uint256 private _withdrawableAmount = 100000 * (10 ** _DECIMALS); // When 100k DEFT collected, it should be swapped to USDC automatically

    uint256 private _tTotal = 100000000 * (10 ** _DECIMALS); // 100 mln tokens
    uint256 private _rTotal = (_MAX - (_MAX % _tTotal));
    uint256 private _tHoldFeeTotal;
    uint256 private _slippage;

    bool private _swapping;
    bool public inSwapAndLiquify;
    address public pool;
    address public uniswapV2UsdcPair;
    IUniswapV2Router02 public uniswapV2Router;
    IERC20 public usdc;

    address[] private _excluded;
    mapping (address => bool) private _isExcluded;
    mapping (address => bool) private _isAmm;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    event Log(string message);
    event AmmAdded(address target);
    event AmmRemoved(address target);
    event ExcludedAdded(address target);
    event ExcludedRemoved(address target);
    event PoolAddressChanged(address newPool);
    event TreasureWithdraw(address receiver, uint256 amount);
    event TreasureFeeAdded(uint256 totalBalance, uint256 tfee, uint256 rFee);
    event UsdcReceived(address receiver, uint256 detfSwapped, uint256 usdcReceived);

    constructor (address uniswapV2Router_, address usdc_) {
        _rOwned[_msgSender()] = _rTotal;
        usdc = IERC20(usdc_);
        uniswapV2Router = IUniswapV2Router02(uniswapV2Router_);
        uniswapV2UsdcPair = address(IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), address(usdc)));
        excludeAccountFromRewards(msg.sender);
        excludeAccountFromRewards(address(this));
        excludeAccountFromRewards(uniswapV2UsdcPair);
        addToAmmList(uniswapV2UsdcPair);
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    //  --------------------
    //  SETTERS (Ownable)
    //  --------------------

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    function excludeAccountFromRewards(address account) public onlyOwner {
        require(!_isExcluded[account], 'excludeAccountFromRewards: Account is already excluded');

        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }

        _isExcluded[account] = true;
        _excluded.push(account);

        emit ExcludedAdded(account);
    }

    function includeAccountForRewards(address account) public onlyOwner {
        require(_isExcluded[account], 'includeAccountForRewards: Account is already excluded');
        require(account != address(this), 'includeAccountForRewards: Can not include token address');

        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }

        emit ExcludedRemoved(account);
    }

    function addToAmmList(address account) public onlyOwner {
        require(account != address(0), 'addToAmmList: Incorrect address!');

        _isAmm[account] = true;

        emit AmmAdded(account);
    }

    function removeFromAmmList(address account) public onlyOwner {
        require(account != address(0), 'removeFromAmmList: Incorrect address!');

        _isAmm[account] = false;

        emit AmmRemoved(account);
    }

    function changeWithdrawLimit(uint256 newLimit) public onlyOwner {
        _withdrawableAmount = newLimit;
    }

    function withdraw(address recipient, uint256 amount) public onlyOwner {
        uint256 balance = balanceOf(address(this));
        require(balance >= _withdrawableAmount, 'withdraw: Balance is less from required limit');
        require(amount <= balance, 'withdraw: Amount is more then balance');

        _transfer(address(this), recipient, amount);

        emit TreasureWithdraw(recipient, amount);
    }

    function setPoolAddress(address pool_) public onlyOwner {
        require(pool_ != address(this), 'setPoolAddress: Zero address not allowed');
        pool = pool_;

        emit PoolAddressChanged(pool);
    }

    function setSlippage(uint256 slippage) public onlyOwner returns (bool) {
        _slippage = slippage;
        return true;
    }

    //  --------------------
    //  SETTERS
    //  --------------------


     function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);

        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);

        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, 'transferFrom: Transfer amount exceeds allowance'));

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));

        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, 'decreaseAllowance: decreased allowance below zero'));

        return true;
    }

    function reflect(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], 'reflect: Excluded addresses cannot call this function');

        (uint256 rAmount,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tHoldFeeTotal = _tHoldFeeTotal.add(tAmount);
    }


    //  --------------------
    //  GETTERS
    //  --------------------


    function name() public pure override returns (string memory) {
        return _NAME;
    }

    function symbol() public pure override returns (string memory) {
        return _SYMBOL;
    }

    function decimals() public pure override returns (uint8) {
        return _DECIMALS;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (account == address(this) || _isExcluded[account]) return _tOwned[account];
        else return tokenFromReflection(_rOwned[account]);
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function isAmmContract(address account) public view returns (bool) {
        return _isAmm[account];
    }

    function totalFees() public view returns (uint256) {
        return _tHoldFeeTotal;
    }

    function getSlippage() public view returns (uint256) {
        return _slippage;
    }

    function getHoldingFee() public pure returns (uint256) {
        return _HOLD_FEE;
    }

    function getTreasureFee() public pure returns (uint256) {
        return _TREASURE_FEE;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns (uint256) {
        require(tAmount <= _tTotal, 'reflectionFromToken: Amount must be less than supply');

        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(rAmount <= _rTotal, 'tokenFromReflection: Amount must be less than total reflections');

        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }


    //  --------------------
    //  INTERNAL
    //  --------------------


    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), '_approve: Approve from the zero address');
        require(spender != address(0), '_approve: Approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), '_transfer: Transfer from the zero address');
        require(recipient != address(0), '_transfer: Transfer to the zero address');
        require(amount > 0, '_transfer: Transfer amount must be greater than zero');
        require(balanceOf(sender) >= amount, "_transfer: The balance is insufficient");
        bool cutFee = (_isAmm[recipient] || _isAmm[sender]) && !_swapping;
        if (
            _tOwned[address(this)] >= _withdrawableAmount && 
            msg.sender != uniswapV2UsdcPair && 
            !inSwapAndLiquify
        ) {
            _swapAndSend();
        }
        // Remove all fees, if it is not swap transaction
        if (!cutFee) {
            _disableFee();
        }

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

        // Reset the fees back again
        if (!cutFee) {
            _enableFee();
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tHoldFee,
            uint256 tTreasureFee
        ) = _getValues(tAmount);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        _claimTreasureFee(tTreasureFee);
        _reflectFee(rFee, tHoldFee);

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tHoldFee,
            uint256 tTreasureFee
        ) = _getValues(tAmount);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        _claimTreasureFee(tTreasureFee);
        _reflectFee(rFee, tHoldFee);

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tHoldFee,
            uint256 tTreasureFee
        ) = _getValues(tAmount);

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        _claimTreasureFee(tTreasureFee);
        _reflectFee(rFee, tHoldFee);

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tHoldFee,
            uint256 tTreasureFee
        ) = _getValues(tAmount);

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        _claimTreasureFee(tTreasureFee);
        _reflectFee(rFee, tHoldFee);

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tHoldFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tHoldFeeTotal = _tHoldFeeTotal.add(tHoldFee);
    }

    function _disableFee() private {
        if (_holdFee == 0 && _treasureFee == 0) return;

        _swapping = true;
        _holdFee = 0;
        _treasureFee = 0;
    }

    function _enableFee() private {
        _swapping = false;
        _holdFee = _HOLD_FEE;
        _treasureFee = _TREASURE_FEE;
    }

    function _claimTreasureFee(uint256 tTreasureFee) private {
        uint256 currentRate = _getRate();
        uint256 rTreasureFee = tTreasureFee.mul(currentRate);

        _rOwned[address(this)] = _rOwned[address(this)].add(rTreasureFee);
        _tOwned[address(this)] = _tOwned[address(this)].add(tTreasureFee);

        emit TreasureFeeAdded(balanceOf(address(this)), tTreasureFee, rTreasureFee);
    }

    function _swapAndSend() private lockTheSwap {
        _swapTokensForUSDC(_withdrawableAmount);
        uint256 usdcBalance = usdc.balanceOf(address(this));
        usdc.transfer(pool, usdcBalance);
        emit UsdcReceived(pool, _withdrawableAmount, usdcBalance);
    }

    function _swapTokensForUSDC(uint256 tokenAmount) private {
        require(pool != address(0), "Pool not found");
        (uint256 reserveIn, uint256 reserveOut,) = IUniswapV2Pair(uniswapV2UsdcPair).getReserves();
        uint256 amountOut = uniswapV2Router.getAmountOut(tokenAmount, reserveIn, reserveOut);
        uint256 minAmountOut = amountOut.sub(amountOut.mul(_slippage).div(_HUNDRED_PERCENT));
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(usdc);
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        try uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            minAmountOut,
            path,
            pool,
            block.timestamp
        ) {
            emit Log("DETF->USDC swap success");
        } catch {
            _approve(address(this), address(uniswapV2Router), 0);
            emit Log("DETF->USDC swap failed");
        }
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tHoldFee, uint256 tTreasureFee) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tHoldFee, tTreasureFee);

        return (
            rAmount,
            rTransferAmount,
            rFee,
            tTransferAmount,
            tHoldFee,
            tTreasureFee
        );
    }

    function _getReflectAmount(uint256 tAmount) private view returns (uint256) {
        uint256 currentRate = _getRate();
        uint256 rAmount = tAmount.mul(currentRate);

        return rAmount;
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        // Cut the holding and treasure fees from the main amount (only if swapping)
        uint256 tHoldFee = tAmount.mul(_holdFee).div(_HUNDRED_PERCENT);
        uint256 tTreasureFee = tAmount.mul(_treasureFee).div(_HUNDRED_PERCENT);
        uint256 tTransferAmount = tAmount.sub(tHoldFee).sub(tTreasureFee);

        return (
            tTransferAmount,
            tHoldFee,
            tTreasureFee
        );
    }

    function _getRValues(uint256 tAmount, uint256 tHoldFee, uint256 tTreasureFee) private view returns (uint256, uint256, uint256) {
        uint256 currentRate = _getRate();
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tHoldFee.mul(currentRate);
        uint256 rTreasureFee = tTreasureFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rTreasureFee);

        return (
            rAmount,
            rTransferAmount,
            rFee
        );
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();

        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }

        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);

        return (
            rSupply,
            tSupply
        );
    }
}