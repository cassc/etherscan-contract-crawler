/**
 *Submitted for verification at Etherscan.io on 2023-08-15
*/

// SPDX-License-Identifier: MIT

/*
$$$$$$$\   $$$$$$\  $$$$$$$\ $$\     $$\       $$$$$$$\  $$\      $$\   $$\ $$$$$$$$\  $$$$$$\  
$$  __$$\ $$  __$$\ $$  __$$\\$$\   $$  |      $$  __$$\ $$ |     $$ |  $$ |\__$$  __|$$  __$$\ 
$$ |  $$ |$$ /  $$ |$$ |  $$ |\$$\ $$  /       $$ |  $$ |$$ |     $$ |  $$ |   $$ |   $$ /  $$ |
$$$$$$$\ |$$$$$$$$ |$$$$$$$\ | \$$$$  /        $$$$$$$  |$$ |     $$ |  $$ |   $$ |   $$ |  $$ |
$$  __$$\ $$  __$$ |$$  __$$\   \$$  /         $$  ____/ $$ |     $$ |  $$ |   $$ |   $$ |  $$ |
$$ |  $$ |$$ |  $$ |$$ |  $$ |   $$ |          $$ |      $$ |     $$ |  $$ |   $$ |   $$ |  $$ |
$$$$$$$  |$$ |  $$ |$$$$$$$  |   $$ |          $$ |      $$$$$$$$\\$$$$$$  |   $$ |    $$$$$$  |
\_______/ \__|  \__|\_______/    \__|          \__|      \________|\______/    \__|    \______/ 

ERC20
twitter: https://twitter.com/babyplutoerc
telegram: https://t.me/BabyPlutoErc20
website: https://babyplutoerc.xyz
*/

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

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory amounts);
}

