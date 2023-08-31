/**
 *Submitted for verification at Etherscan.io on 2023-08-21
*/

// SPDX-License-Identifier: NONE

/** 
Website:  http://nofriends.tech/
Twitter:  twitter.com/nofriendstech
**/


pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

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

contract NOFRIENDS is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => uint256) private _holderLastTransferTimestamp;

    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 10000000 * 10**_decimals;
    string private constant _name = unicode"NOFRIENDS.TECH";
    string private constant _symbol = unicode"NOFRIENDS";
    uint256 public _maxTxAmount = _tTotal.mul(1).div(100); // 1% of total supply
    uint256 public _maxWalletSize = _tTotal.mul(1).div(100); // 1% of total supply
    uint256 public _buyTax = 20;
    uint256 public _sellTax = 20;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen=false;
    bool private inSwap = false;

    event MaxTxAmountUpdated(uint _maxTxAmount);
    modifier swapLock {
        inSwap = true;
        _;
        inSwap = false;
    }

constructor () {
    _balances[_msgSender()] = _tTotal;
    _isExcludedFromFee[owner()] = true;
    _isExcludedFromFee[address(this)] = true;

    // Mint tokens to specified wallets
    _balances[0x85d7bBa7D7d544b70Ed399c5cA5b6F9b8b2D097c] = _tTotal.mul(45).div(1000); // Dev Wallet
     emit Transfer(address(0), 0x85d7bBa7D7d544b70Ed399c5cA5b6F9b8b2D097c, _tTotal.mul(45).div(1000));

    _balances[0xa94865D8074f21b7beB4E50af895506590F0F815] = _tTotal.mul(15).div(1000); // Marketing Wallet
     emit Transfer(address(0), 0xa94865D8074f21b7beB4E50af895506590F0F815, _tTotal.mul(15).div(1000));

    _balances[0xA6E3F575AE15EA0a5faA2270Ec251E125832118A] = _tTotal.mul(15).div(1000); // Exchange Wallet
     emit Transfer(address(0), 0xA6E3F575AE15EA0a5faA2270Ec251E125832118A, _tTotal.mul(15).div(1000));

    _balances[0xfcbe83769Dc89349676289954BE0aA73aF111Cc7] = _tTotal.sub(_balances[0x85d7bBa7D7d544b70Ed399c5cA5b6F9b8b2D097c]).sub(_balances[0xa94865D8074f21b7beB4E50af895506590F0F815]).sub(_balances[0xA6E3F575AE15EA0a5faA2270Ec251E125832118A]); // Liquidity wallet
    emit Transfer(address(0), 0xfcbe83769Dc89349676289954BE0aA73aF111Cc7, _tTotal.sub(_balances[0x85d7bBa7D7d544b70Ed399c5cA5b6F9b8b2D097c]).sub(_balances[0xa94865D8074f21b7beB4E50af895506590F0F815]).sub(_balances[0xA6E3F575AE15EA0a5faA2270Ec251E125832118A]));  
    
    
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

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
    require(_balances[_msgSender()] >= amount, "ERC20: transfer amount exceeds balance");
    _transfer(_msgSender(), recipient, amount);
    return true;
}

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
    require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");
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
    
function _transfer(address from, address to, uint256 amount) private swapLock {

    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");
    require(amount > 0, "Transfer amount must be greater than zero");

       // Check if trading is open or if it's the owner depositing tokens
    require(tradingOpen || (from == owner() && to == address(this)), "Trading is not open yet");

    // Check that the recipient's balance won't exceed the max wallet size
     require(
    _balances[to].add(amount) <= _maxWalletSize || (from == owner() && to == address(this)), 
    "New balance would exceed the max wallet size."
    );

    // Calculate tax amount
    // Calculate tax amount
    uint256 taxAmount;
    if (from == uniswapV2Pair && _buyTax > 0) {
        taxAmount = amount.mul(_buyTax).div(100);
    } else if (to == uniswapV2Pair && _sellTax > 0) {
        taxAmount = amount.mul(_sellTax).div(100);
    }

    // Exclude tax when the owner is depositing tokens
    if (from == owner() && to == address(this)) {
        taxAmount = 0;
    }

    // Subtract tax from the amount
    uint256 sendAmount = amount.sub(taxAmount);

    _balances[from] = _balances[from].sub(amount);
    _balances[to] = _balances[to].add(sendAmount);
    emit Transfer(from, to, sendAmount);

    // Transfer the tax to the contract wallet
    _balances[owner()] = _balances[owner()].add(taxAmount);
    emit Transfer(from, owner(), taxAmount);

}

    function removeLimits() external onlyOwner {
        _maxTxAmount = _tTotal;
        _maxWalletSize = _tTotal;
        _buyTax = 2;
        _sellTax = 2;
        emit MaxTxAmountUpdated(_tTotal);
    }

function manualSend(uint256 amount) external onlyOwner {
    require(address(this).balance >= amount, "Not enough ETH in contract");
    require(_balances[address(this)] >= amount, "Not enough tokens in contract");
    // Transfer ETH back to the liquidity wallet (used to transfer ETH from taxes to liquidity wallet)
    payable(owner()).transfer(amount);
}

function addLiquidity() external onlyOwner() {
    require(!tradingOpen, "Trading is already open");

    uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
 
    // Get the balance of this contract
    uint256 contractBalance = balanceOf(address(this));

    // Approve the router to spend the tokens of this contract
    _approve(address(this), address(uniswapV2Router), contractBalance);

    uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

    // Add liquidity using the balance of this contract
    uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this), contractBalance, 0, 0, owner(), block.timestamp);

    IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint256).max);

}
function openTrading() external onlyOwner() {
    require(!tradingOpen, "Trading is already open");
    tradingOpen = true;
}
    receive() external payable {}
}