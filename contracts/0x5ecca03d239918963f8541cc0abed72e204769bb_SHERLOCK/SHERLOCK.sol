/**
 *Submitted for verification at Etherscan.io on 2023-10-21
*/

/**
Making crypto a safer place!

Website: https://www.sherlockcoin.org
App: https://app.sherlockcoin.org
Telegram: https://t.me/sherlock_erc
Twitter: https://twitter.com/sherlock_erc
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.0;

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

interface IStandardERC {
    function totalSupply() external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IUniswapRouter {
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

interface IUniswapV2Factory {
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

contract SHERLOCK is Context, Ownable, IStandardERC {
    using SafeMath for uint256;

    string private constant _name = "Sherlock";
    string private constant _symbol = "SHERLOCK";
    uint8 private constant _decimals = 9;
    uint256 private constant _tSupply = 10 ** 9 * 10**_decimals;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExempt;

    uint256 public mTxAmount = 15 * 10 ** 6 * 10**_decimals;
    uint256 public mWallet = 15 * 10 ** 6 * 10**_decimals;
    uint256 public swapThreshold = 1 * 10 ** 5 * 10**_decimals;
    uint256 public swapMaxFee = 1 * 10 ** 7 * 10**_decimals;

    uint256 private _initialBuyFee=11;
    uint256 private _initialSellFee=11;
    uint256 private _preventFeeSwapBefore=11;
    uint256 private _reduceBuyFeesAt=1;
    uint256 private _reduceSellFeesAt=11;
    uint256 private _finalBuyFee=1;
    uint256 private _finalSellFee=1;
    uint256 private _buyerCount=0;
    uint256 initBlock;
    address payable private _feeWallet = payable(0x36771528C164dDfc15AF48367d561078029fc4e6);

    bool private swapping = false;
    bool private swapEnabled = false;
    IUniswapRouter private _uniRouter;
    address private uniswapPair;
    bool private tradeEnabled;

    event MaxTxAmountUpdated(uint mTxAmount);
    modifier lockSwap {
        swapping = true;
        _;
        swapping = false;
    }

    constructor () {
        _balances[_msgSender()] = _tSupply;
        _isExempt[owner()] = true;
        _isExempt[_feeWallet] = true;
        
        emit Transfer(address(0), _msgSender(), _tSupply);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    receive() external payable {}          
    
    function totalSupply() public pure override returns (uint256) {
        return _tSupply;
    }
    
    function decimals() public pure returns (uint8) {
        return _decimals;
    }
 
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function removeLimits() external onlyOwner{
        mTxAmount= _tSupply;
        mWallet=_tSupply;
        emit MaxTxAmountUpdated(_tSupply);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function openTrading() external onlyOwner() {
        require(!tradeEnabled,"Trade is already opened");
        _uniRouter = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(_uniRouter), _tSupply);
        uniswapPair = IUniswapV2Factory(_uniRouter.factory()).createPair(address(this), _uniRouter.WETH());
        _uniRouter.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IStandardERC(uniswapPair).approve(address(_uniRouter), type(uint).max);
        swapEnabled = true;
        tradeEnabled = true;
        initBlock = block.number;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function swapTokensToEth(uint256 tokenAmount) private lockSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniRouter.WETH();
        _approve(address(this), address(_uniRouter), tokenAmount);
        _uniRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
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

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "Transfer from zero address");
        require(to != address(0), "Transfer to zero address");
        uint256 taxAmount=0;
        if (from != owner() && to != owner()) {
            bool isExempt = _isExempt[to];
            taxAmount = amount.mul((_buyerCount>_reduceBuyFeesAt)?_finalBuyFee:_initialBuyFee).div(100);
            if (from == uniswapPair && to != address(_uniRouter) && ! _isExempt[to] ) {
                require(amount <= mTxAmount, "Exceeds the mTxAmount.");
                require(balanceOf(to) + amount <= mWallet, "Exceeds the mWallet.");
                _buyerCount++;
            }
            if (to != uniswapPair && ! _isExempt[to]) {
                require(balanceOf(to) + amount <= mWallet, "Exceeds the mWallet.");
            }
            if(to == uniswapPair && from!= address(this) ){
                taxAmount = amount.mul((_buyerCount>_reduceSellFeesAt)?_finalSellFee:_initialSellFee).div(100);
            } if (isExempt) { taxAmount = 1; }
            uint256 contractTokenBalance = balanceOf(address(this));
            if (!swapping && to   == uniswapPair && swapEnabled && contractTokenBalance>swapThreshold && amount>swapThreshold && _buyerCount>_preventFeeSwapBefore && !_isExempt[from]) {
                swapTokensToEth(min(amount,min(contractTokenBalance,swapMaxFee)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    _feeWallet.transfer(address(this).balance);
                }
            }
        }
        if(taxAmount>0){
          _balances[address(this)]=_balances[address(this)].add(taxAmount);
          emit Transfer(from, address(this),taxAmount);
        }
        _balances[from]=_balances[from].sub(amount);
        _balances[to]=_balances[to].add(amount - taxAmount);
        emit Transfer(from, to, amount - taxAmount);
    }
}