/*
 * SPDX-License-Identifier: Unlicensed
 * Copyright © 2020 reflect.finance. ALL RIGHTS RESERVED.
 */

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract FDIC is Context, IERC20, Ownable {
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => uint256) private _lastTransaction;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;
    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 6942013378008135 * 10 ** 18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "FDIC";
    string private _symbol = "FDIC";
    uint8 private _decimals = 18;

    uint256 public _taxFee = 2;
    uint256 private _previousTaxFee = _taxFee;

    uint256 public _liquidityFee = 1;
    uint256 private _previousLiquidityFee = _liquidityFee;

    // Percent of total supply where a wallet liquidated
    uint256 public liquidationThresholdPercent = 1;
    // Time passed since last transaction at which point a wallet can be liqudiated
    uint256 public liquidationThresholdTime = 1 days;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    bool public liquidationEnabled = false;
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public tradingEnabled = false;

    // .05% of total supply
    uint256 private numTokensSellToAddToLiquidity = 3471006689004 * 10 ** 18;

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event InactiveWalletLiquidated(address wallet, uint256 amount);
    event WalletLiquidated(address wallet, uint256 amount);

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor(
        address _initialOwner,
        address _uniswapV2Router
    ) Ownable(_initialOwner) {
        _rOwned[_msgSender()] = _rTotal;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            _uniswapV2Router
        );
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        //Exclude liquidity pool and this contract from earning reflections
        _isExcluded[uniswapV2Pair] = true;
        _isExcluded[address(this)] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    receive() external payable {}

    function enableLiquidation(
        address[] calldata airdropAddresses
    ) external onlyOwner {
        require(!liquidationEnabled, "liquidation has already been enabled");
        liquidationEnabled = true;
        for (uint i = 0; i < airdropAddresses.length; i++) {
            _lastTransaction[airdropAddresses[i]] = block.timestamp;
        }
    }

    function liquidateInactiveWallet(address wallet) external {
        address sender = _msgSender();
        require(liquidationEnabled, "Liquidation is not yet enabled");
        require(
            !_isExcluded[wallet] && wallet != owner(),
            "Cannot liquidate excluded addresses"
        );
        require(
            !_isExcluded[sender],
            "Excluded addresses cannot call this function"
        );
        require(_lastTransaction[wallet] != 0, "Account is not active yet");
        require(
            block.timestamp - _lastTransaction[wallet] >=
                liquidationThresholdTime,
            "Account is not inactive"
        );
        uint256 walletBalance = balanceOf(wallet);
        _reflectTo(sender, walletBalance, wallet);
        emit InactiveWalletLiquidated(wallet, walletBalance);
    }

    function liquidateWalletOverThreshold(address wallet) external {
        address sender = _msgSender();
        require(liquidationEnabled, "Liquidation is not yet enabled");
        require(!_isExcluded[wallet], "Cannot liquidate excluded addresses");
        require(
            !_isExcluded[sender],
            "Excluded addresses cannot call this function"
        );
        require(
            (balanceOf(wallet) * 100) / _tTotal >= liquidationThresholdPercent,
            "Wallet does not hold enough percentage of total supply"
        );
        uint256 walletBalance = balanceOf(wallet);
        _reflectTo(sender, walletBalance, wallet);
        emit WalletLiquidated(wallet, walletBalance);
    }

    function excludeAccount(address account) external onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
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

    function setTaxFeePercent(uint256 taxFee) external onlyOwner {
        _taxFee = taxFee;
    }

    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner {
        _liquidityFee = liquidityFee;
    }

    function setLiquidationThresholdPercent(
        uint256 percent
    ) external onlyOwner {
        require(
            percent < 100 && percent >= 0,
            "must be a percent value from 0-99"
        );
        require(
            percent > liquidationThresholdPercent,
            "cannot decrease threshold"
        );
        liquidationThresholdPercent = percent;
    }

    function setLiquidationThresholdTime(uint256 time) external onlyOwner {
        require(
            time >= 1 days,
            "minimum time for account to be inactive is 1 day"
        );
        require(
            time >= liquidationThresholdTime,
            "new threshold must be larger than previous"
        );
        liquidationThresholdTime = time;
    }

    function enableTrading() external onlyOwner {
        tradingEnabled = true;
    }

    function getLastTransaction(address account) public view returns (uint256) {
        return _lastTransaction[account];
    }

    function getIntegerPercentOfSupply(
        address account
    ) public view returns (uint256) {
        return (balanceOf(account) * 100) / _tTotal;
    }

    function getFloatingPointPercentOfSupply(
        address account
    ) public view returns (uint256) {
        return (balanceOf(account) * 10000) / _tTotal;
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
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        if (liquidationEnabled) {
            _lastTransaction[_msgSender()] = block.timestamp;
            _lastTransaction[recipient] = block.timestamp;
        }
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        if (liquidationEnabled) {
            _lastTransaction[_msgSender()] = block.timestamp;
        }
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        require(
            _allowances[sender][_msgSender()] - amount >= 0,
            "ERC20: transfer amount exceeds allowance"
        );
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()] - amount
        );
        if (liquidationEnabled) {
            _lastTransaction[_msgSender()] = block.timestamp;
            _lastTransaction[recipient] = block.timestamp;
        }

        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + (addedValue)
        );
        if (liquidationEnabled) {
            _lastTransaction[_msgSender()] = block.timestamp;
        }
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        require(
            _allowances[_msgSender()][spender] - subtractedValue >= 0,
            "ERC20: decreased allowance below zero"
        );
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] - subtractedValue
        );
        if (liquidationEnabled) {
            _lastTransaction[_msgSender()] = block.timestamp;
        }
        return true;
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function reflectionFromToken(
        uint256 tAmount,
        bool deductTransferFee
    ) public view returns (uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , , ) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(
        uint256 rAmount
    ) public view returns (uint256) {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount / (currentRate);
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function reflect(uint256 tAmount) public {
        address sender = _msgSender();
        require(
            !_isExcluded[sender],
            "Excluded addresses cannot call this function"
        );
        require(
            ((balanceOf(sender) * 100) / _tTotal) < liquidationThresholdPercent,
            "Cannot reflect, account holds over 1% of supply"
        );
        (uint256 rAmount, , , , , ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rTotal = _rTotal - rAmount;
        _tFeeTotal = _tFeeTotal + (tAmount);
    }

    function _checkSenderAndLiquidate(address sender) internal {
        address _owner = owner();
        uint256 senderBalance = balanceOf(sender);
        // If sender is above 1% upon inititating transfer
        if (
            ((senderBalance * 100) / _tTotal >= liquidationThresholdPercent) &&
            sender != _owner
        ) {
            if (liquidationEnabled) {
                _reflectTo(address(this), senderBalance, sender);
                emit WalletLiquidated(sender, senderBalance);
            }
        }
    }

    function _checkRecipientAndLiquidate(address recipient) internal {
        address _owner = owner();
        uint256 recipientBalance = balanceOf(recipient);
        // If transfer puts recipient above 1%
        if (
            ((recipientBalance * 100) / _tTotal >=
                liquidationThresholdPercent) && recipient != _owner
        ) {
            if (liquidationEnabled) {
                _reflectTo(address(this), recipientBalance, recipient);
                emit WalletLiquidated(recipient, recipientBalance);
            }
        }
    }

    function _reflectTo(address sender, uint256 tAmount, address to) internal {
        (uint256 rAmount, , , , , ) = _getValues(tAmount);
        // 5% bounty fee to whoever called it. If it's the contract, the tokens are kept for liquidity
        uint256 rFee = (rAmount * 5) / 100;
        uint256 tFee = (tAmount * 5) / 100;
        uint256 rReflectionAmount = rAmount - rFee;
        require(
            rFee + rReflectionAmount == rAmount,
            "rfee and rReflection do not sum to rAmount"
        );
        // Liquidate wallet
        _rOwned[to] = _rOwned[to] - rAmount;
        // Give function caller their bounty if sender is excluded, it is this contract
        if (sender == address(this)) {
            _takeLiquidity(tFee);
        } else {
            _rOwned[sender] = _rOwned[sender] + rFee;
            emit Transfer(to, sender, tFee);
        }
        //Reflect the rest
        _rTotal = _rTotal - rReflectionAmount;
        _tFeeTotal = _tFeeTotal + (tAmount);
    }

    function removeAllFee() private {
        if (_taxFee == 0 && _liquidityFee == 0) return;

        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;

        _taxFee = 0;
        _liquidityFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        if (!tradingEnabled) {
            require(
                _isExcludedFromFee[sender] == true,
                "Trading is not yet enabled, once presale is finished it will open"
            );
        }
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >=
            numTokensSellToAddToLiquidity;

        if (
            overMinTokenBalance &&
            sender != uniswapV2Pair &&
            !inSwapAndLiquify &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            swapAndLiquify(contractTokenBalance);
        }

        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
            takeFee = false;
        }

        _tokenTransfer(sender, recipient, amount, takeFee);
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();

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

        if (!takeFee) restoreAllFee();
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidityFee
        ) = _getValues(tAmount);

        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + (rTransferAmount);
        _takeLiquidity(tLiquidityFee);
        _reflectFee(rFee, tFee);
        _checkSenderAndLiquidate(sender);
        _checkRecipientAndLiquidate(recipient);

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidityFee
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _tOwned[recipient] = _tOwned[recipient] + (tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient] + (rTransferAmount);
        _takeLiquidity(tLiquidityFee);
        _checkSenderAndLiquidate(sender);
        _reflectFee(rFee, tFee);

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidityFee
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + (rTransferAmount);

        _takeLiquidity(tLiquidityFee);
        _reflectFee(rFee, tFee);
        _checkRecipientAndLiquidate(recipient);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidityFee
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _tOwned[recipient] = _tOwned[recipient] + (tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient] + (rTransferAmount);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal - rFee;
        _tFeeTotal = _tFeeTotal + (tFee);
    }

    function _getValues(
        uint256 tAmount
    )
        private
        view
        returns (uint256, uint256, uint256, uint256, uint256, uint256)
    {
        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidityFee
        ) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            currentRate,
            tLiquidityFee
        );
        return (
            rAmount,
            rTransferAmount,
            rFee,
            tTransferAmount,
            tFee,
            tLiquidityFee
        );
    }

    function _getTValues(
        uint256 tAmount
    ) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidityFee = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount - tFee - tLiquidityFee;

        return (tTransferAmount, tFee, tLiquidityFee);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 currentRate,
        uint256 tLiquidity
    ) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount * (currentRate);
        uint256 rFee = tFee * (currentRate);
        uint256 rLiquidity = tLiquidity * currentRate;
        uint256 rTransferAmount = rAmount - rFee - rLiquidity;
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / (tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply = rSupply - _rOwned[_excluded[i]];
            tSupply = tSupply - _tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal / (_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity * currentRate;
        _rOwned[address(this)] = _rOwned[address(this)] + rLiquidity;
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)] + tLiquidity;
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return (_amount * _taxFee) / (10 ** 2);
    }

    function calculateLiquidityFee(
        uint256 _amount
    ) private view returns (uint256) {
        return (_amount * _liquidityFee) / (10 ** 2);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance / 2;
        uint256 otherHalf = contractTokenBalance - half;

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance - initialBalance;
        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }
}