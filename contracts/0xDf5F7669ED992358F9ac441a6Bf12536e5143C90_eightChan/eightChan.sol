/**
 *Submitted for verification at Etherscan.io on 2023-05-01
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function allPairsLength() external view returns (uint256);

    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);
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

    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    function name() external view virtual override returns (string memory) {
        return _name;
    }

    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function transfer(address to, uint256 amount)
        external
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount)
        external
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);
    }
}

contract eightChan is ERC20, Ownable {

    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public _isExcludedMaxTransactionAmount;
    mapping (address => bool) public automatedMarketMakerPairs;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    address public marketingAddress;

    bool public tradingActive;
    bool public swapEnabled;
    bool private swapping;


    uint256 public swapTokensAtAmount;

    uint256 public maxWallet;
    uint256 private buyTotalFees;
    uint256 public buyMarketingFee;
    uint256 public buyLiquidityFee;
    uint256 public buyBurnFee;

    uint256 private sellTotalFees;
    uint256 public sellMarketingFee;
    uint256 public sellLiquidityFee;
    uint256 public sellBurnFee;

    uint256 public tokensForMarketing;
    uint256 public tokensForLiquidity;
    uint256 public tokensForBurn;


    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event EnabledTrading();

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event UpdatedmaxWallet(uint256 newAmount);

    event MaxTransactionExclusion(address _address, bool excluded);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    constructor() ERC20("8chan", "8chan") {
        
       IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;

 
        uint256 totalSupply = 1000000 * 1e18;
        
        maxWallet = totalSupply * 2 / 100;
        swapTokensAtAmount = totalSupply * 100 / 100000; // 0.1% swap amount

        buyMarketingFee = 0;
        buyLiquidityFee = 0;
        buyBurnFee = 0;
        buyTotalFees = buyMarketingFee + buyLiquidityFee;

        sellMarketingFee = 0;
        sellLiquidityFee = 0;
        sellBurnFee = 0;
        sellTotalFees = sellMarketingFee + sellLiquidityFee;

        _excludeFromMaxTransaction(owner(), true);
        _excludeFromMaxTransaction(address(this), true);
        _excludeFromMaxTransaction(address(0xdead), true);

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        marketingAddress = 0x37f445c3f67de7101C42b1C4fE47A4DaCfd1a30e;


        _mint(msg.sender, totalSupply);
    
    }

    receive() external payable {}

    // once enabled, can never be turned off
    function enableTrading() external onlyOwner {
        require(!tradingActive, "Cannot reenable trading");
        tradingActive = true;
        swapEnabled = true;
        emit EnabledTrading();
    }

    function updatemaxWallet(uint256 newNum) external onlyOwner {
        maxWallet = newNum * (10**18);
        emit UpdatedmaxWallet(maxWallet);
    }
    
    function _excludeFromMaxTransaction(address updAds, bool isExcluded) private {
        _isExcludedMaxTransactionAmount[updAds] = isExcluded;
        emit MaxTransactionExclusion(updAds, isExcluded);
    }

        function excludeFromMaxTransaction(address updAds, bool isEx) external onlyOwner {
        if(!isEx){
            require(updAds != uniswapV2Pair, "Cannot remove uniswap pair from max txn");
        }
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        require(pair != uniswapV2Pair, "The pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        
        _excludeFromMaxTransaction(pair, value);

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateBuyFees(uint256 _marketingFee, uint256 _liquidityFee, uint256 _burnFee) external onlyOwner {
        buyMarketingFee = _marketingFee;
        buyLiquidityFee = _liquidityFee;
        buyBurnFee = _burnFee;
        buyTotalFees = buyMarketingFee + buyLiquidityFee;
    }

    function updateSellFees(uint256 _marketingFee, uint256 _liquidityFee, uint256 _burnFee) external onlyOwner {
        sellMarketingFee = _marketingFee;
        sellLiquidityFee = _liquidityFee;
        sellBurnFee = _burnFee;
        sellTotalFees = sellMarketingFee + sellLiquidityFee;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function _transfer(address from, address to, uint256 amount) internal override {

        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "amount must be greater than 0");
                   
    
            if (from != owner() && to != owner() && to != address(0) && to != address(0xdead)){
                if(!tradingActive){
                    require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active.");
                }
                if (!_isExcludedMaxTransactionAmount[from] || !_isExcludedMaxTransactionAmount[to]) {
                     require(balanceOf(to) + amount <= maxWallet);
                }
                            
                //when buy
                if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {

                } 
                //when sell
                else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {

                } 
                else if (!_isExcludedMaxTransactionAmount[to] && !_isExcludedMaxTransactionAmount[from]){
                
                }
            }
        

        uint256 contractTokenBalance = balanceOf(address(this));
        
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if(canSwap && swapEnabled && !swapping && !automatedMarketMakerPairs[from] && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            swapping = true;

            swapBack();

            swapping = false;
        }

        bool takeFee = true;
        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }
        
        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if(takeFee){
            
            // on sell
             if (automatedMarketMakerPairs[to] && sellTotalFees > 0){
                fees = amount * sellTotalFees /100;
                tokensForLiquidity += fees * sellLiquidityFee / sellTotalFees;
                tokensForMarketing += fees * sellMarketingFee / sellTotalFees;
                tokensForBurn += amount * sellBurnFee / 100;

            }
            // on buy
            else if(automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = amount * buyTotalFees / 100;
                tokensForLiquidity += fees * buyLiquidityFee / buyTotalFees;
                tokensForMarketing += fees * buyMarketingFee / buyTotalFees;
                tokensForBurn += amount * sellBurnFee / 100;
            }
            
            if(fees > 0){    
                 super._transfer(from, address(this), fees);
            }
                super._transfer(from, address(0xdead), tokensForBurn);


            amount -= (fees + tokensForBurn);
            tokensForBurn = 0;
        }
            
        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(owner()),
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForMarketing;
        
        if(contractBalance == 0 || totalTokensToSwap == 0) {return;}

        if(contractBalance > swapTokensAtAmount * 10){
            contractBalance = swapTokensAtAmount * 10;
        }

        bool success;
        
        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = contractBalance * tokensForLiquidity / totalTokensToSwap / 2;
        
        swapTokensForEth(contractBalance - liquidityTokens); 
        
        uint256 ethBalance = address(this).balance;
        uint256 ethForLiquidity = ethBalance;

        uint256 ethForMarketing = ethBalance * tokensForMarketing / (totalTokensToSwap - (tokensForLiquidity/2));

        ethForLiquidity -= ethForMarketing;
            
        tokensForLiquidity = 0;
        tokensForMarketing = 0;

        
        if(liquidityTokens > 0 && ethForLiquidity > 0){
            addLiquidity(liquidityTokens, ethForLiquidity);
        }

        (success,) = address(marketingAddress).call{value: address(this).balance}("");
    }

    // withdraw ETH if stuck or someone sends to the address
    function withdrawStuckETH() external onlyOwner {
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }

}