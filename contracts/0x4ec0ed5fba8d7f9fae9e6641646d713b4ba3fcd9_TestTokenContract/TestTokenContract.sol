/**
 *Submitted for verification at Etherscan.io on 2023-10-05
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

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
}

contract Test is IERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name = "Artificial General Intelligence";
    string private _symbol = "AGI";

    constructor() {
        _totalSupply = 420 * 10**12 * 10**18; // 420 trillion tokens
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
    return 18;
}

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "Transfer amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance - amount);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer amount exceeds balance");

        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract TestTokenContract is Test, Ownable { 
    uint256 public buyTaxRate = 69; 
    uint256 public sellTaxRate = 69;
    uint256 public accumulatedTax = 0;

    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;

    constructor() {
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    }

    function setPairAddress(address _pairAddress) external onlyOwner {
        uniswapV2Pair = _pairAddress;
    }

    function setBuyTaxRate(uint256 newTaxRate) external onlyOwner {
        require(newTaxRate >= 0 && newTaxRate <= 100, "Invalid tax rate");
        buyTaxRate = newTaxRate;
    }

    function setSellTaxRate(uint256 newTaxRate) external onlyOwner {
        require(newTaxRate >= 0 && newTaxRate <= 100, "Invalid tax rate");
        sellTaxRate = newTaxRate;
    }

    uint256 public liquidityThreshold = 1e6 * 1e18;  // Example: 1 million AGI

    function setLiquidityThreshold(uint256 newThreshold) external onlyOwner {
        liquidityThreshold = newThreshold;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        uint256 taxAmount;
        
        if (sender == uniswapV2Pair) {  // Buy operation
            taxAmount = (buyTaxRate * amount) / 100;
        } else {  // For sells and other transfers
            taxAmount = (sellTaxRate * amount) / 100;
        }

        accumulatedTax += taxAmount;
        amount -= taxAmount;
        super._transfer(sender, recipient, amount);

        // Check if accumulated tax exceeds the threshold
        if (accumulatedTax >= liquidityThreshold) {
            autoAddLiquidity();
        }
    }

    function autoAddLiquidity() internal {
        uint256 halfTax = accumulatedTax / 2;
        uint256 otherHalfTax = accumulatedTax - halfTax;

        // Approve token transfer to cover all scenarios
        _approve(address(this), address(uniswapV2Router), accumulatedTax);

        // Convert half of the tokens to ETH
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        // Before swapping, determine the expected ETH amount
        uint256[] memory amountsOut = uniswapV2Router.getAmountsOut(halfTax, path);
        uint256 expectedETHAmount = amountsOut[1];

        // Convert half of the tokens to ETH
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
        halfTax,
        halfTax - (halfTax / 200), // Minimum amount of ETH based on 0.5% slippage
        path,
        address(this),
        block.timestamp
);

        // Add liquidity using the exact ETH amount
        uniswapV2Router.addLiquidityETH{value: expectedETHAmount}(
        address(this),
        otherHalfTax,
        otherHalfTax - (otherHalfTax / 200), // Minimum amount of tokens based on 0.5% slippage
        expectedETHAmount - (expectedETHAmount / 200), // Minimum amount of ETH based on 0.5% slippage
        owner(),
        block.timestamp
);

        accumulatedTax = 0;
    }

    function withdrawAccumulatedTax() external onlyOwner {
        uint256 amount = accumulatedTax;
        accumulatedTax = 0;
        _transfer(address(this), msg.sender, amount);
    }
}