/**
 *Submitted for verification at Etherscan.io on 2023-08-27
*/

/**

✅Telegram:

✅Twitter:

✅Website:

*/

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
    event Approval (address indexed owner, address indexed spender, uint256 value);
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
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

contract Token is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool public tradingEnabled = false;
    bool private inSwap = false;
    bool private swapEnabled = false;
    uint256 _triggerAmountToSwap = _tTotal / 200;

    address payable private _taxWallet;

//    mapping(address => bool) public _blackList;

    //---
    uint256 public buyFees = 1;
    uint256 public sellFees = 1;

    string private constant _name = "Baby PEPE";
    string private constant _symbol = unicode"BABYPEPE";
    uint8 private constant _decimals = 18;
    uint256 private constant _tTotal = 420690000000000 * 10**_decimals;

//    uint256 public _maxWallet = _tTotal * 5 / 100;
    //---

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () {
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        _taxWallet = payable(0x63774F1067F2d5CB02da38f1E2feE63e890c11E7);

        _balances[_taxWallet] = _tTotal;
        emit Transfer(address(0), _taxWallet, _tTotal);

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[address(uniswapV2Router)] = true;
        _isExcludedFromFee[_taxWallet] = true;

        //startTrade
        tradingEnabled = true;
        swapEnabled = true;
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
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(amount > 0, "Transfer amount must be greater than zero");
//        require(!_blackList[from], "blackList");

        uint256 taxAmount = 0;
        bool txInWhiteList = (_isExcludedFromFee[from] || _isExcludedFromFee[to]);
        if (!txInWhiteList) {
            require(tradingEnabled, "Trading is not started");

            if (from == uniswapV2Pair) {
                //buy
//                require(balanceOf(to) + amount <= _maxWallet, "Exceeds the maxWalletSize."); //limit buy
                taxAmount = amount.mul(buyFees).div(100);
            }

            if (to == uniswapV2Pair ) {
                //sell
                taxAmount = amount.mul(sellFees).div(100);
            }

            if (!inSwap && to == uniswapV2Pair && swapEnabled && balanceOf(address(this)) > _triggerAmountToSwap) {
                doSwapBack(_triggerAmountToSwap);
            }
        }

        if(taxAmount > 0) {
            _balances[address(this)]=_balances[address(this)].add(taxAmount);
            emit Transfer(from, address(this),taxAmount);
        }

        _balances[from]=_balances[from].sub(amount);
        _balances[to]=_balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }

    function setTriggerAmountToSwap(uint amount) external onlyOwner {
        require(amount>0, "amount should not be zero");
        _triggerAmountToSwap = amount;
    }

    function doSwapBack(uint256 amount) private {
        bool success;
        swapTokensForEth(amount);
        (success, ) = address(_taxWallet).call{value: address(this).balance}("");
    }

/*
    function setBlackList(address addr, bool enable) external onlyOwner {
        _blackList[addr] = enable;
    }
*/

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

    function modifyBuyFees(uint256 newFee) external onlyOwner {
        require(newFee <= 100, "invalid new Fee");
        buyFees = newFee;
    }

    function modifySellFees(uint256 newFee) external onlyOwner {
        require(newFee <= 100, "invalid new Fee");
        sellFees = newFee;
    }

    /*
    function removeLimits() external onlyOwner {
//        _maxWallet =_tTotal;
        buyFees = 0;
        sellFees = 0;
        if(buyFees == 0 && sellFees ==0) {
            uint256 allLeft = balanceOf(address(this));
            doSwapBack(allLeft);
        }
    }
*/
/*
    function manualSwapBack() external {
        uint256 allLeft = balanceOf(address(this));
        doSwapBack(allLeft);
    }*/

    /*
    function startTrade() external onlyOwner() {
        tradingEnabled = true;
        swapEnabled = true;
    }
    */

    receive() external payable {}

    function setExcludedFromFee(address account, bool status) external onlyOwner {
        _isExcludedFromFee[account] = status;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

}