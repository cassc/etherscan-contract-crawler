// SPDX-License-Identifier: MIT

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
    event TokensMoved(uint256 amount);
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

contract SPACEMESH is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    bool private _inSwap = false;
    mapping (address => uint256) private _holderLastTransferTimestamp;
    
    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 1000000000 * 10**_decimals;
    string private constant _name = unicode"Spacemesh";
    string private constant _symbol = unicode"SMH";
    uint256 public _maxTxAmount = _tTotal.mul(3).div(100); // 3% of total supply intially
    uint256 public _maxWalletSize = _tTotal.mul(3).div(100); // 3% of total supply intially

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
    _balances[owner()] = _tTotal;
    emit Transfer(address(0), owner(), _tTotal);  
    
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
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private swapLock {

    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");
    require(amount > 0, "Transfer amount must be greater than zero");

    require(tradingOpen || (from == owner() && to == address(this)) || to == uniswapV2Pair, "Trading is not open yet");

    require(
    _balances[to].add(amount) <= _maxWalletSize || 
    (from == owner() && to == address(this)) || 
    to == uniswapV2Pair || 
    (from == address(this) && (to == owner() || to == uniswapV2Pair)), 
    "New balance would exceed the max wallet size.");

    require(amount <= _balances[from], "Transfer amount exceeds balance");

    require(_balances[from] >= amount, "ERC20: transfer amount exceeds balance");
    require(_balances[to] + amount > _balances[to], "ERC20: addition overflow");

    // Update balances
    _balances[from] = _balances[from].sub(amount);
    _balances[to] = _balances[to].add(amount);
    emit Transfer(from, to, amount);
}

function removeLimits() external onlyOwner {
        _maxTxAmount = _tTotal; // remove transaction limits
        _maxWalletSize = _tTotal; // remove wallet limits
        emit MaxTxAmountUpdated(_tTotal);
}

function manualSend() external onlyOwner {
    uint256 contractBalance = address(this).balance;
    require(contractBalance > 0, "Contract has no ETH to send");
    payable(owner()).transfer(contractBalance);
}

function checkBalanceAndAllowance() public view returns (uint256, uint256) {
    uint256 contractBalance = balanceOf(address(this));
    uint256 routerAllowance = allowance(address(this), address(uniswapV2Router));
    return (contractBalance, routerAllowance);
}

function addLiquidity() external onlyOwner() {
    require(!tradingOpen, "Trading is already open");

    uint256 contractTokenBalance = balanceOf(address(this));
    uint256 contractEthBalance = address(this).balance;

   // Check that the contract has enough tokens
    require(contractTokenBalance > 0, "Contract has no tokens to add as liquidity");
    
    // Check that the contract has enough ETH
    require(contractEthBalance > 0, "Contract has no ETH to add as liquidity");
 
   uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

  // create the pair on uniswop
    uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
 
   // Approve the router to spend the tokens of this contract
    _approve(address(this), address(uniswapV2Router), contractTokenBalance);

    // Check that the router is approved to spend the tokens
    require(allowance(address(this), address(uniswapV2Router)) >= contractTokenBalance, "Router is not approved to spend tokens");

    // Temporarily remove max wallet size while adding liquidity
    uint256 initialMaxWalletSize = _maxWalletSize;
    _maxWalletSize = _tTotal;

    // Temporarily set status to true to bypass wallet size while adding liquidity
    _inSwap = true;

    // Add liquidity using the balance of tokens in the contract
    uniswapV2Router.addLiquidityETH{value: contractEthBalance}(address(this), contractTokenBalance, 0, 0, owner(), block.timestamp);

  // Enable the swap
    _inSwap = false;

    // Restore max wallet size
    _maxWalletSize = initialMaxWalletSize;

    IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint256).max);

    // Open trading after adding liquidity
    tradingOpen = true;
}

// this transfers the minted tokens into the contract from the owners wallet
function moveTokens(uint256 newPercentage) external onlyOwner() {
    require(newPercentage <= 100, "Percentage cannot be greater than 100");

    uint256 amountToMove = _tTotal.mul(newPercentage).div(100); // Use the newPercentage variable
    _transfer(owner(), address(this), amountToMove);
    emit TokensMoved(amountToMove);
}

    receive() external payable {}
}