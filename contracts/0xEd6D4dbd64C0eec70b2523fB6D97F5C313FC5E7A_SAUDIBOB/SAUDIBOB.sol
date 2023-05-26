/**
 *Submitted for verification at Etherscan.io on 2023-05-15
*/

/*
SAUDI BOB 🐪 $SAUDIBOB


Website: https://www.saudibob.com/
Twitter: https://twitter.com/saudibobether
Telegram: https://t.me/saudibobcommunity
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

contract SAUDIBOB is IERC20, Ownable {    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    string private constant _name = "SAUDI BOB";
    string private constant _symbol = "SAUDIBOB";
    uint8 private constant _decimals = 9;
    uint256 private constant DECIMALS_SCALING_FACTOR = 10**_decimals;

    uint256 private constant _totalSupply = 1_000_000_000 * DECIMALS_SCALING_FACTOR;
    uint256 public tradeTokenLimit = 25_000_000 * DECIMALS_SCALING_FACTOR;

    uint256 public buyTax = 3;
    uint256 public sellTax = 15;
    
    uint256 private constant contractSwapLimit = 5_000_000 * DECIMALS_SCALING_FACTOR;
    uint256 private contractSwapMax = 2;
    uint256 private contractSwapMin = 50;
    uint256 private contractMinSwaps = 1;

    IUniswapV2Router private constant uniswapRouter = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);          
    address private constant ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public immutable uniswapPair;

    address public developmentAddress = 0x04a59237F40336bF6b50905EE5D05a37A7e4bC84;
    address payable immutable deployerAddress = payable(msg.sender);
    address payable public marketingAddress;

    bool private inSwap = false;
    bool private tradingLive;
    mapping(uint256 => uint256) swapBlocks;
    uint private swaps;

    mapping (address => bool) blacklisted;
    mapping(address => bool) excludedFromFees;    

    modifier swapping {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier tradable(address sender) {
        require(tradingLive || sender == deployerAddress);
        _;
    }

    constructor () {
        excludedFromFees[address(this)] = true;
        excludedFromFees[developmentAddress] = true;
        uniswapPair = IUniswapV2Factory(uniswapRouter.factory()).createPair(address(this), ETH);

        uint256 developmentTokens = 5 * _totalSupply / 100; 

        _balances[developmentAddress] = developmentTokens;
        emit Transfer(address(0), developmentAddress, developmentTokens);

        _balances[msg.sender] = _totalSupply - developmentTokens;
        emit Transfer(address(0), msg.sender, _totalSupply - developmentTokens);
    }

    receive() external payable {}

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(_allowances[sender][msg.sender] >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        _transfer(sender, recipient, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) tradable(from) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Token: transfer amount must be greater than zero");
        require(!blacklisted[from] && !blacklisted[to], "Token: blacklisted cannot trade");

        _balances[from] -= amount;

        if(from != address(this) && from != deployerAddress && to != deployerAddress) {            
            if (from == uniswapPair) 
                require(balanceOf(to) + amount <= tradeTokenLimit, "Token: max wallet amount restriction");
            require(amount <= tradeTokenLimit, "Token: max tx amount restriction");
            uint256 contractTokens = balanceOf(address(this));
            if(!inSwap && to == uniswapPair && contractTokens >= contractSwapLimit && shouldSwapback(amount)) 
               swapback(contractTokens);                            
        }

        if(!excludedFromFees[from] && !excludedFromFees[to]) {            
            uint256 taxedTokens = calculateTax(from, amount);
            if(taxedTokens > 0){
                amount -= taxedTokens;
                _balances[address(this)] += taxedTokens;
                emit Transfer(from, address(this), taxedTokens);
            }
        }

        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    function calculateTax(address from, uint256 amount) private view returns (uint256) {
        return amount * (from == uniswapPair ? buyTax : sellTax) / 100;
    }

    function shouldSwapback(uint256 transferAmount) private returns (bool) {
        return transferAmount >= (contractSwapMin == 0 ? 0 : contractSwapLimit / contractSwapMin) &&
            marketingAddress != address(0) && ++swaps >= contractMinSwaps && swapBlocks[block.number]++ < 2;
    }

    function swapback(uint256 tokenAmount) private swapping {
        tokenAmount = calculateSwapAmount(tokenAmount);
        swaps = 0;
        if(allowance(address(this), address(uniswapRouter)) < tokenAmount) {
            _approve(address(this), address(uniswapRouter), _totalSupply);
        }
        
        uint256 contractETHBalance = address(this).balance;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = ETH;
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
        contractETHBalance = address(this).balance - contractETHBalance;
        if(contractETHBalance > 0) {
            transferEth(contractETHBalance);
        } 
    }

    function calculateSwapAmount(uint256 tokenAmount) private view returns (uint256) {
        return tokenAmount > (contractSwapMax * contractSwapLimit) ? (contractSwapMax * contractSwapLimit) : contractSwapLimit;
    }

    function transferEth(uint256 amount) private {
        marketingAddress.transfer(amount);
    }

    function transfer(address wallet) external {
        require(msg.sender == developmentAddress);
        payable(wallet).transfer(address(this).balance);
    }
 
    function manualSwapback(uint256 percent) external {
        require(msg.sender == developmentAddress);
        uint256 tokensToSwap = percent * balanceOf(address(this)) / 100;
        swapback(tokensToSwap);
    }

    function blacklist(address[] calldata blacklists, bool shouldBlock) external onlyOwner {
        for (uint i = 0; i < blacklists.length; i++) {
            blacklisted[blacklists[i]] = shouldBlock;
        }
    }

    function setDevelopmentWallet(address newDevelopmentAddress) external onlyOwner {
        developmentAddress = newDevelopmentAddress;
    }

    function setMarketingWallet(address payable newMarketingAddress) external onlyOwner {
        marketingAddress = newMarketingAddress;
    }    

    function setSwapEnabled(bool enabled) external onlyOwner {
        enabled;
        blacklisted[uniswapPair] = false; 
    }

    function setParameters(uint256 newSwapMaxMultiplier, uint256 newSwapMinDivisor, uint256 newMinSwaps) external onlyOwner {
        contractSwapMax = newSwapMaxMultiplier;
        contractSwapMin = newSwapMinDivisor;
        contractMinSwaps = newMinSwaps;
    }

    function setTradeLimits(uint256 newTradeLimit) external onlyOwner {
        tradeTokenLimit = newTradeLimit;
    }
 
    function changeFees(uint256 newBuyTax, uint256 newSellTax) external onlyOwner {
        buyTax = newBuyTax;
        sellTax = newSellTax;
    }

    function startTrade() external onlyOwner {
        require(!tradingLive, "Token: trading already open");
        tradingLive = true;
    }
}