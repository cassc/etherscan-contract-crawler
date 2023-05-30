// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import {IUniswapV2Router02, IUniswapV2Factory} from "./Interfaces.sol";

/**
 *
 * ███╗   ███╗ █████╗  ██████╗ ██╗██╗  ██╗
 * ████╗ ████║██╔══██╗██╔════╝ ██║╚██╗██╔╝
 * ██╔████╔██║███████║██║  ███╗██║ ╚███╔╝
 * ██║╚██╔╝██║██╔══██║██║   ██║██║ ██╔██╗
 * ██║ ╚═╝ ██║██║  ██║╚██████╔╝██║██╔╝ ██╗
 * ╚═╝     ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═╝╚═╝  ╚═╝
 *
 * TRI fork with a sprinkle of magic.
 * Supports:
 *  - Auto passive yield thanks to RFI mechanics
 *  - Auto liquidity generation from each tx
 *  - Magic re-balancer creating buy pressure by burning tokens and re-balancing liquidity
 */
contract Magix is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    string private _name = "Magix";
    string private _symbol = "MAGX";
    uint8 private _decimals = 9;

    uint256 private constant MAX = ~uint256(0);
    uint256 internal _tTotal = 1_000_000e9;
    uint256 internal _rTotal = (MAX - (MAX % _tTotal));

    mapping(address => uint256) internal _rOwned;
    mapping(address => uint256) internal _tOwned;
    mapping(address => mapping(address => uint256)) internal _allowances;

    mapping(address => bool) internal _noFee;
    mapping(address => bool) internal _isExcluded;
    address[] internal _excluded;

    // The tax fee contains two decimal places so 250 = 2.5%
    uint256 public _feeDecimal = 2;
    uint256 public _taxFee = 200;
    uint256 public _liquidityFee = 100;

    uint256 public taxFeeTotal;
    uint256 public liquidityFeeTotal;
    uint256 public burnFeeTotal;

    uint256 public liquidityAddedAt;
    bool public tradingEnabled = false;
    bool public swapAndLiquifyEnabled = true;
    bool private _inSwapAndLiquify;

    // Swapping fees to LP tokens
    uint256 public minTokensBeforeSwap = 500e9;
    uint256 public autoSwapCallerFee = 20e9;

    // Magic re-balancer to buy-back and burn tokens
    address public balancer;
    uint256 public lastRebalance;
    uint256 public rebalanceInterval = 30 minutes;
    uint256 public minTokensForMagic = 100e9;
    uint256 public rebalanceCallerFee = 400; // %
    uint256 public liquidityRemoveFee = 100; // %

    address constant uniswapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    event RewardsDistributed(uint256 amount);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapedTokenForEth(uint256 EthAmount, uint256 TokenAmount);
    event SwapedEthForTokens(uint256 EthAmount, uint256 TokenAmount, uint256 CallerReward, uint256 AmountBurned);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event Rebalance(uint256 tokenBurnt);
    event TradingEnabled();
    event TaxFeeUpdated(uint256 taxFee);
    event LockFeeUpdated(uint256 lockFee);
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event AutoSwapCallerFeeUpdated(uint256 autoSwapCallerFee);
    event LiquidityRemoveFeeUpdated(uint256 liquidityRemoveFee);
    event MagicCallerFeeUpdated(uint256 rebalnaceCallerFee);
    event MinTokenForMagicUpdated(uint256 minRebalanceAmount);
    event MagicIntervalUpdated(uint256 rebalanceInterval);

    modifier lockTheSwap {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }

    constructor() public {
        uniswapV2Router = IUniswapV2Router02(uniswapRouter);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        balancer = address(new Balancer());
        lastRebalance = block.timestamp;

        _noFee[_msgSender()] = true;
        _noFee[address(this)] = true;

        // Exclude uniswapV2Pair from taking rewards
        _isExcluded[uniswapV2Pair] = true;
        _excluded.push(uniswapV2Pair);

        _rOwned[_msgSender()] = _rTotal;
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

    function totalSupply() public override view returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public override view returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override virtual returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override virtual returns (bool) {
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

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function reflectionFromToken(uint256 tokenAmount, bool deductTransferFee) public view returns (uint256) {
        require(tokenAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            return tokenAmount.mul(_getReflectionRate());
        } else {
            return tokenAmount
            .sub(tokenAmount.mul(_taxFee).div(10 ** _feeDecimal + 2))
            .mul(_getReflectionRate());
        }
    }

    function tokenFromReflection(uint256 reflectionAmount) public view returns (uint256) {
        require(reflectionAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getReflectionRate();
        return reflectionAmount.div(currentRate);
    }

    function excludeAccount(address account) external onlyOwner() {
        require(account != uniswapRouter, "Magix: Uniswap router cannot be excluded.");
        require(account != address(this), 'Magix: The contract it self cannot be excluded');
        require(!_isExcluded[account], "Magix: Account is already excluded");

        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccount(address account) external onlyOwner() {
        require(_isExcluded[account], "Magix: Account is already included");

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
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(tradingEnabled || sender == owner() || recipient == owner() ||
        _noFee[sender] || _noFee[recipient], "Trading is locked before presale.");

        // Anti-bot measures
        require(block.timestamp > liquidityAddedAt + 6 minutes || amount <= 20_000e9, "You cannot transfer more than 20000 tokens.");

        // Don't auto-swap tokens in any txs related to Uniswap to keep TX fees low and prevent circular calls
        if (swapAndLiquifyEnabled && !_inSwapAndLiquify && _msgSender() != uniswapV2Pair && _msgSender() != uniswapRouter && sender != uniswapV2Pair && sender != uniswapRouter) {
            uint256 lockedBalanceForPool = balanceOf(address(this));
            bool overMinTokenBalance = lockedBalanceForPool >= minTokensBeforeSwap;
            if (overMinTokenBalance) {
                swapAndLiquifyForEth(lockedBalanceForPool);
            }
        }

        // Transfer magic
        uint256 transferAmount = amount;
        uint256 rate = _getReflectionRate();

        if (!_noFee[sender] && !_noFee[recipient] && !_inSwapAndLiquify) {
            transferAmount = collectFee(sender, amount, rate);
        }

        _rOwned[sender] = _rOwned[sender].sub(amount.mul(rate));
        _rOwned[recipient] = _rOwned[recipient].add(transferAmount.mul(rate));

        if (_isExcluded[sender]) {
            _tOwned[sender] = _tOwned[sender].sub(amount);
        }
        if (_isExcluded[recipient]) {
            _tOwned[recipient] = _tOwned[recipient].add(transferAmount);
        }

        emit Transfer(sender, recipient, transferAmount);
    }

    function collectFee(address account, uint256 amount, uint256 rate) private returns (uint256) {
        uint256 transferAmount = amount;

        // Distribute reflection fee
        if (_taxFee != 0) {
            uint256 taxFee = amount.mul(_taxFee).div(10 ** (_feeDecimal + 2));
            transferAmount = transferAmount.sub(taxFee);
            _rTotal = _rTotal.sub(taxFee.mul(rate));
            taxFeeTotal = taxFeeTotal.add(taxFee);
            emit RewardsDistributed(taxFee);
        }

        // Collect liquidity fee
        if (_liquidityFee != 0) {
            uint256 liquidityFee = amount.mul(_liquidityFee).div(10 ** (_feeDecimal + 2));
            transferAmount = transferAmount.sub(liquidityFee);
            _rOwned[address(this)] = _rOwned[address(this)].add(liquidityFee.mul(rate));
            liquidityFeeTotal = liquidityFeeTotal.add(liquidityFee);
            emit Transfer(account, address(this), liquidityFee);
        }

        return transferAmount;
    }

    function _getReflectionRate() private view returns (uint256) {
        uint256 reflectionSupply = _rTotal;
        uint256 tokenSupply = _tTotal;

        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > reflectionSupply || _tOwned[_excluded[i]] > tokenSupply) {
                return _rTotal.div(_tTotal);
            }

            reflectionSupply = reflectionSupply.sub(_rOwned[_excluded[i]]);
            tokenSupply = tokenSupply.sub(_tOwned[_excluded[i]]);
        }

        if (reflectionSupply < _rTotal.div(_tTotal)) {
            return _rTotal.div(_tTotal);
        }
        return reflectionSupply.div(tokenSupply);
    }

    function swapAndLiquifyForEth(uint256 lockedBalanceForPool) private lockTheSwap {
        uint256 lockedForSwap = lockedBalanceForPool.sub(autoSwapCallerFee);
        uint256 half = lockedForSwap.div(2);
        uint256 otherHalf = lockedForSwap.sub(half);

        uint256 initialBalance = address(this).balance;

        swapTokensForEth(half);

        uint256 newBalance = address(this).balance.sub(initialBalance);

        addLiquidityETH(otherHalf, newBalance);
        emit SwapAndLiquify(half, newBalance, otherHalf);

        _transfer(address(this), tx.origin, autoSwapCallerFee);
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function swapEthForTokens(uint256 ethAmount) private {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value : ethAmount}(
            0,
            path,
            address(balancer),
            block.timestamp
        );
    }

    function addLiquidityETH(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value : ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }

    function removeLiquidityETH(uint256 lpAmount) private returns (uint ETHAmount) {
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), lpAmount);

        (ETHAmount) = uniswapV2Router.removeLiquidityETHSupportingFeeOnTransferTokens(
            address(this),
            lpAmount,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    function doTheMagic() public lockTheSwap {
        require(balanceOf(_msgSender()) >= minTokensForMagic, "Magix: First you have to obtain magic by owning 100 MAGIX");
        require(block.timestamp > lastRebalance + rebalanceInterval, 'Magix: Magic does not happen often, please wait');

        lastRebalance = block.timestamp;

        uint256 amountToRemove = IERC20(uniswapV2Pair).balanceOf(address(this)).mul(liquidityRemoveFee).div(10 ** (_feeDecimal + 2));
        if (amountToRemove == 0) {
            return;
        }
        uint256 initialBalance = address(this).balance;

        removeLiquidityETH(amountToRemove);
        uint256 receivedEth = address(this).balance.sub(initialBalance);

        swapEthForTokens(receivedEth);

        uint256 tNewTokenBalance = balanceOf(address(balancer));
        uint256 tRewardForCaller = tNewTokenBalance.mul(rebalanceCallerFee).div(10 ** (_feeDecimal + 2));
        uint256 tBurn = tNewTokenBalance.sub(tRewardForCaller);

        uint256 rate = _getReflectionRate();

        _rOwned[_msgSender()] = _rOwned[_msgSender()].add(tRewardForCaller.mul(rate));
        _rOwned[address(balancer)] = 0;

        // Just deduct the burn value instead of sending it to the burn address, we want to keep consistent Black Hole inflation rate
        burnFeeTotal = burnFeeTotal.add(tBurn);
        _tTotal = _tTotal.sub(tBurn);
        _rTotal = _rTotal.sub(tBurn.mul(rate));

        emit Transfer(address(balancer), _msgSender(), tRewardForCaller);
        emit Transfer(address(balancer), address(0), tBurn);
        emit Rebalance(tBurn);
    }

    function setExcludedFromFee(address account, bool excluded) public onlyOwner {
        _noFee[account] = excluded;
    }

    function setSwapAndLiquifyEnabled(bool enabled) public onlyOwner {
        swapAndLiquifyEnabled = enabled;
        emit SwapAndLiquifyEnabledUpdated(enabled);
    }

    function setTaxFee(uint256 taxFee) external onlyOwner {
        require(taxFee >= 0 && taxFee <= 5 * 10 ** _feeDecimal, 'Magix: taxFee should be in 0 - 5');
        _taxFee = taxFee;
        emit TaxFeeUpdated(taxFee);
    }

    function setLiquidityFee(uint256 fee) public onlyOwner {
        require(fee >= 0 && fee <= 5 * 10 ** _feeDecimal, 'Magix: lockFee should be in 0 - 5');
        _liquidityFee = fee;
        emit LockFeeUpdated(fee);
    }

    function setMinTokensBeforeSwap(uint256 amount) external onlyOwner() {
        require(amount >= 50e9 && amount <= 25000e9, 'Magix: minTokenBeforeSwap should be in 50e9 - 25000e9');
        require(amount > autoSwapCallerFee, 'Magix: minTokenBeforeSwap should be greater than autoSwapCallerFee');
        minTokensBeforeSwap = amount;
        emit MinTokensBeforeSwapUpdated(minTokensBeforeSwap);
    }

    function setAutoSwapCallerFee(uint256 fee) external onlyOwner() {
        require(fee >= 1e9, 'Magix: autoSwapCallerFee should be greater than 1e9');
        autoSwapCallerFee = fee;
        emit AutoSwapCallerFeeUpdated(autoSwapCallerFee);
    }

    function setLiquidityRemoveFee(uint256 fee) external onlyOwner() {
        require(fee >= 1 && fee <= 10 * 10 ** _feeDecimal, 'Magix: liquidityRemoveFee should be in 1 - 10');
        liquidityRemoveFee = fee;
        emit LiquidityRemoveFeeUpdated(liquidityRemoveFee);
    }

    function setMagicCallerFee(uint256 fee) external onlyOwner() {
        require(fee >= 1 && fee <= 15 * 10 ** _feeDecimal, 'Magix: magicCallerFee should be in 1 - 15');
        rebalanceCallerFee = fee;
        emit MagicCallerFeeUpdated(rebalanceCallerFee);
    }

    function setMagicInterval(uint256 interval) public onlyOwner() {
        rebalanceInterval = interval;
        emit MagicIntervalUpdated(rebalanceInterval);
    }

    function setMinTokenForAlchemy(uint256 amount) external onlyOwner() {
        minTokensForMagic = amount;
        emit MinTokenForMagicUpdated(minTokensForMagic);
    }

    function enableTrading() external onlyOwner() {
        liquidityAddedAt = block.timestamp;

        tradingEnabled = true;
        emit TradingEnabled();
    }

    receive() external payable {}
}

contract Balancer {
    constructor() public {
    }
}