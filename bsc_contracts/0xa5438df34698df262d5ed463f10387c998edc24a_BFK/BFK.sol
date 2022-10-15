/**
 *Submitted for verification at BscScan.com on 2022-10-14
*/

// SPDX-License-Identifier: MIT                                                                               
                                                    
pragma solidity 0.8.16;

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
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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

interface IDexRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;
    function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IDexFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract BFK is ERC20, Ownable {

    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;

    IDexRouter public dexRouter;
    address public lpPair;

    bool private swapping;
    uint256 public swapTokensAtAmount;

    address public operationsAddress;
    address public ecosystemAddress;

    uint256 public tradingActiveBlock = 0; // 0 means trading is not active
    uint256 public blockForPenaltyEnd;
    mapping (address => bool) public boughtEarly;
    address[] public earlyBuyers;
    uint256 public botsCaught;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;
    
     // Anti-bot and anti-whale mappings and variables
    mapping(address => uint256) private _holderLastTransferBlock; // to hold last Transfers temporarily during launch
    bool public transferDelayEnabled = true;


    uint256 public buyTotalFees;
    uint256 public buyOperationsFee;
    uint256 public buyLiquidityFee;
    uint256 public buyEcosystemFee;

    uint256 public sellTotalFees;
    uint256 public sellOperationsFee;
    uint256 public sellLiquidityFee;
    uint256 public sellEcosystemFee;

    uint256 public tokensForEcosystem;

    /******************/

    // exlcude from fees and max transaction amount
    mapping (address => bool) public _isExcludedFromFees;
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

    event UpdatedEcosystemAddress(address indexed newWallet);

    event MaxTransactionExclusion(address _address, bool excluded);

    event OwnerForcedSwapBack(uint256 timestamp);

    event CaughtEarlyBuyer(address sniper);

    event TransferForeignToken(address token, uint256 amount);

    constructor() ERC20(block.chainid == 56 || block.chainid == 1 ? "BFK WARZONE" : "TEST", block.chainid == 56 || block.chainid == 1 ? "BFK" : "TEST") {
        
        address newOwner = msg.sender;
        
        if(block.chainid == 56 || block.chainid ==1){
            newOwner = 0x5810a0D422E725B93BD362a4A18d990089048975;
        }

        // initialize router
        address _dexRouter;

        if(block.chainid == 1){
            _dexRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // ETH: Uniswap V2
        } else if(block.chainid == 56){
            _dexRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // BNB Chain: PCS V2
        } else if(block.chainid == 97){
            _dexRouter = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1; // BNB Chain Testnet: PCS V2
        } else {
            revert("Chain not configured");
        }

        dexRouter = IDexRouter(_dexRouter);

        // create pair
        lpPair = IDexFactory(dexRouter.factory()).createPair(address(this), dexRouter.WETH());
        _excludeFromMaxTransaction(address(lpPair), true);
        _setAutomatedMarketMakerPair(address(lpPair), true);

        uint256 totalSupply = 1 * 1e9 * 1e18;
        
        maxBuyAmount = totalSupply * 5 / 1000;
        maxSellAmount = totalSupply * 5 / 1000;
        swapTokensAtAmount = totalSupply * 1 / 10000; // 0.01%

        buyOperationsFee = 2;
        buyLiquidityFee = 1;
        buyEcosystemFee = 2;
        buyTotalFees = buyOperationsFee + buyLiquidityFee + buyEcosystemFee;

        sellOperationsFee = 12;
        sellLiquidityFee = 8;
        sellEcosystemFee = 4;
        sellTotalFees = sellOperationsFee + sellLiquidityFee + sellEcosystemFee;

        if(block.chainid == 56){
            operationsAddress = address(0xFe0E0143286F9e2e7F9F061C0BB0c00eF178A622);
            ecosystemAddress = address(0xFe0E0143286F9e2e7F9F061C0BB0c00eF178A622);
        } else {
            operationsAddress = newOwner;
            ecosystemAddress = newOwner;
        }

        _excludeFromMaxTransaction(newOwner, true);
        _excludeFromMaxTransaction(address(this), true);
        _excludeFromMaxTransaction(address(0xdead), true);
        _excludeFromMaxTransaction(address(dexRouter), true);
        _excludeFromMaxTransaction(address(operationsAddress), true);
        _excludeFromMaxTransaction(address(ecosystemAddress), true);

        excludeFromFees(newOwner, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        excludeFromFees(address(dexRouter), true);
        excludeFromFees(address(operationsAddress), true);
        excludeFromFees(address(ecosystemAddress), true);

        _createInitialSupply(address(newOwner), totalSupply);
        transferOwnership(newOwner);
    }

    function enableTrading(uint256 blocksForPenalty) external onlyOwner {
        require(!tradingActive, "Trading is already active, cannot relaunch.");
        require(blocksForPenalty < 10, "Cannot make penalty blocks more than 10");
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

    function getEarlyBuyers() external view returns (address[] memory){
        return earlyBuyers;
    }

    function removeBoughtEarly(address wallet) external onlyOwner {
        boughtEarly[wallet] = false;
    }

    function manageBlacklist(address[] calldata wallets,  bool blacklisted) external onlyOwner {
        if(blacklisted){
            require(block.number <= blockForPenaltyEnd + 57600, "Only get 2 days to blacklist perceived bots, cannot blacklist after this time.");
        }

        for(uint256 i = 0; i < wallets.length; i++){
            boughtEarly[wallets[i]] = blacklisted;
        }
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
        require(wallets.length < 200, "Can only airdrop 200 wallets per txn due to gas limits"); // allows for airdrop + launch at the same exact time, reducing delays and reducing sniper input.
        for(uint256 i = 0; i < wallets.length; i++){
            address wallet = wallets[i];
            uint256 amount = amountsInTokens[i];
            super._transfer(msg.sender, wallet, amount);
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

    function updateBuyFees(uint256 _operationsFee, uint256 _liquidityFee, uint256 _ecosystemFee) external onlyOwner {
        buyOperationsFee = _operationsFee;
        buyLiquidityFee = _liquidityFee;
        buyEcosystemFee = _ecosystemFee;
        buyTotalFees = buyOperationsFee + buyLiquidityFee + buyEcosystemFee;
        require(buyTotalFees <= 15, "Must keep fees at 15% or less");
    }

    function updateSellFees(uint256 _operationsFee, uint256 _liquidityFee, uint256 _ecosystemFee) external onlyOwner {
        sellOperationsFee = _operationsFee;
        sellLiquidityFee = _liquidityFee;
        sellEcosystemFee = _ecosystemFee;
        sellTotalFees = sellOperationsFee + sellLiquidityFee + sellEcosystemFee;
        require(sellTotalFees <= 25, "Must keep fees at 25% or less");
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function _transfer(address from, address to, uint256 amount) internal override {

        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "amount must be greater than 0");
        
        if(!tradingActive){
            require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active.");
        }

        if(!earlyBuyPenaltyInEffect() && tradingActive){
            require(!boughtEarly[from] || to == owner() || to == address(0xdead), "Bots cannot transfer tokens in or out except to owner or dead address.");
        }
        
        if(limitsInEffect){
            if (from != owner() && to != owner() && to != address(0) && to != address(0xdead) && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]){
            
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
        uint256 tokensForLiquidity;
        address liquidityReceiver;

        // only take fees on buys/sells, do not take on wallet transfers
        if(takeFee){
            // bot/sniper penalty.
            if(earlyBuyPenaltyInEffect() && automatedMarketMakerPairs[from] && !automatedMarketMakerPairs[to] && buyTotalFees > 0){

                if(!boughtEarly[to]){
                    boughtEarly[to] = true;
                    botsCaught += 1;
                    earlyBuyers.push(to);
                    emit CaughtEarlyBuyer(to);
                }
                
                liquidityReceiver = from;
                fees = amount * buyTotalFees / 100;
        	    tokensForLiquidity = fees * buyLiquidityFee / buyTotalFees;
                tokensForEcosystem += fees * buyEcosystemFee / buyTotalFees;
            }

            // on sell
            else if (automatedMarketMakerPairs[to] && sellTotalFees > 0){
                liquidityReceiver = to;
                fees = amount * sellTotalFees / 100;
                tokensForLiquidity = fees * sellLiquidityFee / sellTotalFees;
                tokensForEcosystem += fees * sellEcosystemFee / sellTotalFees;
            }

            // on buy
            else if(automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                liquidityReceiver = from;
        	    fees = amount * buyTotalFees / 100;
        	    tokensForLiquidity = fees * buyLiquidityFee / buyTotalFees;
                tokensForEcosystem += fees * buyEcosystemFee / buyTotalFees;
            }
            
            if(fees > 0){    
                super._transfer(from, address(this), fees);
                if(tokensForLiquidity > 0){
                    super._transfer(address(this), liquidityReceiver, tokensForLiquidity);
                }
            }
        	
        	amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function earlyBuyPenaltyInEffect() public view returns (bool){
        return block.number < blockForPenaltyEnd;
    }

    function swapTokensAndSendEth(uint256 tokenAmount) private {

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        _approve(address(this), address(dexRouter), tokenAmount);

        // make the swap
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(operationsAddress),
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

        if(tokensForEcosystem > 0 && balanceOf(address(this)) >= tokensForEcosystem) {
            super._transfer(address(this), address(ecosystemAddress), tokensForEcosystem);
        }
        tokensForEcosystem = 0;

        uint256 contractBalance = balanceOf(address(this));
        
        if(contractBalance == 0) {return;}

        if(contractBalance > swapTokensAtAmount * 20){
            contractBalance = swapTokensAtAmount * 20;
        }

        swapTokensAndSendEth(contractBalance);
    }

    function transferForeignToken(address _token, address _to) external onlyOwner returns (bool _sent) {
        require(_token != address(0), "_token address cannot be 0");
        require(_token != address(this) || !tradingActive, "Can't withdraw native tokens while trading is active");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
        emit TransferForeignToken(_token, _contractBalance);
    }

    // withdraw ETH if stuck
    function withdrawStuckETH() external onlyOwner {
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }

    function setOperationsAddress(address _operationsAddress) external onlyOwner {
        require(_operationsAddress != address(0), "address cannot be 0");
        operationsAddress = payable(_operationsAddress);
        emit UpdatedOperationsAddress(_operationsAddress);
    }

    function setEcosystemAddress(address _ecosystemAddress) external onlyOwner {
        require(_ecosystemAddress != address(0), "address cannot be 0");
        ecosystemAddress = payable(_ecosystemAddress);
        emit UpdatedEcosystemAddress(_ecosystemAddress);
    }

    // force Swap back if slippage issues.
    function forceSwapBack() external onlyOwner {
        require(balanceOf(address(this)) >= swapTokensAtAmount, "Can only swap when token amount is at or higher than restriction");
        swapping = true;
        swapBack();
        swapping = false;
        emit OwnerForcedSwapBack(block.timestamp);
    }
}