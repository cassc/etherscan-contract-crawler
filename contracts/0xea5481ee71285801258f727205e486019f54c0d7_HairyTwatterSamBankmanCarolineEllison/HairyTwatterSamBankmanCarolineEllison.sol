/**
 *Submitted for verification at Etherscan.io on 2023-10-12
*/

/*
                                                             
Web---> https://HairyTwatterSbf.com

TG---> https://t.me/HairyTwatterSbf

X---> https://x.com/HairyTwatterSbf

Caroline was using Sam as a piggie bank. She took all the Solana and set him up. Dirty whore. 

The ticker was $BITCOIN now it’s $SAM

// SPDX-License-Identifier: MIT

*/
pragma solidity 0.8.20;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Router01 {
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
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

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

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
   
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
  
} 

abstract contract Ownable is Context {
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
        require(_owner == _msgSender(), "Caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "Transfer amount cannot exceeds allowance");
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }

        _transfer(sender, recipient, amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "Decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "Transfer from zero address not allowed");
        require(recipient != address(0), "Transfer to the zero address not allowed");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _init(address account, uint256 amount) internal virtual {
        require(account != address(0));

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0));

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount);
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0));
        require(spender != address(0));

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

contract HairyTwatterSamBankmanCarolineEllison is ERC20, Ownable {
    IUniswapV2Router02 public uniswapV2Router;
    address public  uniswapV2Pair;

    mapping (address => bool) private _isExcludedFromFees;

    uint256 private buyFee;
    uint256 private sellFee;
    
    address public FTXWallet;
    address private DEAD = 0x000000000000000000000000000000000000dEaD;

    bool    public tradingEnabled;

    uint256 public swapTokensAtAmount;
    bool    private swapping;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event BuyFeeUpdated(uint256 buyFee);
    event SellFeeUpdated(uint256 sellFee);
    event ExcludedFromLimits(address indexed account, bool isExcluded);
    event MaxWalletLimitAmountChanged(uint256 maxWalletLimitRate);
    event MaxTransactionLimitAmountChanged(uint256 maxTransferRate);
    event SwapTokensAtAmountUpdated(uint256 swapTokensAtAmount);
    event SwapAndSend(uint256 tokensSwapped, uint256 valueReceived);

    constructor () ERC20("HairyTwatterSamBankmanCarolineEllison", "SAM") 
    {   
        address newOwner = 0x534745AB6DD178A0b9577FCF6316C9Dd6596aEf4;
        transferOwnership(newOwner);
        
        address router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair   = _uniswapV2Pair;

        _approve(address(this), address(uniswapV2Router), type(uint256).max);
              
        FTXWallet =  0x864239821Cf10837e8527e26c07dBFEDdeaabf05;

        buyFee  = 5;
        sellFee = 10;

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(0xdead)] = true;
        _isExcludedFromFees[address(this)] = true;

        _isExcludedFromMaxTxLimit[owner()] = true;
        _isExcludedFromMaxTxLimit[address(0)] = true;
        _isExcludedFromMaxTxLimit[address(this)] = true;
        _isExcludedFromMaxTxLimit[DEAD] = true;
        
        _isExcludedFromMaxWalletLimit[owner()] = true;
        _isExcludedFromMaxWalletLimit[address(0)] = true;
        _isExcludedFromMaxWalletLimit[address(this)] = true;
        _isExcludedFromMaxWalletLimit[DEAD] = true;

        _init(owner(), 1e8 ether);
        swapTokensAtAmount = totalSupply() / 5000;

        maxTransactionAmount  = totalSupply() / 100;        
        maxWalletAmount       = totalSupply() / 100;

    }

    receive() external payable {

  	}

    function enableTrading() public onlyOwner{
        require(!tradingEnabled);
        tradingEnabled = true;
    }  

    function claimStuckTokens(address token) external onlyOwner {
        if (token == address(0x0)) {
            (bool success,) = msg.sender.call{value: address(this).balance}("");
            require(success);
            return;
        }
        IERC20 ERC20token = IERC20(token);
        uint256 balance = ERC20token.balanceOf(address(this));
        ERC20token.transfer(msg.sender, balance);
    }

    function setBuyFee(uint256 _buyFee) external onlyOwner {
        require(_buyFee <= 20, "Buy Fee cannot be more than 20%");
        buyFee = _buyFee;
        emit BuyFeeUpdated(buyFee);
    }

    function setSellFee(uint256 _sellFee) external onlyOwner {
        require(_sellFee <= 20, "Sell Fee cannot be more than 20%");
        sellFee = _sellFee;
        emit SellFeeUpdated(sellFee);
    }

    function excludeFromFees(address account, bool excluded) external onlyOwner{
        require(_isExcludedFromFees[account] != excluded);
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }
 
    function changeFTXWallet(address _FTXWallet) external onlyOwner {
        require(_FTXWallet != address(0));
        FTXWallet = _FTXWallet;
    }
    
    function _transfer(address from,address to,uint256 amount) internal  override {
        require(from != address(0));
        require(to != address(0));
        require(tradingEnabled || _isExcludedFromFees[from] || _isExcludedFromFees[to]);
            
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (maxTransactionLimitEnabled) 
        {
            if ((from == uniswapV2Pair || to == uniswapV2Pair) &&
                _isExcludedFromMaxTxLimit[from] == false && 
                _isExcludedFromMaxTxLimit[to]   == false) 
            {
                require(amount <= maxTransactionAmount, "Transfer amount exceeds the maxTransactionAmount");                
            }
        }
    
		uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (canSwap &&
            !swapping &&
            to == uniswapV2Pair
        ) {
            swapping = true;
          
            swap(contractTokenBalance);        

            swapping = false;
        }

        uint256 _totalFees;
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to] || swapping) {
            _totalFees = 0;

        }else if (from == uniswapV2Pair) {
            _totalFees =  buyFee;

        }else if (to == uniswapV2Pair) {             
            _totalFees = sellFee;
        
        }else {
            _totalFees = 0;
        }

        if (_totalFees > 0) {
            uint256 fees = (amount * _totalFees) / 100;
            amount = amount - fees;
            super._transfer(from, address(this), fees);
        }

        if (maxWalletLimitEnabled) {
            if (_isExcludedFromMaxWalletLimit[from]  == false && 
                _isExcludedFromMaxWalletLimit[to]    == false &&
                to != uniswapV2Pair
            ) {
                uint balance  = balanceOf(to);
                require(
                    balance + amount <= maxWalletAmount, 
                    "Amount exceeds the maxWalletAmount"
                );
            }
        }

        super._transfer(from, to, amount);
    }

    function setSwapTokensAtAmount(uint256 newAmount) external onlyOwner{
        require(newAmount > totalSupply() / 1000000);
        swapTokensAtAmount = newAmount;
        emit SwapTokensAtAmountUpdated(swapTokensAtAmount);
    }
    
    function swap(uint256 tokenAmount) private {
        uint256 initialBalance = address(this).balance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp);

        uint256 newBalance = address(this).balance - initialBalance;

        bool success = payable(FTXWallet).send(newBalance);
        if (success) {
            emit SwapAndSend(tokenAmount, newBalance);
        }
    }
    
    mapping(address => bool) private _isExcludedFromMaxWalletLimit;
    mapping(address => bool) private _isExcludedFromMaxTxLimit;
    bool    public limitsEnabled              = true;
    bool    public maxWalletLimitEnabled      = true;
    bool    public maxTransactionLimitEnabled = true;
    uint256 public maxWalletAmount;
    uint256 public maxTransactionAmount;


    function setEnableLimits(bool enable) external onlyOwner {
        require(
            enable != limitsEnabled);
        maxWalletLimitEnabled = enable;
        maxTransactionLimitEnabled = enable;
    }

    function setMaxWalletAmount(uint256 _maxWalletAmount) external onlyOwner {
        require(
            _maxWalletAmount >= (totalSupply() / (10 ** decimals())) / 100, 
            "Max wallet amount cannot be lower than 1% of total supply"
        );
        maxWalletAmount = _maxWalletAmount * (10 ** decimals());
        emit MaxWalletLimitAmountChanged(maxWalletAmount);
    }

    function setExcludeFromLimits(address account, bool exclude) external onlyOwner {
        require(
            _isExcludedFromMaxWalletLimit[account] != exclude && _isExcludedFromMaxTxLimit[account] != exclude);
        _isExcludedFromMaxWalletLimit[account] = exclude;
        _isExcludedFromMaxTxLimit[account]     = exclude;
        emit ExcludedFromLimits(account, exclude);
    }

    function isExcludedFromMaxWalletLimit(address account) public view returns(bool) {
        return _isExcludedFromMaxWalletLimit[account];
    }

    function isExcludedFromMaxTransaction(address account) public view returns(bool) {
        return _isExcludedFromMaxTxLimit[account];
    }    
    
    function setMaxTransactionAmount(uint256 _maxTransactionAmount) external onlyOwner {
        require(
            _maxTransactionAmount  >= (totalSupply() / (10 ** decimals())) / 1000, 
            "Max Transaction Amount cannot be lower than 0.1% of total supply"
        ); 
        maxTransactionAmount  = _maxTransactionAmount  * (10 ** decimals());
        emit MaxTransactionLimitAmountChanged(maxTransactionAmount);
    }  
    
}