abstract contract Ownable {
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
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
// Implement Ownable in BabyPluto contract
contract BabyPluto is IERC20, Ownable {
    string public name = "Baby Pluto";
    string public symbol = "$BPLU";
    uint8 public decimals = 18;
    uint256 private _totalSupply;
    address private _owner;
    bool private _isBotProtected;

    // Addresses for the different wallets
    address public devWallet = 0x1C04777c8ed248F9837c4125349da622D2820487;
    address public marketingWallet;
    address public lpWallet;

    uint256 public baseTaxPercentage = 25; // Initial tax percentage (25%)
    uint256 public taxDecrement = 1; // The amount to decrement the tax percentage after every block

    uint256 public minTaxPercentage = 1; // Minimum tax percentage (1%)
    uint256 public transactionsCount;
    uint256 public blocksCount;

    uint256 public constant blocksPerTaxDecrement = 1; // Number of blocks per tax decrement
    uint256 public constant transactionsPerTaxDecrement = 1000; // Number of transactions per tax decrement
    uint256 public constant blocksPerMaxBuy = 50; // Number of blocks with maximum buy limit
    uint256 public constant maxBuyPercentage = 1; // Maximum buy limit as a percentage of total supply
    uint256 public constant minimumBuyAmount = 0.01 ether; // Minimum buy amount for the first 400 transactions

    uint256 public maxTaxPercentage = 30; // Maximum tax percentage (30%)

    uint256 public taxPercentageToDev;
    uint256 public taxPercentageToMarketing;
    uint256 public taxPercentageToLP;

    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    uint256 public swapCount;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor() {
        _totalSupply = 1000000000 * 10 ** uint256(decimals); // 1 billion tokens
        _balances[msg.sender] = _totalSupply;
        _owner = msg.sender;
        emit Transfer(address(0), msg.sender, _totalSupply);

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        // Set the Uniswap V2 Router
        uniswapV2Router = _uniswapV2Router;  
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
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: transfer amount must be greater than zero");
        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");

        // Check for minimum buy amount for the first 400 transactions
        if (transactionsCount < 400) {
            require(msg.sender == _owner || msg.value >= minimumBuyAmount, "Minimum buy amount not met");
        }

        // Check for maximum buy limit for the first 50 blocks
        if (blocksCount < blocksPerMaxBuy) {
            require(amount <= _totalSupply * maxBuyPercentage / 100, "Maximum buy limit exceeded");
        }

        // Calculate taxes based on current tax percentage
        uint256 taxAmountToDev = amount * taxPercentageToDev / 100;
        uint256 taxAmountToMarketing = amount * taxPercentageToMarketing / 100;
        uint256 taxAmountToLP = amount * taxPercentageToLP / 100;

        // Apply taxes
        _balances[sender] -= amount;
        _balances[recipient] += amount - (taxAmountToDev + taxAmountToMarketing + taxAmountToLP);

        // Distribute taxes
        _balances[devWallet] += (taxAmountToDev + taxAmountToMarketing + taxAmountToLP);

        transactionsCount++;
        blocksCount = block.number;

        // Update tax percentages based on transaction count
        if (transactionsCount <= transactionsPerTaxDecrement) {
            // Phase 1: Decrease tax percentage by taxDecrement after each block
            uint256 blockTaxDecrement = (baseTaxPercentage - minTaxPercentage) / transactionsPerTaxDecrement;
            taxPercentageToDev = baseTaxPercentage - (blockTaxDecrement * transactionsCount);
            taxPercentageToMarketing = taxPercentageToDev;
        } else if (transactionsCount > transactionsPerTaxDecrement && transactionsCount <= (transactionsPerTaxDecrement + 400)) {
            // Phase 2: Maintain 5/5 tax percentage for 400 transactions after reaching 5/5
            taxPercentageToDev = minTaxPercentage;
            taxPercentageToMarketing = minTaxPercentage;
        } else {
            // Phase 3: Maintain 1/1 tax percentage after 1000 transactions
            taxPercentageToDev = minTaxPercentage;
            taxPercentageToMarketing = minTaxPercentage;
        }

        // Ensure tax percentages don't exceed the maximum tax percentage
        if (taxPercentageToDev + taxPercentageToMarketing + taxPercentageToLP > maxTaxPercentage) {
            uint256 totalTaxPercentage = taxPercentageToDev + taxPercentageToMarketing + taxPercentageToLP;
            taxPercentageToDev = (taxPercentageToDev * maxTaxPercentage) / totalTaxPercentage;
            taxPercentageToMarketing = (taxPercentageToMarketing * maxTaxPercentage) / totalTaxPercentage;
            taxPercentageToLP = (taxPercentageToLP * maxTaxPercentage) / totalTaxPercentage;
        }

        // Emit Transfer events
        emit Transfer(sender, recipient, amount - (taxAmountToDev + taxAmountToMarketing + taxAmountToLP));
        emit Transfer(sender, devWallet, (taxAmountToDev + taxAmountToMarketing + taxAmountToLP));
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setBotProtection(bool isProtected) external onlyOwner {
        _isBotProtected = isProtected;
    }

    function isBotProtected() public view returns (bool) {
        return _isBotProtected;
    }

    function setMarketingWallet(address _marketingWallet) external onlyOwner {
        marketingWallet = _marketingWallet;
    }

    function setLpWallet(address _lpWallet) external onlyOwner {
        lpWallet = _lpWallet;
    }

    function renounceOwnership() external onlyOwner {
        _owner = address(0);
    }

    function swapETHForTokens(uint256 amountOutMin, address[] memory path, address to, uint256 deadline) external payable {
        require(path[0] == uniswapV2Router.WETH(), "Path must start with WETH");
        require(path[path.length - 1] == address(this), "Path must end with this contract's token");

        if (transactionsCount < 400) {
            require(msg.value >= minimumBuyAmount, "Minimum buy amount not met");
        }

        uint256[] memory amounts = uniswapV2Router.swapExactETHForTokens{value: msg.value}(amountOutMin, path, to, deadline);
        swapCount++;

        emit Transfer(address(0), msg.sender, amounts[amounts.length - 1]);
    }
}