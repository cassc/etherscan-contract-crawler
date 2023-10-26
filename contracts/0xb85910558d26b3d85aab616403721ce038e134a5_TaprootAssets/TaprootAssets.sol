/**
 *Submitted for verification at Etherscan.io on 2023-10-19
*/

// SPDX-License-Identifier: MIT

/*

------------------------------------------------------------------------------------

Web：http://taprootassets.vip    
Telegram：https://t.me/Taproot_Assets  
Twitter：https://twitter.com/Taproot_Assets

thank you https://twitter.com/lightning  Technical support for the team
-------------------------------------------------------------------------------------
*/    
pragma solidity ^0.8.20;

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

contract TaprootAssets is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private isExcludedFromFee;
    mapping(address => uint256) private holderLastTransferTimestamp;
    bool public transferDelayEnabled = true;
    address payable private marketingWallet;

    struct Taxes {
        uint256 buy;
        uint256 sell;
    }
    Taxes public launchTax;
    Taxes public finalTax;
    Taxes public reduceTaxAt;
    uint256 private buyCount=0;

    string private constant _name = unicode"Taproot Assets";
    string private constant _symbol = unicode"Taproot";
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 100_000_000_000_000 * 10**_decimals;
    uint256 public taxSwapThreshold = _totalSupply.mul(2).div(10000);
    uint256 public maxTaxSwap = _totalSupply.mul(1).div(100);

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private inSwap = false;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () {
        marketingWallet = payable(_msgSender());
        launchTax = Taxes(18, 25);
        finalTax = Taxes(2, 2);
        reduceTaxAt = Taxes(25, 30);
        _balances[_msgSender()] = _totalSupply;
        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[marketingWallet] = true;

        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _totalSupply);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
 
        emit Transfer(address(0), _msgSender(), _totalSupply);
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
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (isExcludedFromFee[from] || isExcludedFromFee[to]) {
            _balances[from] = _balances[from].sub(amount);
            _balances[to] = _balances[to].add(amount);
            emit Transfer(from, to, amount);
            return;
        }
        uint256 taxAmount = amount.mul((buyCount>reduceTaxAt.buy)?finalTax.buy:launchTax.buy).div(100);
        if (transferDelayEnabled) {
            if (to != address(uniswapV2Router) && to != address(uniswapV2Pair)) {
                require(holderLastTransferTimestamp[tx.origin] < block.number,
                    "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed."
                );
                holderLastTransferTimestamp[tx.origin] = block.number;
            }
        }
        
        if (from == uniswapV2Pair && to != address(uniswapV2Router)) {
            buyCount++;
        }

        if (to == uniswapV2Pair && from != address(this)){
            taxAmount = amount.mul((buyCount>reduceTaxAt.sell)?finalTax.sell:launchTax.sell).div(100);
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        if (!inSwap && to == uniswapV2Pair && contractTokenBalance>taxSwapThreshold && buyCount>reduceTaxAt.sell) {
            swapTokensForEth(min(amount,min(contractTokenBalance,maxTaxSwap)));
            uint256 contractETHBalance = address(this).balance;
            if(contractETHBalance > 0) {
                sendETHToFee(address(this).balance);
            }
        }

        if (taxAmount > 0) {
          _balances[address(this)]=_balances[address(this)].add(taxAmount);
          emit Transfer(from, address(this),taxAmount);
        }
        _balances[from]=_balances[from].sub(amount);
        _balances[to]=_balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }


    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

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
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(isExcludedFromFee[account] != excluded,"Account is already the value of 'excluded'");
        isExcludedFromFee[account] = excluded;
    }

    function removeLimits() external onlyOwner{
        transferDelayEnabled = false;
    }

    function sendETHToFee(uint256 amount) private {
        marketingWallet.transfer(amount);
    }

    receive() external payable {}
}