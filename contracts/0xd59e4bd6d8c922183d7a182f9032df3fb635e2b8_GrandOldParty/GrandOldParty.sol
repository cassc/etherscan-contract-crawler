/**
 *Submitted for verification at Etherscan.io on 2023-06-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

// Telegram: https://t.me/GOP_ERC
// Twitter: @GOP_ERC
// Website: www.goperc.xyz

/*
* We stand with the Republican party and will always support its candidate.
* Taxes will be used exclusively for marketing purposes and to support the GOP candidate
* when the US elections come, whoever is the candidate.
* This is your chance to support the only party that cares about freedom. FIGHT FOR FREEDOM
* Liquidity locked for 1 month at the start, locked for 100 years at 200k Mcap.
*/

interface IUniswapV2Router02 {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract GrandOldParty is IERC20 {
    string public constant name = "Grand Old Party";
    string public constant symbol = "$GOP";
    uint8 public constant decimals = 18;
    uint256 private constant _totalSupply = 1000000000 * 10**uint256(decimals);
    uint256 public taxPercentage = 5;
    address payable public taxWallet;
    address private _owner;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only the contract owner can call this function");
        _;
    }

    constructor() {
        _owner = msg.sender;
        _balances[msg.sender] = _totalSupply;
        taxWallet = payable(0xa5950791bC240683db45fC51673044d8526a8a0c); // Set the tax wallet address
    }

    function totalSupply() external pure override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
        return true;
    }

    function setTaxPercentage(uint256 percentage) external onlyOwner {
        require(percentage <= 100, "Tax percentage must be less than or equal to 100");
        taxPercentage = percentage;
    }

    function setTaxWallet(address payable wallet) external onlyOwner {
        taxWallet = wallet;
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(_balances[sender] >= amount, "Insufficient balance");

        uint256 taxAmount = amount * taxPercentage / 100;
        uint256 transferAmount = amount - taxAmount;

        _balances[sender] -= amount;
        _balances[recipient] += transferAmount;
        _balances[taxWallet] += taxAmount;

        emit Transfer(sender, recipient, transferAmount);
        emit Transfer(sender, taxWallet, taxAmount);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // Function to create a Uniswap V2 liquidity pool
    function createUniswapV2Pool(address uniswapRouter) external onlyOwner {
        require(uniswapRouter != address(0), "Invalid Uniswap router address");

        IUniswapV2Router02 router = IUniswapV2Router02(uniswapRouter);

        // Approve the router to spend the tokens
        _approve(address(this), uniswapRouter, _totalSupply);

        // Swap half of the tokens for ETH
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _totalSupply / 2,
            0,
            path,
            address(this),
            block.timestamp
        );

        // Add liquidity to the Uniswap pool
        uint256 balanceETH = address(this).balance;
        router.addLiquidityETH{value: balanceETH}(
            address(this),
            _totalSupply / 2,
            0,
            0,
            address(this),
            block.timestamp
        );

        // Burn the remaining tokens
        _balances[address(this)] = 0;
        emit Transfer(address(this), address(0), _totalSupply / 2);
    }
}