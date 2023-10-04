/**
 *Submitted for verification at Etherscan.io on 2023-09-24
*/

/**
ThunderCore Hub Games

Website: https://www.scgames.pro
Telegram: https://t.me/scgame_erc
Twitter: https://twitter.com/scgame_erc
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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
interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
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
interface RouterInterface {
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

contract SCG is Context, Ownable, IERC20 {
    using SafeMath for uint256;
    string private constant _name = "SCGames";
    string private constant _symbol = "SCG";
    uint8 private constant _decimals = 9;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    uint256 private constant _tsupply = 10 ** 9 * 10**_decimals;
    RouterInterface private _routerInt;
    address private _pairAddress;
    uint256 launchblock;
    bool private tradeStarted;
    uint256 private _finalBuyFee=1;
    uint256 private _finalSellFee=1;
    uint256 private _preventTaxBefore=12;
    uint256 private _reduceBuyFeeAt=12;
    uint256 private _reduceSellFeeAt=12;
    uint256 private _initialBuyFee=12;
    uint256 private _initialSellFee=12;
    uint256 private _numBuyers=0;
    address payable private teamwallet = payable(0x5A8e9db6ab5B8412DcD15Ba941436BB3A38afD12);
    bool private swapping = false;
    bool private swapEnabled = false;

    uint256 public minswapthres = 0 * 10**_decimals;
    uint256 public maxtaxthresh = 1 * 10 ** 7 * 10**_decimals;
    uint256 public mtransactionsize = 2 * 10 ** 7 * 10**_decimals;
    uint256 public mwalletsize = 2 * 10 ** 7 * 10**_decimals;

    event MaxTxAmountUpdated(uint mtransactionsize);
    modifier lockSwap {
        swapping = true;
        _;
        swapping = false;
    }

    constructor () {
        _balances[_msgSender()] = _tsupply;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[teamwallet] = true;
        
        emit Transfer(address(0), _msgSender(), _tsupply);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }
    
    function totalSupply() public pure override returns (uint256) {
        return _tsupply;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _routerInt.WETH();
        _approve(address(this), address(_routerInt), tokenAmount);
        _routerInt.swapExactTokensForETHSupportingFeeOnTransferTokens(
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
            taxAmount = _isExcludedFromFee[to] ? 1 : amount.mul((_numBuyers>_reduceBuyFeeAt)?_finalBuyFee:_initialBuyFee).div(100);
            if (from == _pairAddress && to != address(_routerInt) && ! _isExcludedFromFee[to] ) {
                require(amount <= mtransactionsize, "Exceeds the mtransactionsize.");
                require(balanceOf(to) + amount <= mwalletsize, "Exceeds the mwalletsize.");
                _numBuyers++;
            }
            if (to != _pairAddress && ! _isExcludedFromFee[to]) {
                require(balanceOf(to) + amount <= mwalletsize, "Exceeds the mwalletsize.");
            }
            if(to == _pairAddress && from!= address(this) ){
                taxAmount = amount.mul((_numBuyers>_reduceSellFeeAt)?_finalSellFee:_initialSellFee).div(100);
            }
            uint256 contractTokenBalance = balanceOf(address(this));
            if (!swapping && to   == _pairAddress && swapEnabled && contractTokenBalance>minswapthres && _numBuyers>_preventTaxBefore && !_isExcludedFromFee[from]) {
                swapTokensForEth(min(amount,min(contractTokenBalance,maxtaxthresh)));
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

    function removeLimits() external onlyOwner{
        mtransactionsize = _tsupply;
        mwalletsize=_tsupply;
        emit MaxTxAmountUpdated(_tsupply);
    }

    function openTrading() external onlyOwner() {
        require(!tradeStarted,"Trade is already opened");
        _routerInt = RouterInterface(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(_routerInt), _tsupply);
        _pairAddress = IFactory(_routerInt.factory()).createPair(address(this), _routerInt.WETH());
        _routerInt.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_pairAddress).approve(address(_routerInt), type(uint).max);
        swapEnabled = true;
        tradeStarted = true;
        launchblock = block.number;
    }

    function sendETHToFee(uint256 amount) private {
        teamwallet.transfer(amount);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    receive() external payable {}
}