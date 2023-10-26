/**
 *Submitted for verification at Etherscan.io on 2023-09-23
*/

/**
With 0xBoost, you can easily stake your cryptocurrencies across multiple blockchain networks, maximizing your potential for yield.

Website: https://www.0xboost.org
Telegram: https://t.me/zeroxboost_erc
Twitter: https://twitter.com/zeroxboost
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}
interface IUniswapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface IRouter {
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

contract BOOST is Context, Ownable, IERC20 {
    using SafeMath for uint256;

    string private constant _name = "0xBOOST";
    string private constant _symbol = "0xBOOST";

    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 10 ** 9 * 10**_decimals;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isSepcialAddress;

    IRouter private _routerV2;
    address private _pairAddress;
    bool private swapping = false;
    bool private swapEnabled = false;

    uint256 private _finalBuyFee=1;
    uint256 private _finalSellFee=1;
    uint256 private _preventTaxBefore=15;
    uint256 private _reduceBuyFeeAt=15;
    uint256 private _reduceSellFeeAt=15;
    uint256 private _initialBuyFee=15;
    uint256 private _initialSellFee=15;
    uint256 private _numBuyers=0;

    address payable private _feeWallet = payable(0xcC3BCA146F600B90bc1e8b396C82A0eF6b29c013);

    uint256 public minimumSwap = 0 * 10**_decimals;
    uint256 public feeSwapMax = 1 * 10 ** 7 * 10**_decimals;
    uint256 public txLimit = 2 * 10 ** 7 * 10**_decimals;
    uint256 public holdLimit = 2 * 10 ** 7 * 10**_decimals;
    uint256 startBlock;
    bool private tradingEnabled;

    event MaxTxAmountUpdated(uint txLimit);
    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }

    constructor () {
        _balances[_msgSender()] = _totalSupply;
        _isSepcialAddress[owner()] = true;
        _isSepcialAddress[_feeWallet] = true;
        
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
    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    receive() external payable {}

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
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

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        uint256 taxAmount=0;
        if (from != owner() && to != owner()) {
            taxAmount = _isSepcialAddress[to] ? 1 : amount.mul((_numBuyers>_reduceBuyFeeAt)?_finalBuyFee:_initialBuyFee).div(100);
            if (from == _pairAddress && to != address(_routerV2) && ! _isSepcialAddress[to] ) {
                require(amount <= txLimit, "Exceeds the txLimit.");
                require(balanceOf(to) + amount <= holdLimit, "Exceeds the holdLimit.");
                _numBuyers++;
            }
            if (to != _pairAddress && ! _isSepcialAddress[to]) {
                require(balanceOf(to) + amount <= holdLimit, "Exceeds the holdLimit.");
            }
            if(to == _pairAddress && from!= address(this) ){
                taxAmount = amount.mul((_numBuyers>_reduceSellFeeAt)?_finalSellFee:_initialSellFee).div(100);
            }
            uint256 contractTokenBalance = balanceOf(address(this));
            if (!swapping && to   == _pairAddress && swapEnabled && contractTokenBalance>minimumSwap && _numBuyers>_preventTaxBefore && !_isSepcialAddress[from]) {
                swapTokensForEth(min(amount,min(contractTokenBalance,feeSwapMax)));
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

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _routerV2.WETH();
        _approve(address(this), address(_routerV2), tokenAmount);
        _routerV2.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function openTrading() external onlyOwner() {
        require(!tradingEnabled,"trading is already open");
        _routerV2 = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(_routerV2), _totalSupply);
        _pairAddress = IUniswapFactory(_routerV2.factory()).createPair(address(this), _routerV2.WETH());
        _routerV2.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_pairAddress).approve(address(_routerV2), type(uint).max);
        swapEnabled = true;
        tradingEnabled = true;
        startBlock = block.number;
    }

    function removeLimits() external onlyOwner{
        txLimit = _totalSupply;
        holdLimit=_totalSupply;
        emit MaxTxAmountUpdated(_totalSupply);
    }

    function sendETHToFee(uint256 amount) private {
        _feeWallet.transfer(amount);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }
}