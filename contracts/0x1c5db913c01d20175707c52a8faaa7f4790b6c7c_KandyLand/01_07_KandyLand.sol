// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";



interface IFactory {
    // This function creates a new liquidity pair for the two tokens provided. 
    // It returns the address of the created pair.
    function createPair(address tokenA, address tokenB) external returns (address pair);
    
    // This function retrieves the liquidity pair for the two provided tokens.
    // If the pair does not exist, it returns the zero address.
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

// This function returns the address of the Factory contract.
interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    // This function adds liquidity to a specific ERC20/ETH pair.
    // It returns the amounts of the ERC20 token and ETH added, and the amount of liquidity tokens minted.
    function addLiquidityETH(
            address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline
            ) external payable returns (
                uint256 amountToken, uint256 amountETH, uint256 liquidity
                );
    
    // This function swaps a specific amount of an ERC20 token for ETH.
    // It supports tokens that implement a transfer fee in their transfer function.
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
            uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline
            ) external;
}



contract KandyLand is IERC20, Ownable {
    IRouter public uniswapV2Router;
    address public uniswapV2Pair;
    string private constant _name =  "Lolli"; //
    string private constant _symbol = "lli";
    uint8 private constant _decimals = 18;
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private constant _totalSupply = 1000000000 * 10**18;               // 1 Billion
    uint256 public constant maxWalletAmount = _totalSupply * 2 / 100;         // 2%
    mapping (address => bool) private _isExcludedFromMaxWalletLimit;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isWhitelisted;
    uint8 public buyTax = 3;
    uint8 public sellTax = 3;
    uint8 public LPRatio = 3;
    uint8 public MarketingRatio = 1;
    uint8 public NFTLiquidityRatio = 1;
    uint8 public DevRatio = 1;
    address public constant deadWallet = 0x000000000000000000000000000000000000dEaD;
    address public constant MarketingWallet = payable(0x0e7d87DD4554269FbaCE37E3fe8beC66BA13922d);
    address public constant DevTeamWallet = payable(0xaAd1EA1BAC089f537faB4B24bABbD67851aa2F98);
    address public constant NFTLiquidityWallet = payable(0xBdA361a6479dde1357d09eEff0D25150AF5599c0);
    bool private tradingIsOpen = false;

    constructor() {
        IRouter _uniswapV2Router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IFactory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[MarketingWallet] = true;
        _isExcludedFromFee[NFTLiquidityWallet] = true;
        _isExcludedFromFee[DevTeamWallet] = true;
        _isExcludedFromFee[deadWallet] = true;
        _isExcludedFromMaxWalletLimit[owner()] = true;
        _isExcludedFromMaxWalletLimit[address(uniswapV2Router)] = true;
        _isExcludedFromMaxWalletLimit[uniswapV2Pair] = true;
        _isExcludedFromMaxWalletLimit[address(this)] = true;
        _isExcludedFromMaxWalletLimit[MarketingWallet] = true;
        _isExcludedFromMaxWalletLimit[DevTeamWallet] = true;
        _isExcludedFromMaxWalletLimit[NFTLiquidityWallet] = true;
        _isExcludedFromMaxWalletLimit[deadWallet] = true;
        _isWhitelisted[owner()] = true;
        balances[owner()] = _totalSupply;
        emit Transfer(address(0), owner(), _totalSupply);
    }

    receive() external payable {} // so the contract can receive eth

    function openTrading() external onlyOwner {
        require(!tradingIsOpen, "trading is already open");   
        tradingIsOpen = true;
    }

    function setFees(uint8 newBuyTax, uint8 newSellTax) external onlyOwner {
        require(newBuyTax <= 9 && newSellTax <= 9, "fees must be <=9%");
        require(newBuyTax != buyTax || newSellTax != sellTax, "new fees cannot be the same as old fees");
        buyTax = newBuyTax;
        sellTax = newSellTax;
    }

    function addWhitelist(address newAddress) external onlyOwner {
        require(!_isWhitelisted[newAddress], "address already added");
        _isWhitelisted[newAddress] = true;
    }

    function setRatios(uint8 newLPRatio, uint8 newMarketingRatio, uint8 newNFTLiquidityRatio, uint8 newDevRatio) external onlyOwner {
    require(newLPRatio + newMarketingRatio + newNFTLiquidityRatio + newDevRatio == buyTax + sellTax, "ratios must add up to total tax");
    LPRatio = newLPRatio;
    MarketingRatio = newMarketingRatio;
    NFTLiquidityRatio = newNFTLiquidityRatio;
    DevRatio = newDevRatio;
}

    function excludeFromMaxWalletLimit(address account) external onlyOwner {
        require(!_isExcludedFromMaxWalletLimit[account], "address is already excluded from max wallet");
        _isExcludedFromMaxWalletLimit[account] = true;
    }

    function excludeFromFees(address account) external onlyOwner {
        require(!_isExcludedFromFee[account], "address is already excluded from fees");
        _isExcludedFromFee[account] = true;
    }

    function withdrawStuckETH() external onlyOwner {
        require(address(this).balance > 0, "cannot send more than contract balance");
        (bool success,) = address(owner()).call{value: address(this).balance}("");
        require(success, "error withdrawing ETH from contract");
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender,address recipient,uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        require(amount <= _allowances[sender][msg.sender], "ERC20: transfer amount exceeds allowance.");
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool){
        _approve(msg.sender,spender,_allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        require(subtractedValue <= _allowances[msg.sender][spender], "ERC20: decreased allownace below zero.");
        _approve(msg.sender,spender,_allowances[msg.sender][spender] - subtractedValue);
        return true;
    }

    function _approve(address owner, address spender,uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
    }

    function name() external pure returns (string memory) { return _name; }
    function symbol() external pure returns (string memory) { return _symbol; }
    function decimals() external view virtual returns (uint8) { return _decimals; }
    function totalSupply() external pure override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view override returns (uint256) { return balances[account]; }
    function allowance(address owner, address spender) external view override returns (uint256) { return _allowances[owner][spender]; }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "cannot transfer from the zero address");
        require(to != address(0), "cannot transfer to the zero address");
        require(amount > 0, "transfer amount must be greater than zero");
        require(amount <= balanceOf(from), "cannot transfer more than balance"); 
        require(tradingIsOpen || _isWhitelisted[to] || _isWhitelisted[from], "trading is not open yet");
        require(_isExcludedFromMaxWalletLimit[to] || balanceOf(to) + amount <= maxWalletAmount, "cannot exceed maxWalletAmount");
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to] || (from != uniswapV2Pair && to != uniswapV2Pair)) {
    balances[from] -= amount;
    balances[to] += amount;
    emit Transfer(from, to, amount);
} else {
    balances[from] -= amount;
    if (from == uniswapV2Pair) { // buy
        if (buyTax > 0) { 
            balances[address(this)] += amount * buyTax / 100;
            emit Transfer(from, address(this), amount * buyTax / 100);
        }
        balances[to] += amount - (amount * buyTax / 100);
        emit Transfer(from, to, amount - (amount * buyTax / 100));
    } else { // sell
        if (sellTax > 0) {
            balances[address(this)] += amount * sellTax / 100;         
            emit Transfer(from, address(this), amount * sellTax / 100); 
            if (balanceOf(address(this)) > _totalSupply / 4000) { // .025% threshold for swapping
                uint256 tokensForLp = balanceOf(address(this)) * LPRatio / (LPRatio + MarketingRatio + NFTLiquidityRatio + DevRatio) / 2;
                _swapTokensForETH(balanceOf(address(this)) - tokensForLp);
                bool success = false;
                if (LPRatio > 0) { 
                    _addLiquidity(tokensForLp, address(this).balance * LPRatio / (LPRatio + MarketingRatio + NFTLiquidityRatio + DevRatio), deadWallet); 
                }
                if (MarketingRatio > 0) { 
                    (success,) = MarketingWallet.call{value: address(this).balance * MarketingRatio / (MarketingRatio + NFTLiquidityRatio + DevRatio), gas: 30000}(""); 
                }
                if (NFTLiquidityRatio > 0) { 
                    (success,) = NFTLiquidityWallet.call{value: address(this).balance * NFTLiquidityRatio / (NFTLiquidityRatio + DevRatio), gas: 30000}(""); 
                }
                if (DevRatio > 0) { 
                    (success,) = DevTeamWallet.call{value: address(this).balance, gas: 30000}(""); 
                }
            }
        }
        balances[to] += amount - (amount * sellTax / 100);
        emit Transfer(from, to, amount - (amount * sellTax / 100));
    }
}

    }

    function _swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount, address lpRecipient) private {
		_approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(address(this), tokenAmount, 0, 0, lpRecipient, block.timestamp);
    }
}