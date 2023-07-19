// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

/*
    MEGAMOON
    $MEGAM

    Website: https://megamooncoin.com/
    Twitter: https://twitter.com/MEGAMOON_eth
    Telegram: https://t.me/MEGAMOON_eth
 */

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IDynamicThresholdOracle.sol";

contract MegaMoon is IERC20, Ownable {
    using Address for address payable;
 
    mapping (address => uint) private _rOwned;
    mapping (address => uint) private _tOwned;
    mapping (address => mapping (address => uint)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
 
    address[] private _excluded;
 
    bool public swapEnabled;
    bool private swapping;
    bool public tradingEnabled;
 
    IUniswapV2Router02 public router;
    IDynamicThresholdOracle public oracle;
    address public pair;
    address public buybackWallet;
    address public marketingWallet;
 
    uint8 private constant _decimals = 18;
    uint private constant MAX = ~uint(0);
 
    uint private _tTotal = 1_000_000_000 * 10**_decimals;
    uint private _rTotal = (MAX - (MAX % _tTotal));
 
    uint public totalRfi;
    uint public swapThreshold = 2 * _tTotal / 1000; // 0.2%
    uint public maxTxAmount = 10 * _tTotal / 1000; // 1.0%
    uint public maxWalletAmount = 20 * _tTotal / 1000; // 2.0%
    uint public staticBuyThreshold = _tTotal / 1000; // 0.1%
    uint public startBlock;
    uint public offlineBlocks = 5;
 
    uint public buyTax = 150; // 15% during offline blocks
    uint public sellTax = 150; // 15% max sell tax
    uint public dynamicTax = 30; // 3% -> 0%, 3%, 6%, 9%, 12%, 15%
    uint public maxSellTax = 150; // 15%
 
    string private constant _name = "MEGAMOON";
    string private constant _symbol = "MEGAM";
 
    struct TaxesPercentage {
        uint rfi;
        uint buyback;
        uint marketing;
    }
 
    TaxesPercentage public taxesPercentage = TaxesPercentage(40, 40, 20);
 
    struct valuesFromGetValues {
        uint rAmount;
        uint rTransferAmount;
        uint rRfi;
        uint rSwap;
        uint tTransferAmount;
        uint tRfi;
        uint tSwap;
    }
 
    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }

    modifier onlyOwnerOrOracle {
        require(
            msg.sender == owner() ||
            msg.sender == address(oracle), 
            "Only the owner or oracle can make this call!"
        );
        _;
    }
 
    constructor (
        address _routerAddress, 
        address _buybackWallet, 
        address _marketingWallet
    ) {
        IUniswapV2Router02 _router = IUniswapV2Router02(_routerAddress);
        address _pair = IUniswapV2Factory(_router.factory())
            .createPair(address(this), _router.WETH());
 
        router = _router;
        pair = _pair;
 
        excludeFromReward(pair);
        excludeFromReward(address(0xdead));
 
        _rOwned[msg.sender] = _rTotal;
        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[address(0xdead)] = true;
        _isExcludedFromFee[_marketingWallet]=true;
        _isExcludedFromFee[_buybackWallet] = true;
 
        marketingWallet = _marketingWallet;
        buybackWallet = _buybackWallet;
 
        emit Transfer(address(0), msg.sender, _tTotal);
    }
 
    function name() public pure returns (string memory) {
        return _name;
    }
    function symbol() public pure returns (string memory) {
        return _symbol;
    }
    function decimals() public pure returns (uint8) {
        return _decimals;
    }
 
    function totalSupply() public view override returns (uint) {
        return _tTotal;
    }
 
    function balanceOf(address account) public view override returns (uint) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }
 
    function transfer(address recipient, uint amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
 
    function allowance(address owner, address spender) public view override returns (uint) {
        return _allowances[owner][spender];
    }
 
    function approve(address spender, uint amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
 
    function transferFrom(address sender, address recipient, uint amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
 
        uint currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);
 
        return true;
    }
 
    function increaseAllowance(address spender, uint addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
 
    function decreaseAllowance(address spender, uint subtractedValue) public virtual returns (bool) {
        uint currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
 
        return true;
    }
 
    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }
 
    function tokenFromReflection(uint rAmount) public view returns(uint) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint currentRate =  _getRate();
        return rAmount / currentRate;
    }
 
    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }
 
    function includeInReward(address account) external onlyOwner {
        require(_isExcluded[account], "Account is not excluded");
        for (uint i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }
 
    function excludeFromFee(address account, bool status) public onlyOwner {
        _isExcludedFromFee[account] = status;
    }
 
    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function buyThreshold() public view returns (uint) {
        return address(oracle) != address(0x0) ? oracle.getBuyThreshold() : staticBuyThreshold;
    }
 
    function _reflectRfi(uint rRfi, uint tRfi) private {
        _rTotal -= rRfi;
        totalRfi += tRfi;
    }
 
    function _takeSwapFees(uint rValue, uint tValue) private {
        if (_isExcluded[address(this)])
        {
            _tOwned[address(this)]+= tValue;
        }

        _rOwned[address(this)] += rValue;
    }
 
    function _getValues(uint tAmount, bool takeFee, bool isSell) private view returns (valuesFromGetValues memory to_return) {
        to_return = _getTValues(tAmount, takeFee, isSell);
        (to_return.rAmount, to_return.rTransferAmount, to_return.rRfi, to_return.rSwap) = _getRValues(to_return, tAmount, takeFee, _getRate());

        return to_return;
    }
 
    function _getTValues(uint tAmount, bool takeFee, bool isSell) private view returns (valuesFromGetValues memory s) {
        if (!takeFee) {
            s.tTransferAmount = tAmount;
            return s;
        }
 
        uint tempTax = isSell ? sellTax : buyTax;
        uint rfiTax = tempTax * taxesPercentage.rfi / 100;
        uint swapTax = tempTax * (100 - taxesPercentage.rfi) / 100;
        s.tRfi = tAmount * rfiTax / 1000;
        s.tSwap = tAmount * swapTax / 1000;
        s.tTransferAmount = tAmount - s.tRfi - s.tSwap;

        return s;
    }
 
    function _getRValues(valuesFromGetValues memory s, uint tAmount, bool takeFee, uint currentRate) private pure returns (uint rAmount, uint rTransferAmount, uint rRfi, uint rSwap) {
        rAmount = tAmount*currentRate;
 
        if (!takeFee) {
            return (rAmount, rAmount, 0, 0);
        }
 
        rRfi = s.tRfi * currentRate;
        rSwap = s.tSwap * currentRate;
        rTransferAmount = rAmount - rRfi - rSwap;

        return (rAmount, rTransferAmount, rRfi, rSwap);
    }
 
    function _getRate() private view returns (uint) {
        (uint rSupply, uint tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }
 
    function _getCurrentSupply() private view returns (uint, uint) {
        uint rSupply = _rTotal;
        uint tSupply = _tTotal;
        for (uint i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply-_rOwned[_excluded[i]];
            tSupply = tSupply-_tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
 
    function _approve(address owner, address spender, uint amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
 
    function _transfer(address from, address to, uint amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= balanceOf(from), "You are trying to transfer more than your balance");
 
        if (buyTax != 0 && tradingEnabled) {
            if (startBlock + offlineBlocks < block.number) buyTax = 0;
        }
 
        bool takeFee = false;
 
        if (!_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            require(tradingEnabled, "Liquidity has not been added yet");
            require(amount <= maxTxAmount, "You are exceeding maxTxAmount");
            if (to != pair) require(balanceOf(to) + amount <= maxWalletAmount, "You are exceeding maxWalletAmount");

            takeFee = true;

            if (from == pair && startBlock + offlineBlocks < block.number) {
                takeFee = false;

                if (amount >= buyThreshold()) {
                    if (sellTax >= dynamicTax) sellTax -= dynamicTax;
                    else sellTax = 0;
                }
            }
        }
 
        bool canSwap = balanceOf(address(this)) >= swapThreshold;
        if (!swapping && swapEnabled && canSwap && from != pair && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            swapTokensForFees(swapThreshold);
        }
 
        _tokenTransfer(from, to, amount, takeFee);
    }

    function _tokenTransfer(address sender, address recipient, uint tAmount, bool takeFee) private {
        bool isSell = recipient == pair ? true : false;
        valuesFromGetValues memory s = _getValues(tAmount, takeFee, isSell);
 
        if (isSell && takeFee && startBlock + offlineBlocks < block.number) {
            if (sellTax + dynamicTax > maxSellTax) sellTax = maxSellTax;
            else sellTax += dynamicTax;
        }

        if (_isExcluded[sender] ) {
            _tOwned[sender] = _tOwned[sender] - tAmount;
        }
        if (_isExcluded[recipient]) {
            _tOwned[recipient] = _tOwned[recipient] + s.tTransferAmount;
        }
 
        _rOwned[sender] = _rOwned[sender] - s.rAmount;
        _rOwned[recipient] = _rOwned[recipient] + s.rTransferAmount;
 
        if (s.rRfi > 0 || s.tRfi > 0) _reflectRfi(s.rRfi, s.tRfi);
        if (s.rSwap > 0 || s.tSwap > 0) _takeSwapFees(s.rSwap, s.tSwap);
 
        emit Transfer(sender, recipient, s.tTransferAmount);
        emit Transfer(sender, address(this), s.tSwap);
 
    }
 
    function swapTokensForFees(uint tokens) private lockTheSwap {
        uint initialBalance = address(this).balance;
        swapTokensForETH(tokens);
        uint deltaBalance = address(this).balance - initialBalance;
 
        uint totalPercent = 100 - taxesPercentage.rfi;
        if (totalPercent == 0) return;
 
        uint marketingAmount = deltaBalance * taxesPercentage.marketing / totalPercent;
        if (marketingAmount > 0) payable(marketingWallet).sendValue(marketingAmount);
 
        uint buybackAmount = deltaBalance - marketingAmount;
        if (buybackAmount > 0) payable(buybackWallet).sendValue(buybackAmount);
    }
 
    function swapTokensForETH(uint tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
 
        _approve(address(this), address(router), tokenAmount);
 
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
 
    function enableTrading() external onlyOwner {
        tradingEnabled = true;
        swapEnabled = true;
        startBlock = block.number;
    }

    function updateOracle(address newOracle) external onlyOwnerOrOracle {
        oracle = IDynamicThresholdOracle(newOracle);
    }
 
    function updateMarketingWallet(address newWallet) external onlyOwner {
        marketingWallet = newWallet;
        _isExcludedFromFee[marketingWallet] = true;
    }
 
    function updateBuybackWallet(address newWallet) external onlyOwner {
        buybackWallet = newWallet;
        _isExcludedFromFee[buybackWallet] = true;
    }

    function setTaxesPercentage(uint _rfi, uint _buyback, uint _marketing) external onlyOwner {
        require(_rfi + _buyback + _marketing == 100, "Total must be 100");
        taxesPercentage = TaxesPercentage(_rfi, _buyback, _marketing);
    }
 
    function updateThreshold(uint amount) external onlyOwner {
        staticBuyThreshold = amount * 10**_decimals;
    }
 
    function updateMaxTxAmount(uint amount) external onlyOwner {
        maxTxAmount = amount * 10**_decimals;
    }
 
    function updateMaxWallet(uint amount) external onlyOwner {
        maxWalletAmount = amount * 10**_decimals;
    }
 
    function updateSwapThreshold(uint amount) external onlyOwner {
        swapThreshold = amount * 10**_decimals;
    }
 
    function updateSwapEnabled(bool _enabled) external onlyOwner {
        swapEnabled = _enabled;
    }
 
    function updatePair(address newRouter, address newPair) external onlyOwner {
        router = IUniswapV2Router02(newRouter);
        pair = newPair;
    }
 
    function updateDynamicTax(uint amount) external onlyOwner {
        dynamicTax = amount;
    }
 
    function updateMaxSellTax(uint amount) external onlyOwner {
        maxSellTax = amount;
    }
 
    function rescueETH() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
 
    function rescueTokens(address _token) external onlyOwner {
        require(_token != address(this), "Can not rescue own token!");
        IERC20(_token).transfer(owner(), IERC20(_token).balanceOf(address(this)));
    }

    function distributeAirdrop(address[] calldata recipients, uint[] calldata amounts) external onlyOwner {
        require(recipients.length == amounts.length, "Error in arrays!");
        for (uint256 i = 0; i < recipients.length; i++) {
            _transfer(_msgSender(), recipients[i], amounts[i] * 10**_decimals);
        }
    }
 
    receive() external payable {}
}