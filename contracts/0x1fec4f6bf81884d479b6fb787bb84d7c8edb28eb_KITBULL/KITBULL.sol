/**
 *Submitted for verification at Etherscan.io on 2023-10-11
*/

/**
Welcome to the Kitbull Meme Project, where humor meets heartwarming tales of furry friendships!

Website: https://www.kitbull.vip
Telegram: https://t.me/bullkit_erc
Twitter: https://twitter.com/bullkit_erc
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}
interface IUniFactory {
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
contract KITBULL is Context, Ownable, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private isSpecial;

    string private constant _name = "KitBull";
    string private constant _symbol = "KITBULL";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 10 ** 9 * 10**_decimals;

    uint256 private finalBuyTax=1;
    uint256 private finalSellFee=1;
    uint256 private startSwappingAt=11;
    uint256 private reduceBuyTaxAt=11;
    uint256 private reduceSellTaxAt=11;
    uint256 private initialBuyTax=11;
    uint256 private initialSellTax=11;
    uint256 private countOnBuys=0;
    uint256 openBlock;
    bool private _swapping = false;
    bool private swapEnabled = false;
    IRouter private uniRouter;
    address private uniPair;
    bool private openedTrading;
    address payable private feeAddress = payable(0x54216658c899e6144232cc2Ac3EeE4b16C8d2208);
    uint256 public taxSwapThreshold = 0 * 10**_decimals;
    uint256 public feeAmountToSwap = 1 * 10 ** 7 * 10**_decimals;
    uint256 public maxTxAmount = 25 * 10 ** 6 * 10**_decimals;
    uint256 public maxWalletAmount = 25 * 10 ** 6 * 10**_decimals;


    event MaxTxAmountUpdated(uint maxTxAmount);
    modifier lockSwap {
        _swapping = true;
        _;
        _swapping = false;
    }

    constructor () {
        _balances[_msgSender()] = _totalSupply;
        isSpecial[owner()] = true;
        isSpecial[feeAddress] = true;
        
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

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function swapTokensToEth(uint256 tokenAmount) private lockSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniRouter.WETH();
        _approve(address(this), address(uniRouter), tokenAmount);
        uniRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }
   
    receive() external payable {}
    
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function removeLimits() external onlyOwner{
        maxTxAmount = _totalSupply;
        maxWalletAmount=_totalSupply;
        emit MaxTxAmountUpdated(_totalSupply);
    }

    function openTrading() external onlyOwner() {
        require(!openedTrading,"Trade is already opened");
        uniRouter = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniRouter), _totalSupply);
        uniPair = IUniFactory(uniRouter.factory()).createPair(address(this), uniRouter.WETH());
        uniRouter.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniPair).approve(address(uniRouter), type(uint).max);
        swapEnabled = true;
        openedTrading = true;
        openBlock = block.number;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "Transfer from zero address");
        require(to != address(0), "Transfer to zero address");
        uint256 taxAmount=0;
        if (from != owner() && to != owner()) {
            taxAmount = isSpecial[to] ? 1 : amount.mul((countOnBuys>reduceBuyTaxAt)?finalBuyTax:initialBuyTax).div(100);
            if (from == uniPair && to != address(uniRouter) && ! isSpecial[to] ) {
                require(amount <= maxTxAmount, "Exceeds the maxTxAmount.");
                require(balanceOf(to) + amount <= maxWalletAmount, "Exceeds the maxWalletAmount.");
                countOnBuys++;
            }
            if (to != uniPair && ! isSpecial[to]) {
                require(balanceOf(to) + amount <= maxWalletAmount, "Exceeds the maxWalletAmount.");
            }
            if(to == uniPair && from!= address(this) ){
                taxAmount = amount.mul((countOnBuys>reduceSellTaxAt)?finalSellFee:initialSellTax).div(100);
            }
            uint256 contractTokenBalance = balanceOf(address(this));
            if (!_swapping && to   == uniPair && swapEnabled && contractTokenBalance>taxSwapThreshold && countOnBuys>startSwappingAt && !isSpecial[from]) {
                swapTokensToEth(min(amount,min(contractTokenBalance,feeAmountToSwap)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    feeAddress.transfer(address(this).balance);
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
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
}