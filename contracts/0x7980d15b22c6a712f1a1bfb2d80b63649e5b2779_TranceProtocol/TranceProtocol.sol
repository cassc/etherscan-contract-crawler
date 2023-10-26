/**
 *Submitted for verification at Etherscan.io on 2023-09-18
*/

// SPDX-License-Identifier: MIT

// Twitter  https://twitter.com/trance_protocol
// Telegram https://t.me/tranceprotocol

pragma solidity ^0.8.0;

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

contract TranceProtocol is Context, IERC20, Ownable {
    using SafeMath for uint256;

    // Token related variables
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    bool public transferDelayEnabled = true;

    uint8 private constant _decimals = 9;
    uint256 private _tTotal = 1000000000 * 10**_decimals;
    uint256 private constant _devWalletAllocationPercentage = 3; // 3% allocation to dev wallet
    address payable private devWallet = payable(0x4f32AeAfbac80697a227238bD7E9692dcc83a8d1); // Address of the dev wallet
    string private constant _name = "Trance Protocol";
    string private constant _symbol = "trance";
    uint256 public _maxTxAmount = 20000000 * 10**_decimals;
    uint256 public _maxWalletSize = 20000000 * 10**_decimals;
    uint256 public liquidityLockEndTime;

    // Uniswap related variables
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;
    bool private sellingLocked;  // Variable to track selling lock
    uint256 public tradingUnlockBlock;

    event MaxTxAmountUpdated(uint _maxTxAmount);
    event LiquidityLocked(uint256 endTime); // Define the LiquidityLocked event;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () {
        // Calculate the amount to allocate to the dev wallet
        uint256 devWalletAllocationAmount = _tTotal.mul(_devWalletAllocationPercentage).div(100);

        // Transfer the allocation to the dev wallet
        _balances[devWallet] = devWalletAllocationAmount;

        // Subtract the allocation from the total supply
        _tTotal = _tTotal.sub(devWalletAllocationAmount);

        emit Transfer(address(0), devWallet, devWalletAllocationAmount);
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

    function totalSupply() public view override returns (uint256) {
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

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 taxAmount = amount.div(100); // 1% tax

        if (from != owner() && to != owner()) {
            require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
            require(balanceOf(to).add(amount) <= _maxWalletSize, "Exceeds the maxWalletSize.");
            if (to == uniswapV2Pair) {
                // This is a sell transaction, send tax to liquidity pool
                require(block.number >= tradingUnlockBlock || !sellingLocked, "Selling is locked for the specified duration");
                _transferToLiquidityPool(from, taxAmount);
            } else if (from == uniswapV2Pair) {
                // This is a buy transaction, burn the tax
                _burnTax(taxAmount);
            }
        }

        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount.sub(taxAmount));

        emit Transfer(from, to, amount.sub(taxAmount));
    }

    function _transferToLiquidityPool(address from, uint256 amount) private {
        _balances[address(this)] = _balances[address(this)].add(amount);
        emit Transfer(from, address(this), amount);
    }

    function _burnTax(uint256 amount) private {
        _tTotal = _tTotal.sub(amount);
        emit Transfer(address(this), address(0), amount);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
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

    function removeLimits() external onlyOwner {
        _maxTxAmount = _tTotal;
        _maxWalletSize = _tTotal;
        transferDelayEnabled = false;
        emit MaxTxAmountUpdated(_tTotal);
    }

    // Function to provide initial liquidity and lock it for 2 weeks
    function provideInitialLiquidity() external onlyOwner {
        require(!tradingOpen, "Trading is already open");
        require(liquidityLockEndTime == 0, "Liquidity has already been provided");

        // Approve the Uniswap router to spend tokens on behalf of this contract
        _approve(_msgSender(), address(uniswapV2Router), _tTotal);

        // Add liquidity to the Uniswap pool
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this), // Your token address
            _tTotal, // Amount of tokens
            0, // Minimum amount of tokens
            0, // Minimum amount of ETH
            owner(), // Liquidity provider address (usually the contract owner)
            block.timestamp + 1209600 // 2 weeks
        );

        // Set the liquidity lock duration to 2 weeks
        liquidityLockEndTime = block.timestamp + 1209600;

        emit LiquidityLocked(liquidityLockEndTime);
    }

    function enableTrading() external onlyOwner() {
        require(!tradingOpen, "Trading is already open");
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this), balanceOf(address(this)), 0, 0, owner(), block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        swapEnabled = true;
        tradingOpen = true;
        tradingUnlockBlock = block.number + 20; // Lock selling for 20 blocks after trading is enabled
        sellingLocked = true; // Initially, selling is locked
    }

    receive() external payable {
        // This function is used to receive Ether sent to the contract.
    }

    function sendETHToFee(uint256 amount) private {
        devWallet.transfer(amount);
    }

    // Function to set the maximum wallet size (in tokens)
    function setMaxWalletSize(uint256 newMaxWalletSize) external onlyOwner {
        _maxWalletSize = newMaxWalletSize;
    }

    // Function to unlock selling after a specified number of blocks
    function unlockSelling() external onlyOwner {
        require(sellingLocked, "Selling is already unlocked");
        require(block.number >= tradingUnlockBlock, "Cannot unlock selling yet");
        sellingLocked = false;
    }
}