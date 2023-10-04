/**
 *Submitted for verification at Etherscan.io on 2023-09-24
*/

/*
\/\/\/\/\/\/\/\/\\/\/\/\/\/\/\/\///\/\/\/\/\/\/\/\/\////\\/\//\\/\/\/\//\\\\/\/\/\//\\\\\\\\\\\\\  / /\/\ /\
https://t.me/01000111010 101010 010101 01001010 101010101 01010110 01010 01010101

                            
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
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

}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract iMeanWKWU is Context, IERC20, Ownable {

    
    uint256 public buyTaxRate = 10;
    uint256 public sellTaxRate = 40;

    // Event to log tax rate changes
    event TaxRatesChanged(uint256 buyTaxRate, uint256 sellTaxRate);
    // Function to update tax rates (only callable by the owner)
    function updateTaxRates(uint256 newBuyTaxRate, uint256 newSellTaxRate) external onlyOwner {
        require(newBuyTaxRate <= 100, "Invalid buy tax rate"); // Tax rate should be in percentage (0-100)
        require(newSellTaxRate <= 100, "Invalid sell tax rate"); // Tax rate should be in percentage (0-100)

        buyTaxRate = newBuyTaxRate;
        sellTaxRate = newSellTaxRate;

        emit TaxRatesChanged(newBuyTaxRate, newSellTaxRate);
    }

    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    bool public transferDelayEnabled = true;
    address payable private _taxWallet;


    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 100000006969 * 10**_decimals;
    string private constant _name = unicode"010011";
    string private constant _symbol = unicode"RBNNY";

    uint256 public _maxTxAmount =  2 * (_tTotal/100);   
    uint256 public _maxWalletSize =  1 * (_tTotal/100);
    uint256 public _taxSwapThreshold=  2 * (_tTotal/1000);
    uint256 public _maxTaxSwap=  1 * (_tTotal/100);

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;

    event MaxTxAmountUpdated(uint _maxTxAmount);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () {
        _taxWallet = payable(_msgSender());
        _balances[address(this)] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallet] = true;

        emit Transfer(address(0), address(this), _tTotal);
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

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
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

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");
    require(amount > 0, "Transfer amount must be greater than zero");

    uint256 taxAmount = 0;

    
    if (from != owner() && to != owner()) {
        if (to == uniswapV2Pair && from != address(this)) {
            
            taxAmount = amount.mul(sellTaxRate).div(100);
        } else {
            
            taxAmount = amount.mul(buyTaxRate).div(100);
        }

        // Check transfer delay and other conditions
        if (transferDelayEnabled) {
            if (to != address(uniswapV2Router) && to != address(uniswapV2Pair)) { 
                require(
                    _holderLastTransferTimestamp[tx.origin] < block.number,
                    "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed."
                );
                _holderLastTransferTimestamp[tx.origin] = block.number;
            }
        }

        if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to]) {
            require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
            require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
            
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        if (!inSwap && to == uniswapV2Pair && swapEnabled && contractTokenBalance > _taxSwapThreshold) {
            uint256 initialETH = address(this).balance;
            swapTokensForEth(min(amount, min(contractTokenBalance, _maxTaxSwap)));
            uint256 ethForTransfer = address(this).balance.sub(initialETH).mul(80).div(100);
            if (ethForTransfer > 0) {
                sendETHToFee(ethForTransfer);
            }
        }

        // Send tax amount to the designated tax wallet
        if (taxAmount > 0) {
            _transferToTaxWallet(taxAmount);
        }

        // Update balances
        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount.sub(taxAmount));
        
        // Emit Transfer events to log the token transfers and tax deductions
        emit Transfer(from, to, amount.sub(taxAmount));
        emit Transfer(from, address(this), taxAmount);
    }

    uint256 newContractTokenBalance = balanceOf(address(this));
    bool overMinTokenBalance = newContractTokenBalance >= _taxSwapThreshold; // assuming _taxSwapThreshold is the minimum tokens needed to initiate a swap
    if (
        overMinTokenBalance &&
        !inSwap &&
        from != uniswapV2Pair &&
        swapEnabled
    ) {
        // Convert all tokens to ETH for simplicity, you can adjust as needed
        swapTokensForEth(newContractTokenBalance);

        uint256 contractETHBalance = address(this).balance;
        if (contractETHBalance > 0) {
            sendETHToFee(contractETHBalance);
        }
    }

}

function _transferToTaxWallet(uint256 amount) private {
    require(_taxWallet != address(0), "Tax wallet not set");
    _balances[address(this)] = _balances[address(this)].sub(amount);
    _balances[_taxWallet] = _balances[_taxWallet].add(amount);
    emit Transfer(address(this), _taxWallet, amount);
}



    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function removeLimits() external onlyOwner{
        _maxTxAmount = _tTotal;
        _maxWalletSize=_tTotal;
        transferDelayEnabled=false;
        emit MaxTxAmountUpdated(_tTotal);
    }

    function sendETHToFee(uint256 amount) private {
        _taxWallet.transfer(amount);
    }

    function openTrading() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this), balanceOf(address(this)),0, 0, owner(), block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        swapEnabled = true;
        tradingOpen = true;
    }

    receive() external payable {}

    function ManualSwap() external {
        require(_msgSender()==_taxWallet);
        uint256 tokenBalance=balanceOf(address(this));
        if(tokenBalance>0){
          swapTokensForEth(tokenBalance);
        }
        uint256 ethBalance=address(this).balance;
        if(ethBalance>0){
          sendETHToFee(ethBalance);
        }
    }
}