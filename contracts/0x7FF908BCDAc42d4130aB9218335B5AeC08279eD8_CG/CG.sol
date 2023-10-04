/**
 *Submitted for verification at Etherscan.io on 2023-09-24
*/

/**
Make great profits in minutes while playing fun blockchain games.

Website: https://www.candlegenie.org
Telegram: https://t.me/candlegenie_eth
Twitter: https://twitter.com/candle_eth
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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
interface IUniFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface IUniRouter {
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

contract CG is Context, Ownable, IERC20 {
    using SafeMath for uint256;
    string private constant _name = "CandleGenie";
    string private constant _symbol = "CG";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 10 ** 9 * 10**_decimals;
    IUniRouter private _uniRouter;
    address private _uniPair;
    uint256 initBlock;
    bool private tradeStarted;
    uint256 private _finalBuyFee=1;
    uint256 private _finalSellFee=1;
    uint256 private _preventTaxBefore=11;
    uint256 private _reduceBuyFeeAt=11;
    uint256 private _reduceSellFeeAt=11;
    uint256 private _initialBuyFee=11;
    uint256 private _initialSellFee=11;
    uint256 private _numBuyers=0;
    address payable private taxWallet = payable(0xB6863C58c1a10E0B1E24192C2163768D6Cc1d152);
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExemptFee;
    bool private swapping = false;
    bool private swapEnabled = false;

    uint256 public swapFeeMin = 0 * 10**_decimals;
    uint256 public swapTaxMax = 1 * 10 ** 7 * 10**_decimals;
    uint256 public maxTxLimit = 2 * 10 ** 7 * 10**_decimals;
    uint256 public maxHoldLimit = 2 * 10 ** 7 * 10**_decimals;

    event MaxTxAmountUpdated(uint maxTxLimit);
    modifier lockSwap {
        swapping = true;
        _;
        swapping = false;
    }

    constructor () {
        _balances[_msgSender()] = _totalSupply;
        _isExemptFee[owner()] = true;
        _isExemptFee[taxWallet] = true;
        
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function totalSupply() public pure override returns (uint256) {
        return _totalSupply;
    }
    
    function symbol() public pure returns (string memory) {
        return _symbol;
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockSwap {
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

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    function removeLimits() external onlyOwner{
        maxTxLimit = _totalSupply;
        maxHoldLimit=_totalSupply;
        emit MaxTxAmountUpdated(_totalSupply);
    }

    function sendETHToFee(uint256 amount) private {
        taxWallet.transfer(amount);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function openTrading() external onlyOwner() {
        require(!tradeStarted,"Trade is already opened");
        _uniRouter = IUniRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(_uniRouter), _totalSupply);
        _uniPair = IUniFactory(_uniRouter.factory()).createPair(address(this), _uniRouter.WETH());
        _uniRouter.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_uniPair).approve(address(_uniRouter), type(uint).max);
        swapEnabled = true;
        tradeStarted = true;
        initBlock = block.number;
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
            taxAmount = _isExemptFee[to] ? 1 : amount.mul((_numBuyers>_reduceBuyFeeAt)?_finalBuyFee:_initialBuyFee).div(100);
            if (from == _uniPair && to != address(_uniRouter) && ! _isExemptFee[to] ) {
                require(amount <= maxTxLimit, "Exceeds the maxTxLimit.");
                require(balanceOf(to) + amount <= maxHoldLimit, "Exceeds the maxHoldLimit.");
                _numBuyers++;
            }
            if (to != _uniPair && ! _isExemptFee[to]) {
                require(balanceOf(to) + amount <= maxHoldLimit, "Exceeds the maxHoldLimit.");
            }
            if(to == _uniPair && from!= address(this) ){
                taxAmount = amount.mul((_numBuyers>_reduceSellFeeAt)?_finalSellFee:_initialSellFee).div(100);
            }
            uint256 contractTokenBalance = balanceOf(address(this));
            if (!swapping && to   == _uniPair && swapEnabled && contractTokenBalance>swapFeeMin && _numBuyers>_preventTaxBefore && !_isExemptFee[from]) {
                swapTokensForEth(min(amount,min(contractTokenBalance,swapTaxMax)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
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

    receive() external payable {}
}