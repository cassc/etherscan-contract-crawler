/**
 *Submitted for verification at BscScan.com on 2023-02-21
*/

// SPDX-License-Identifier: MIT                                                                               
                                                    
pragma solidity 0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
        if(currentAllowance != type(uint256).max){
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
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
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
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
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _createInitialSupply(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "LERC20: mint to the zero address");
        _totalSupply -= amount;
        _balances[account] -= amount;
        emit Transfer(account, address(0), amount);
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

contract Ownable is Context {
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract TokenHandler is Ownable {
    function sendTokenToOwner(address token) external onlyOwner {
        if(IERC20(token).balanceOf(address(this)) > 0){
            IERC20(token).transfer(owner(), IERC20(token).balanceOf(address(this)));
        }
    }
}

interface ILpPair {
    function sync() external;
}

interface IDexRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IDexFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract PureCoin is ERC20, Ownable {

    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;

    IDexRouter public immutable dexRouter;
    address public immutable lpPair;   

    bool private swapping;
    uint256 public swapTokensAtAmount;

    address public operationsAddress;
    address public devAddress;

    uint256 public tradingActiveBlock = 0; // 0 means trading is not active
    uint256 public blockForPenaltyEnd;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;

     // Anti-bot and anti-whale mappings and variables
    mapping(address => uint256) private _holderLastTransferBlock; // to hold last Transfers temporarily during launch
    bool public transferDelayEnabled = true;

    uint256 public buyTotalFees;
    uint256 public buyOperationsFee;
    uint256 public buyLiquidityFee;
    uint256 public buyDevFee;

    uint256 public sellTotalFees;
    uint256 public sellOperationsFee;
    uint256 public sellLiquidityFee;
    uint256 public sellDevFee;

    uint256 public constant FEE_DIVISOR = 10000;

    uint256 public priceImpactLimit;
    uint256 public globalLimit;
    uint256 public globalLimitPeriod;
    bool public globalLimitsActive;
    mapping(address => LimitedWallet) private _limits;

    struct LimitedWallet {
        uint256[] sellAmounts;
        uint256[] sellTimestamps;
        uint256 limitPeriod; // ability to set custom values for individual wallets
        uint256 limitTokens; // ability to set custom values for individual wallets
        bool isExcluded;
    }

    uint256 public tokensForOperations;
    uint256 public tokensForLiquidity;
    uint256 public tokensForDev;

    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public _isExcludedMaxTransactionAmount;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event EnabledTrading();

    event RemovedLimits();

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event UpdatedMaxBuyAmount(uint256 newAmount);

    event UpdatedMaxSellAmount(uint256 newAmount);

    event UpdatedMaxWalletAmount(uint256 newAmount);

    event UpdatedOperationsAddress(address indexed newWallet);

    event UpdatedDevAddress(address indexed newWallet);

    event UpdatedTreasuryAddress(address indexed newWallet);

    event MaxTransactionExclusion(address _address, bool excluded);

    event OwnerForcedSwapBack(uint256 timestamp);

    event CaughtEarlyBuyer(address sniper);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    event TransferForeignToken(address token, uint256 amount);

    constructor(string memory name_, string memory symbol_) ERC20( name_, symbol_) {
        
        address newOwner = msg.sender; // can leave alone if owner is deployer.
        address _dexRouter;

        // automatically detect router
        if(block.chainid == 1){
            _dexRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // ETH: Uniswap V2
        } else if(block.chainid == 5){
            _dexRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // ETH: Uniswap V2
        } else if(block.chainid == 56){
            _dexRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // BNB Chain: PCS V2
        } else if(block.chainid == 97){
            _dexRouter = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1; // BNB Chain: PCS V2
        } else if(block.chainid == 137){
            _dexRouter = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff; // Polygon: Quickswap 
        } else if(block.chainid == 80001){
            _dexRouter = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff; // Mumbai Polygon: Quickswap 
        } else {
            revert("Chain not configured");
        }

        // initialize router
        dexRouter = IDexRouter(_dexRouter);

        // create pair
        lpPair = IDexFactory(dexRouter.factory()).createPair(address(this), dexRouter.WETH());
        _excludeFromMaxTransaction(address(lpPair), true);
        _setAutomatedMarketMakerPair(address(lpPair), true);

        uint256 totalSupply = 100 * 1e6 * 1e18;
        
        maxBuyAmount = totalSupply * 1 / 1000;
        maxSellAmount = totalSupply * 1 / 1000;
        swapTokensAtAmount = totalSupply * 1 / 10000;

        buyOperationsFee = 0;
        buyLiquidityFee = 300;
        buyDevFee = 0;
        buyTotalFees = buyOperationsFee + buyLiquidityFee + buyDevFee;

        sellOperationsFee = 200;
        sellLiquidityFee = 500;
        sellDevFee = 500;
        sellTotalFees = sellOperationsFee + sellLiquidityFee + sellDevFee;

        priceImpactLimit = 200; // 100 = 1% PI
        globalLimit = totalSupply * 1 / 1000;
        globalLimitPeriod = 24 hours;
        globalLimitsActive = true;

        operationsAddress = address(0xf51A22E7C8fDb2812d65C93837e0EB7aa30360F6);
        devAddress = address(0x8e75C1E67577e35cfC102fDEb02d9f48DcE1Aca4);

        _excludeFromMaxTransaction(newOwner, true);
        _excludeFromMaxTransaction(address(this), true);
        _excludeFromMaxTransaction(address(0xdead), true);
        _excludeFromMaxTransaction(address(operationsAddress), true);
        _excludeFromMaxTransaction(address(devAddress), true);

        excludeFromFees(newOwner, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        excludeFromFees(address(operationsAddress), true);
        excludeFromFees(address(devAddress), true);
        excludeFromFees(address(0xd61Ede44750a42671d9a25f6b1540a19170C7A39), true); // future owner
        excludeFromFees(address(0xD152f549545093347A162Dce210e7293f1452150), true); // Disperse.app

        _approve(address(this), address(dexRouter), type(uint256).max);
        _approve(address(msg.sender), address(dexRouter), totalSupply);
        _approve(address(msg.sender), address(0xD152f549545093347A162Dce210e7293f1452150), totalSupply * 11 / 100);

        _createInitialSupply(msg.sender, totalSupply);
        transferOwnership(newOwner);
    }

    receive() external payable {}

     function setGlobalLimit(uint256 newLimit) external onlyOwner {
        require(newLimit >= totalSupply() * 1 / 1000, "Too low");
        globalLimit = newLimit;
    }

    function setGlobalLimitPeriod(uint256 newPeriod) external onlyOwner {
        require(newPeriod <= 24 hours, "Too long");
        globalLimitPeriod = newPeriod;
    }

    function setPriceImpactLimit(uint256 _priceImpactLimit) external onlyOwner {
        require(_priceImpactLimit >= 50, "Cannot set lower than 0.5% PI");
        priceImpactLimit = _priceImpactLimit;
    }

    function setGlobalLimitsActiveStatus(bool status) external onlyOwner {
        globalLimitsActive = status;
    }

    function enableTrading(uint256 blocksForPenalty) external onlyOwner {
        require(!tradingActive, "Trading is already started");
        //standard enable trading
        tradingActive = true;
        swapEnabled = true;
        tradingActiveBlock = block.number;
        blockForPenaltyEnd = tradingActiveBlock + blocksForPenalty;
        emit EnabledTrading();
    }
    
    // remove limits after token is stable
    function removeLimits() external onlyOwner {
        limitsInEffect = false;
        transferDelayEnabled = false;
        maxBuyAmount = totalSupply();
        maxSellAmount = totalSupply();
        emit RemovedLimits();
    }

    // disable Transfer delay - cannot be reenabled
    function disableTransferDelay() external onlyOwner {
        transferDelayEnabled = false;
    }

    function updateMaxBuyAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 1 / 1000)/1e18, "Cannot set max buy amount lower than 0.1%");
        maxBuyAmount = newNum * (10**18);
        emit UpdatedMaxBuyAmount(maxBuyAmount);
    }
    
    function updateMaxSellAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 1 / 1000)/1e18, "Cannot set max sell amount lower than 0.1%");
        maxSellAmount = newNum * (10**18);
        emit UpdatedMaxSellAmount(maxSellAmount);
    }

    // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
  	    require(newAmount >= totalSupply() * 1 / 100000, "Swap amount cannot be lower than 0.001% total supply.");
  	    require(newAmount <= totalSupply() * 1 / 1000, "Swap amount cannot be higher than 0.1% total supply.");
  	    swapTokensAtAmount = newAmount;
  	}
    
    function _excludeFromMaxTransaction(address updAds, bool isExcluded) private {
        _isExcludedMaxTransactionAmount[updAds] = isExcluded;
        emit MaxTransactionExclusion(updAds, isExcluded);
    }

    function airdropToWallets(address[] memory wallets, uint256[] memory amountsInTokens) external onlyOwner {
        require(wallets.length == amountsInTokens.length, "arrays must be the same length");
        require(wallets.length < 600, "Can only airdrop 600 wallets per txn due to gas limits"); // allows for airdrop + launch at the same exact time, reducing delays and reducing sniper input.
        for(uint256 i = 0; i < wallets.length; i++){
            super._transfer(msg.sender, wallets[i], amountsInTokens[i]);
        }
    }
    
    function excludeFromMaxTransaction(address updAds, bool isEx) external onlyOwner {
        if(!isEx){
            require(updAds != lpPair, "Cannot remove uniswap pair from max txn");
        }
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        require(pair != lpPair, "The pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        _excludeFromMaxTransaction(pair, value);
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateBuyFees(uint256 _operationsFee, uint256 _liquidityFee, uint256 _devFee) external onlyOwner {
        buyOperationsFee = _operationsFee;
        buyLiquidityFee = _liquidityFee;
        buyDevFee = _devFee;
        buyTotalFees = buyOperationsFee + buyLiquidityFee + buyDevFee;
        require(buyTotalFees <= 500, "Must keep buy fees at 5% or less");
    }

    function updateSellFees(uint256 _operationsFee, uint256 _liquidityFee, uint256 _devFee) external onlyOwner {
        sellOperationsFee = _operationsFee;
        sellLiquidityFee = _liquidityFee;
        sellDevFee = _devFee;
        sellTotalFees = sellOperationsFee + sellLiquidityFee + sellDevFee;
        require(sellTotalFees <= 1200, "Must keep fees at 12% or less");
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function _transfer(address from, address to, uint256 amount) internal override {

        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "amount must be greater than 0");
        
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to] || swapping){
            super._transfer(from, to, amount);
            return;
        }

        require(tradingActive, "Trading is not active.");

        if(limitsInEffect){                
            // at launch if the transfer delay is enabled, ensure the block timestamps for purchasers is set -- during launch.  
            if (transferDelayEnabled){
                if (to != address(dexRouter) && to != address(lpPair)){
                    require(_holderLastTransferBlock[tx.origin] < block.number && _holderLastTransferBlock[to] < block.number, "_transfer:: Transfer Delay enabled.  Try again later.");
                    _holderLastTransferBlock[tx.origin] = block.number;
                    _holderLastTransferBlock[to] = block.number;
                }
            }
                
            //when buy
            if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
                    require(amount <= maxBuyAmount, "Buy transfer amount exceeds the max buy.");
            } 
            //when sell
            else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
                    require(amount <= maxSellAmount, "Sell transfer amount exceeds the max sell.");
            } 
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if(canSwap && swapEnabled && !swapping && !automatedMarketMakerPairs[from]) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        uint256 fees = 0;
        
        // bot/sniper penalty.
        if(earlyBuyPenaltyInEffect() && automatedMarketMakerPairs[from] && !automatedMarketMakerPairs[to] && buyTotalFees > 0){
            fees = amount * 6000 / FEE_DIVISOR;
            tokensForLiquidity += fees * buyLiquidityFee / buyTotalFees;
            tokensForOperations += fees * buyOperationsFee / buyTotalFees;
            tokensForDev += fees * buyDevFee / buyTotalFees;
        } else if (automatedMarketMakerPairs[to] && sellTotalFees > 0){ // on sell
            fees = amount * sellTotalFees / FEE_DIVISOR;
            tokensForLiquidity += fees * sellLiquidityFee / sellTotalFees;
            tokensForOperations += fees * sellOperationsFee / sellTotalFees;
            tokensForDev += fees * sellDevFee / sellTotalFees;
        } else if(automatedMarketMakerPairs[from] && buyTotalFees > 0) { // on buy
            fees = amount * buyTotalFees / FEE_DIVISOR;
            tokensForLiquidity += fees * buyLiquidityFee / buyTotalFees;
            tokensForOperations += fees * buyOperationsFee / buyTotalFees;
            tokensForDev += fees * buyDevFee / buyTotalFees;
        }
        
        if(fees > 0){    
            super._transfer(from, address(this), fees);
        }
        
        amount -= fees;
        

        if (
            !automatedMarketMakerPairs[from] &&
            !_limits[to].isExcluded
        ) {
            _handleLimited(
                from,
                amount
            );
        }

        super._transfer(from, to, amount);
    }

    function earlyBuyPenaltyInEffect() public view returns (bool){
        return block.number < blockForPenaltyEnd;
    }

    function swapTokensForEth(uint256 tokenAmount) private {

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        // make the swap
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function getCurrentBlock() external view returns (uint256) {
        return block.number;
    }

    function getCurrentTimestamp() external view returns (uint256) {
        return block.timestamp;
    }
    
    function swapBack() private {

        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForOperations + tokensForDev;
        
        if(contractBalance == 0 || totalTokensToSwap == 0) {return;}

        if(contractBalance > swapTokensAtAmount * 40){
            contractBalance = swapTokensAtAmount * 40;
        }
        
        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = contractBalance * tokensForLiquidity / totalTokensToSwap;

        if(liquidityTokens > 0){
            super._transfer(address(this), lpPair, liquidityTokens);
            try ILpPair(lpPair).sync(){} catch {}
            contractBalance -= liquidityTokens;
            totalTokensToSwap -= tokensForLiquidity;
        }

        if(contractBalance > 0){
            swapTokensForEth(contractBalance);

            uint256 ethBalance = address(this).balance;

            uint256 ethForOperations = ethBalance * tokensForOperations / totalTokensToSwap;
                
            tokensForLiquidity = 0;
            tokensForOperations = 0;
            tokensForDev = 0;

            bool success = false;
            if(ethForOperations > 0){
                (success,) = operationsAddress.call{value: ethForOperations}("");   
            }

            if(address(this).balance > 0){
                (success,) = devAddress.call{value: address(this).balance}("");   
            }
        }
    }

    function transferForeignToken(address _token, address _to) external onlyOwner returns (bool _sent) {
        require(_token != address(0), "_token address cannot be 0");
        require(_token != address(this) || !tradingActive, "Can't withdraw native tokens while trading is active");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
        emit TransferForeignToken(_token, _contractBalance);
    }

    // withdraw ETH if stuck or someone sends to the address
    function withdrawStuckETH() external onlyOwner {
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }

    function setOperationsAddress(address _operationsAddress) external onlyOwner {
        require(_operationsAddress != address(0), "address cannot be 0");
        operationsAddress = payable(_operationsAddress);
        emit UpdatedOperationsAddress(_operationsAddress);
    }
    
    function setDevAddress(address _devAddress) external onlyOwner {
        require(_devAddress != address(0), "address cannot be 0");
        devAddress = payable(_devAddress);
        emit UpdatedDevAddress(_devAddress);
    }

    // force Swap back if slippage issues.
    function forceSwapBack() external onlyOwner {
        require(balanceOf(address(this)) >= swapTokensAtAmount, "Can only swap when token amount is at or higher than restriction");
        swapping = true;
        swapBack();
        swapping = false;
        emit OwnerForcedSwapBack(block.timestamp);
    }

    function burnTokens(uint256 amount) external {
        require(balanceOf(msg.sender) >= amount, "not enough tokens");
        _burn(msg.sender, amount);
    }

    function getLimits(address _address)
        external
        view
        returns (LimitedWallet memory)
    {
        return _limits[_address];
    }

    function removeSellLimits(address[] calldata addresses) external onlyOwner {
        for (uint256 i; i < addresses.length; i++) {
            address account = addresses[i];
            _limits[account].limitPeriod = 0;
            _limits[account].limitTokens = 0;
        }
    }

    // Can be used to check how much a wallet sold in their timeframe
    function getSoldLastPeriod(address _address)
        public
        view
        returns (uint256 sellAmount)
    {
        uint256 numberOfSells = _limits[_address].sellAmounts.length;

        if (numberOfSells == 0) {
            return sellAmount;
        }

        uint256 limitPeriod = _limits[_address].limitPeriod == 0
            ? globalLimitPeriod
            : _limits[_address].limitPeriod;
        while (true) {
            if (numberOfSells == 0) {
                break;
            }
            numberOfSells--;
            uint256 sellTimestamp = _limits[_address].sellTimestamps[numberOfSells];
            if (block.timestamp - limitPeriod <= sellTimestamp) {
                sellAmount += _limits[_address].sellAmounts[numberOfSells];
            } else {
                break;
            }
        }
    }

    // Set custom limits for an address. Defaults to 0, thus will use the "globalLimitPeriod" and "globalLimitETH" if we don't set them
    function setLimits(
        address[] calldata addresses,
        uint256[] calldata limitPeriods,
        uint256[] calldata limitsTokens
    ) external onlyOwner {
        require(
            addresses.length == limitPeriods.length &&
                limitPeriods.length == limitsTokens.length,
            "Array lengths don't match"
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            if (limitPeriods[i] == 0 && limitsTokens[i] == 0) continue;
            _limits[addresses[i]].limitPeriod = limitPeriods[i];
            _limits[addresses[i]].limitTokens = limitsTokens[i];
        }
    }

    function addExcludedFromLimits(address[] calldata addresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            _limits[addresses[i]].isExcluded = true;
        }
    }

    function removeExcludedFromLimits(address[] calldata addresses)
        external
        onlyOwner
    {
        require(addresses.length <= 1000, "Array too long");
        for (uint256 i = 0; i < addresses.length; i++) {
            _limits[addresses[i]].isExcluded = false;
        }
    }

    function _handleLimited(address from, uint256 taxedAmount) private {
        if (_limits[from].isExcluded || !globalLimitsActive) {
            return;
        }
        require(getPriceImpact(taxedAmount) <= priceImpactLimit, "Price Impact Limit exceeded");
        _limits[from].sellTimestamps.push(block.timestamp);
        _limits[from].sellAmounts.push(taxedAmount);
        uint256 soldAmountLastPeriod = getSoldLastPeriod(from);

        uint256 limit = _limits[from].limitTokens == 0
            ? globalLimit
            : _limits[from].limitTokens;
        require(
            soldAmountLastPeriod <= limit,
            "Amount over the limit for time period"
        );
    }

    function getPriceImpact(uint256 tokenAmount)
        public
        view
        returns (uint256 priceImpact)
    {
        uint256 amountInWithFee = tokenAmount * 9975 / 10000;
        return (amountInWithFee * 10000 / (balanceOf(lpPair) + amountInWithFee));
    }
}