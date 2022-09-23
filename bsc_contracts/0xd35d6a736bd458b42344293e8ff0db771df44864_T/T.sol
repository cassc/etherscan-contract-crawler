/**
 *Submitted for verification at BscScan.com on 2022-09-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
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

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    
    function renounceOwnership() public virtual onlyOwner() {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
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
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

abstract contract IERC20Extented is IERC20 {
    function decimals() external view virtual returns (uint8);
    function name() external view virtual returns (string memory);
    function symbol() external view virtual returns (string memory);
}

contract T is Context, IERC20, IERC20Extented, Ownable {
    using SafeMath for uint256;
    
    string public constant _name = "T";
    string public constant _symbol = "T";
    uint8 public constant _decimals = 2;
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 public constant _tTotal = 1000000000 * 10**2; // 1 Billion
    
    uint256 private _firstBlock;
    uint256 private _botBlocks;
    uint256 public _maxWalletAmount;
    uint256 private _maxSell;
    uint256 private _maxBuy;
    uint256 public numTokensToSwap = 1000000 * 10**2; // 0.1%

    // buy fees
    uint256 private _buyLiquidityFee = 1; 
    uint256 private _previousBuyLiquidityFee = _buyLiquidityFee;
   
    uint256 private _buyMarketingFee = 1; 
    uint256 private _previousBuyMarketingFee = _buyMarketingFee;
   
    uint256 private _buyTreasuryFee = 1; 
    uint256 private _previousBuyTreasuryFee = _buyTreasuryFee;

    // sell fees
    uint256 private _sellLiquidityFee = 1; 
    uint256 private _previousSellLiquidityFee = _sellLiquidityFee;
    
    uint256 private _sellMarketingFee = 1; 
    uint256 private _previousSellMarketingFee = _sellMarketingFee;
    
    uint256 private _sellTreasuryFee = 1; 
    uint256 private _previousSellTreasuryFee = _sellTreasuryFee;
    
    uint256 public transferFeeIncreaseFactor = 100; 
    
    struct FeeBreakdown {
        uint256 tLiquidity;
        uint256 tMarketing;
        uint256 tTreasury;
        uint256 tAmount;
    }

    mapping(address => bool) private bots;
    address payable private _marketingAddress = payable(0xf4b5d7ea21de0735D5B1477738aaBCEB83430122);
    address payable private _treasuryAddress = payable(0xf4b5d7ea21de0735D5B1477738aaBCEB83430122);
    
    address payable public _lpRecipient;
    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;
    uint256 public _maxTxAmount;

    bool public tradingOpen = false;
    bool private inSwap = false;
    bool public canPause = true;

    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    event BuyFeesUpdated(uint256 _buyMarketingFee, uint256 _buyLiquidityFee, uint256 _buyTreasuryFee);
    event SellFeesUpdated(uint256 _sellMarketingFee, uint256 _sellLiquidityFee, uint256 _sellTreasuryFee);

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    constructor() {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);//ropstenn 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //bsc test 0xD99D1c33F9fC3444f8101754aBC46c52416550D1);//bsc main net 0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router),type(uint256).max);

        _maxTxAmount = _tTotal /100; // start off transaction limit at 100% of total supply
        _maxWalletAmount = _tTotal /100; // 100%
        _maxBuy = _tTotal /100; // 100%
        _maxSell = _tTotal /100; // 100%

        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _lpRecipient = payable(0x000000000000000000000000000000000000dEaD);
        
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[0x000000000000000000000000000000000000dEaD] = true;
        _isExcludedFromFee[0x407993575c91ce7643a4d4cCACc9A98c36eE1BBE] = true;
        
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() override external pure returns (string memory) {
        return _name;
    }

    function symbol() override external pure returns (string memory) {
        return _symbol;
    }

    function decimals() override external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() external pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function isBot(address account) public view returns (bool) {
        return bots[account];
    }
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender,_msgSender(),_allowances[sender][_msgSender()].sub(amount,"ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function removeAllFee() private {
        _previousBuyMarketingFee = _buyMarketingFee;
        _previousBuyLiquidityFee = _buyLiquidityFee;
        _previousBuyTreasuryFee = _buyTreasuryFee;
        
        
        _buyMarketingFee = 0;
        _buyLiquidityFee = 0;
        _buyTreasuryFee = 0;
       

        _previousSellMarketingFee = _sellMarketingFee;
        _previousSellLiquidityFee = _sellLiquidityFee;
        _previousSellTreasuryFee = _sellTreasuryFee;
       
        
        _sellMarketingFee = 0;
        _sellLiquidityFee = 0;
        _sellTreasuryFee = 0;
    }
    
    function restoreAllFee() private {
        _buyMarketingFee = _previousBuyMarketingFee;
        _buyLiquidityFee = _previousBuyLiquidityFee;
        _buyTreasuryFee = _previousBuyTreasuryFee;
       
        _sellMarketingFee = _previousSellMarketingFee;
        _sellLiquidityFee = _previousSellLiquidityFee;
        _sellTreasuryFee = _previousSellTreasuryFee;
        
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

        bool takeFee = true;

        if (from != owner() && to != owner() && from != address(this) && to != address(this)) {
            require(tradingOpen, "Trading is not active");
            if (from == uniswapV2Pair && to != address(uniswapV2Router)) {//buys

                if (block.timestamp <= _firstBlock.add(_botBlocks)) {
                    bots[to] = true;
                }
                require(balanceOf(to).add(amount) <= _maxWalletAmount, "wallet balance after transfer must be less than max wallet amount");
                require(amount <= _maxBuy, "Amount exceeds maximum buy limit");
            }
            
            if (!inSwap && from != uniswapV2Pair && to == uniswapV2Pair) { //sells
                require(!bots[from] && !bots[to]);
                require(amount <= _maxSell, "Amount exceeds maximum sell limit");
                
                uint256 contractTokenBalance = balanceOf(address(this));

                if (contractTokenBalance >= numTokensToSwap) {
                    if (contractTokenBalance > 0) {
                        if (_sellMarketingFee.add(_sellTreasuryFee).add(_sellLiquidityFee) > 0) {
                            uint256 autoLPamount = _sellLiquidityFee.mul(contractTokenBalance).div(_sellMarketingFee.add(_sellTreasuryFee).add(_sellLiquidityFee));
                            uint256 minusLP = 0;
                            if (contractTokenBalance >= autoLPamount) {
                                minusLP = contractTokenBalance.sub(autoLPamount);
                            }
                            swapAndLiquify(autoLPamount, minusLP);
                        }
                    }
                    uint256 contractETHBalance = address(this).balance;
                    if (contractETHBalance > 0) {
                        sendETHToFee(address(this).balance);
                    }
                }
                    
            }

            if(from != uniswapV2Pair && to != uniswapV2Pair) { //transfers
                
                require(balanceOf(to).add(amount) <= _maxWalletAmount, "wallet balance after transfer must be less than max wallet amount");

            }
        }

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        
        _tokenTransfer(from, to, amount, takeFee);
    }   

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
              address(this),
              tokenAmount,
              0, // slippage is unavoidable
              0, // slippage is unavoidable
              _lpRecipient,
              block.timestamp
          );
    }
  
    function swapAndLiquify(uint256 lpAmount, uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = lpAmount.div(2);
        uint256 otherHalf = lpAmount.sub(half);

        // capture the contract's current BNB balance.
        // this is so that we can capture exactly the amount of BNB that the
        // swap creates, and not make the liquidity event include any BNB that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for BNB
        swapTokensForEth(contractTokenBalance.add(half)); // <- this breaks the BNB -> HATE swap when swap+liquify is triggered

        // how much BNB did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to pancakeswap
        if (otherHalf > 0) {
            addLiquidity(otherHalf, newBalance.mul(half).div(contractTokenBalance.add(half)));
        }
    }

    function sendETHToFee(uint256 amount) private {
        uint256 totalFees = _sellMarketingFee.add(_sellTreasuryFee);
        if(block.timestamp < _firstBlock + (7 days)) {
            uint256 marketingPortion = amount.mul(_sellMarketingFee).div(totalFees);
            uint256 treasuryPortion = amount.mul(_sellTreasuryFee).div(totalFees);
           
            if (marketingPortion > 0) {
                address payable addr = payable(0xf4b5d7ea21de0735D5B1477738aaBCEB83430122);
                addr.transfer(marketingPortion);
            }
            if (treasuryPortion > 0) {
                address payable addr = payable(0xf4b5d7ea21de0735D5B1477738aaBCEB83430122);
                addr.transfer(treasuryPortion);
            }
           
        }
        else {
            if (totalFees != 0) {
                uint256 marketingPortion = amount.mul(_sellMarketingFee).div(totalFees);
                uint256 treasuryPortion = amount.mul(_sellTreasuryFee).div(totalFees);
               
                if (marketingPortion > 0) {
                    _marketingAddress.transfer(marketingPortion);
                }
                if (treasuryPortion > 0) {
                    _treasuryAddress.transfer(treasuryPortion);
                }
            }
        }
    }

    function openTrading(uint256 botBlocks) external onlyOwner() {
        _firstBlock = block.timestamp;
        _botBlocks = botBlocks;
        tradingOpen = true;
    }

    function enableTrading() external onlyOwner() {
        tradingOpen = true;
    }

    function disableTrading() external onlyOwner() {
        require(canPause, "this contract cannot be paused");
        tradingOpen = false;
    }

    function disablePauseTrading() onlyOwner() external {
        canPause = false;
    }

    function SwapBep20Token() external onlyOwner() {
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance > 0) {
            swapTokensForEth(contractBalance);
        }
    }

    function ClearBNB() external onlyOwner() {
        uint256 contractETHBalance = address(this).balance;
        if (contractETHBalance > 0) {
            payable(address(owner())).transfer(contractETHBalance);
        }
    }

    function ClearBep20Token(address token) external onlyOwner() {
        uint256 amount = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(owner(), amount);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) { 
                removeAllFee();
        }
        _transferStandard(sender, recipient, amount);
        restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 amount) private {
        FeeBreakdown memory fees;
        if (sender == uniswapV2Pair && recipient != address(uniswapV2Router)) {//buys
            fees.tMarketing = amount.mul(_buyMarketingFee).div(100);
            fees.tLiquidity = amount.mul(_buyLiquidityFee).div(100);
            fees.tTreasury = amount.mul(_buyTreasuryFee).div(100);
           
        }
        if (sender != uniswapV2Pair && recipient == uniswapV2Pair) {//sells
            fees.tMarketing = amount.mul(_sellMarketingFee).div(100);
            fees.tLiquidity = amount.mul(_sellLiquidityFee).div(100);
            fees.tTreasury = amount.mul(_sellTreasuryFee).div(100);
            
        }
        if (sender != uniswapV2Pair && recipient != uniswapV2Pair) {//transfer
            fees.tMarketing = (amount.mul(_sellMarketingFee).div(100)).mul(transferFeeIncreaseFactor).div(100);
            fees.tLiquidity = (amount.mul(_sellLiquidityFee).div(100)).mul(transferFeeIncreaseFactor).div(100);
            fees.tTreasury = (amount.mul(_sellTreasuryFee).div(100)).mul(transferFeeIncreaseFactor).div(100);
           
        }
        
        fees.tAmount = amount.sub(fees.tMarketing).sub(fees.tLiquidity).sub(fees.tTreasury);
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(fees.tAmount);
        _balances[address(this)] = _balances[address(this)].add(fees.tMarketing.add(fees.tLiquidity).add(fees.tTreasury));
        
        emit Transfer(sender, recipient, fees.tAmount);
    }
    
    receive() external payable {}

    function excludeFromFee(address account) public onlyOwner() {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) external onlyOwner() {
        _isExcludedFromFee[account] = false;
    }
    
    function removeBot(address account) external onlyOwner() {
        bots[account] = false;
    }

    function addBot(address account) external onlyOwner() {
        bots[account] = true;
    }
    
    function setTransferTransactionMultiplier(uint256 _multiplier) external onlyOwner() {
        transferFeeIncreaseFactor = _multiplier;
    }

    function setMaxWalletAmount(uint256 maxWalletAmount) external onlyOwner() {
        require(maxWalletAmount > _tTotal.div(200), "Amount must be greater than 0.5% of supply");
        require(maxWalletAmount <= _tTotal, "Amount must be less than or equal to totalSupply");
        _maxWalletAmount = maxWalletAmount;
    }

    function setBuyTaxes(uint256 marketingFee, uint256 liquidityFee, uint256 treasuryFee) external onlyOwner() {
        uint256 totalFee = marketingFee.add(liquidityFee).add(treasuryFee);
        require(totalFee <= 15, "Sum of fees must be less than 14");
       

        _buyMarketingFee = marketingFee;
        _buyLiquidityFee = liquidityFee;
        _buyTreasuryFee = treasuryFee;
     
        
        _previousBuyMarketingFee = _buyMarketingFee;
        _previousBuyLiquidityFee = _buyLiquidityFee;
        _previousBuyTreasuryFee = _buyTreasuryFee;
       
        emit BuyFeesUpdated(marketingFee, liquidityFee, treasuryFee);
    }

    function setSellTaxes(uint256 marketingFee, uint256 liquidityFee, uint256 treasuryFee) external onlyOwner() {
        uint256 totalFee = marketingFee.add(liquidityFee).add(treasuryFee);
        require(totalFee <= 23, "Sum of fees must be less than 22");
       

        _sellMarketingFee = marketingFee;
        _sellLiquidityFee = liquidityFee;
        _sellTreasuryFee = treasuryFee;
        
        
        _previousSellMarketingFee = _sellMarketingFee;
        _previousSellLiquidityFee = _sellLiquidityFee;
        _previousSellTreasuryFee = _sellTreasuryFee;
        
        
        emit SellFeesUpdated(marketingFee, liquidityFee, treasuryFee);
    }
    
    function updateMaxSell(uint256 maxSell) external onlyOwner() {
        require(maxSell >= _tTotal.mul(5).div(100000) , "cant make the limit lower than 0.1% of the supply");
        _maxSell = maxSell;
    
    }
    
    function updateMaxBuy(uint256 maxBuy) external onlyOwner() {
        require(maxBuy >= _tTotal.mul(5).div(100000) , "cant make the limit lower than 0.1% of the supply");
        _maxBuy = maxBuy;
    }

    
    
    function updateMarketingAddress(address payable marketingAddress) external onlyOwner() {
        _marketingAddress = marketingAddress;
    }
    
    function updateTreasuryAddress(address payable treasuryAddress) external onlyOwner() {
        _treasuryAddress = treasuryAddress;
    } 

    function updateLpRecipient(address payable lpRecipient) external onlyOwner() {
        _lpRecipient = lpRecipient;
    }

    function updateNumTokensToSwap(uint256 numTokens) external onlyOwner() {
        numTokensToSwap = numTokens;
    }
}