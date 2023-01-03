// SPDX-License-Identifier: MIT                                                                               
                                                    
pragma solidity 0.8.17;

import '../common/Ownable.sol';
import '../common/ERC20.sol';
import '../common/IDexRouter.sol';
import '../common/TokenHandler.sol';
import '../common/DividendTracker.sol';
import '../common/IDexFactory.sol';
import '../common/ILpPair.sol';
import '../common/IERC20.sol';
import '../common/Context.sol';
import '../common/EnumerableSet.sol';

contract Dubbz is ERC20, Ownable {

    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
    uint256 public maxWallet;

    IDexRouter public immutable dexRouter;
    address public immutable lpPair;
    address public immutable lpPairEth;

    bool public lpToEth;

    IERC20 public immutable STABLECOIN; 

    bool private swapping;
    uint256 public swapTokensAtAmount;

     // Anti-bot and anti-whale mappings and variables
    mapping(address => uint256) private _holderLastTransferTimestamp; // to hold last Transfers temporarily during launch
    bool public transferDelayEnabled = true;

    // must be used with Stablecoin
    TokenHandler private immutable tokenHandler;
    DividendTracker public immutable dividendTracker;

    address public projectAddress;
    address public operationsAddress;
    address public futureOwnerAddress;

    bool public projectGetsTokens;

    uint256 public tradingActiveBlock = 0; // 0 means trading is not active
    mapping (address => bool) public restrictedWallets;
    uint256 public blockForPenaltyEnd;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;
    
    uint256 public buyTotalFees;
    uint256 public buyLiquidityFee;
    uint256 public buyProjectFee;
    uint256 public buyOperationsFee;

    uint256 public sellTotalFees;
    uint256 public sellProjectFee;
    uint256 public sellLiquidityFee;
    uint256 public sellOperationsFee;

    uint256 constant FEE_DIVISOR = 10000;

    uint256 public tokensForProject;
    uint256 public tokensForOperations;
    uint256 public tokensForLiquidity;
    
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public _isExcludedMaxTransactionAmount;

    mapping (address => bool) public automatedMarketMakerPairs;

    mapping (address => bool) public addressVerified;
    address private verificationAddress;
    bool private verificationRequired;

    // Events

    event VestingTokens(address indexed wallet, uint256 amount);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event EnabledTrading();
    event RemovedLimits();
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event UpdatedMaxBuyAmount(uint256 newAmount);
    event UpdatedMaxSellAmount(uint256 newAmount);
    event UpdatedMaxWalletAmount(uint256 newAmount);
    event UpdatedBuyFee(uint256 newAmount);
    event UpdatedSellFee(uint256 newAmount);
    event UpdatedProjectAddress(address indexed newWallet);
    event UpdatedLiquidityAddress(address indexed newWallet);
    event UpdatedOperationsAddress(address indexed newWallet);
    event MaxTransactionExclusion(address _address, bool excluded);
    event OwnerForcedSwapBack(uint256 timestamp);
    event CaughtEarlyBuyer(address sniper);
    event TransferForeignToken(address token, uint256 amount);
    event IncludeInDividends(address indexed wallet);
    event ExcludeFromDividends(address indexed wallet);

    constructor(bool _lpIsEth) ERC20("Dubbz", "Dubbz") {

        lpToEth = _lpIsEth;

        address stablecoinAddress;
        address _dexRouter;

        // automatically detect router/desired stablecoin
        if(block.chainid == 1){
            stablecoinAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // USDC
            _dexRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // ETH: Uniswap V2
        } else if(block.chainid == 5){
            stablecoinAddress  = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F; // Görli Testnet USDC
            _dexRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // ETH: Uniswap V2
        } else if(block.chainid == 56){
            stablecoinAddress  = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; // BUSD
            _dexRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // BNB Chain: PCS V2
        } else if(block.chainid == 97){
            stablecoinAddress  = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7; // BSC Testnet BUSD
            _dexRouter = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1; // BNB Chain: PCS V2
        } else if(block.chainid == 137){
            stablecoinAddress  = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174; // USDC
            _dexRouter = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff; // Polygon: Quickswap 
        } else if(block.chainid == 80001){
            stablecoinAddress  = 0x0FA8781a83E46826621b3BC094Ea2A0212e71B23; // Mumbai USDC
            _dexRouter = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff; // Mumbai Polygon: Quickswap 
        } else {
            revert("Chain not configured");
        }

        dividendTracker = new DividendTracker(stablecoinAddress); // stablecoin is what is distributed from dividend tracker

        STABLECOIN = IERC20(stablecoinAddress);
        require(STABLECOIN.decimals()  > 0 , "Incorrect liquidity token");

        address newOwner = msg.sender; // can leave alone if owner is deployer.

        dexRouter = IDexRouter(_dexRouter);

        // create pair
        lpPair = IDexFactory(dexRouter.factory()).createPair(address(this), address(STABLECOIN));
        setAutomatedMarketMakerPair(address(lpPair), true);

        lpPairEth = IDexFactory(dexRouter.factory()).createPair(address(this), dexRouter.WETH());
        setAutomatedMarketMakerPair(address(lpPairEth), true);

        uint256 totalSupply = 10 * 1e6 * 1e18;
        
        maxBuyAmount = totalSupply * 25 / 10000; // 0.25%
        maxSellAmount = totalSupply * 25 / 10000; // 0.25%
        maxWallet = totalSupply * 5 / 1000; // 0.5%
        swapTokensAtAmount = totalSupply * 1 / 10000; // 0.01%

        tokenHandler = new TokenHandler();

        buyProjectFee = 0;
        buyLiquidityFee = 400;
        buyOperationsFee = 300;
        buyTotalFees = buyProjectFee + buyLiquidityFee + buyOperationsFee;

        sellProjectFee = 0;
        sellLiquidityFee = 100;
        sellOperationsFee = 600;
        sellTotalFees = sellProjectFee + sellLiquidityFee + sellOperationsFee;

        // update these!
        projectAddress = address(newOwner);
        futureOwnerAddress = address(newOwner);
        operationsAddress = address(newOwner);

        _excludeFromMaxTransaction(newOwner, true);
        _excludeFromMaxTransaction(futureOwnerAddress, true);
        _excludeFromMaxTransaction(address(this), true);
        _excludeFromMaxTransaction(address(0xdead), true);
        _excludeFromMaxTransaction(address(projectAddress), true);
        _excludeFromMaxTransaction(address(operationsAddress), true);
        _excludeFromMaxTransaction(address(dexRouter), true);

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(newOwner);
        dividendTracker.excludeFromDividends(address(dexRouter));
        dividendTracker.excludeFromDividends(address(0xdead));
        dividendTracker.excludeFromDividends(address(futureOwnerAddress));
        dividendTracker.excludeFromDividends(lpPair);
        dividendTracker.excludeFromDividends(lpPairEth);

        excludeFromFees(newOwner, true);
        excludeFromFees(futureOwnerAddress, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        excludeFromFees(address(projectAddress), true);
        excludeFromFees(address(operationsAddress), true);
        excludeFromFees(address(dexRouter), true);

        _createInitialSupply(address(newOwner), totalSupply);
        transferOwnership(newOwner);
    }

    receive() external payable {}

    // Owner Functions

    function setVerificationRules(address _verificationAddress, bool _verificationRequired) external onlyOwner {
        require(_verificationAddress != address(0), "invalid address");
        verificationAddress = _verificationAddress;
        verificationRequired = _verificationRequired;
    }

    function updateLpToEth(bool _lpToEth) external onlyOwner {
        if(_lpToEth){
            require(balanceOf(address(lpPairEth))>0, "Must have tokens in ETH pair to set as default LP pair");
        } else {
            require(balanceOf(address(lpPair))>0, "Must have tokens in STABLECOIN pair to set as default LP pair");
        }
        lpToEth = _lpToEth;
    }

    function enableTrading(uint256 blocksForPenalty) external onlyOwner {
        require(tradingActiveBlock == 0, "Trading is already active, cannot relaunch.");
        require(blocksForPenalty <= 10, "Cannot make penalty blocks more than 10");
        tradingActive = true;
        swapEnabled = true;
        tradingActiveBlock = block.number;
        blockForPenaltyEnd = tradingActiveBlock + blocksForPenalty;
        emit EnabledTrading();
    }

    function pauseTrading() external onlyOwner {
        require(tradingActiveBlock > 0, "Cannot pause until token has launched");
        require(tradingActive, "Trading is already paused");
        tradingActive = false;
    }

    function unpauseTrading() external onlyOwner {
        require(tradingActiveBlock > 0, "Cannot unpause until token has launched");
        require(!tradingActive, "Trading is already unpaused");
        tradingActive = true;
    }

     // disable Transfer delay - cannot be reenabled
    function disableTransferDelay() external onlyOwner {
        transferDelayEnabled = false;
    }

    function manageRestrictedWallets(address[] calldata wallets,  bool restricted) external onlyOwner {
        for(uint256 i = 0; i < wallets.length; i++){
            restrictedWallets[wallets[i]] = restricted;
        }
    }
    
    function removeLimits() external onlyOwner {
        limitsInEffect = false;
        maxBuyAmount = totalSupply();
        maxSellAmount = totalSupply();
        transferDelayEnabled = false;
        emit RemovedLimits();
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

    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 1 / 100) / (10 ** decimals()), "Cannot set max sell amount lower than 1%");
        maxWallet = newNum * (10 ** decimals());
        emit UpdatedMaxWalletAmount(maxWallet);
    }

    // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
  	    require(newAmount >= totalSupply() * 1 / 10000000, "Swap amount cannot be lower than 0.00001% total supply.");
  	    require(newAmount <= totalSupply() * 1 / 1000, "Swap amount cannot be higher than 0.1% total supply.");
  	    swapTokensAtAmount = newAmount;
  	}
    
    function transferForeignToken(address _token, address _to) external onlyOwner returns (bool _sent) {
        require(_token != address(0), "_token address cannot be 0");
        require(_token != address(this) || !tradingActive, "Can't withdraw native tokens while trading is active");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
        emit TransferForeignToken(_token, _contractBalance);
    }

    function setProjectAddress(address _projectAddress) external onlyOwner {
        require(_projectAddress != address(0), "address cannot be 0");
        projectAddress = payable(_projectAddress);
        emit UpdatedProjectAddress(_projectAddress);
    }

    function setOperationsAddress(address _operationsAddress) external onlyOwner {
        require(_operationsAddress != address(0), "address cannot be 0");
        operationsAddress = payable(_operationsAddress);
        emit UpdatedOperationsAddress(_operationsAddress);
    }

    function forceSwapBack(bool inEth) external onlyOwner {
        require(balanceOf(address(this)) >= swapTokensAtAmount, "Can only swap when token amount is at or higher than restriction");
        swapping = true;
        if(inEth){
            swapBackEth();
        } else {
            swapBack();
        }
        swapping = false;
        emit OwnerForcedSwapBack(block.timestamp);
    }
    
    function airdropToWallets(address[] memory wallets, uint256[] memory amountsInTokens) external onlyOwner {
        require(wallets.length == amountsInTokens.length, "arrays must be the same length");
        require(wallets.length < 200, "Can only airdrop 200 wallets per txn due to gas limits");
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

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != lpPair || value, "The pair cannot be removed from automatedMarketMakerPairs");
        automatedMarketMakerPairs[pair] = value;
        _excludeFromMaxTransaction(pair, value);
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateBuyFees(uint256 _projectFee, uint256 _liquidityFee, uint256 _operationsFee) external onlyOwner {
        buyProjectFee = _projectFee;
        buyLiquidityFee = _liquidityFee;
        buyOperationsFee = _operationsFee;
        buyTotalFees = buyProjectFee + buyLiquidityFee + buyOperationsFee;
        require(buyTotalFees <= 800, "Must keep fees at 8% or less");
        emit UpdatedBuyFee(buyTotalFees);
    }

    function updateSellFees(uint256 _projectFee, uint256 _liquidityFee, uint256 _operationsFee) external onlyOwner {
        sellProjectFee = _projectFee;
        sellLiquidityFee = _liquidityFee;
        sellOperationsFee = _operationsFee;
        sellTotalFees = sellProjectFee + sellLiquidityFee + sellOperationsFee;
        require(sellTotalFees <= 1400, "Must keep fees at 14% or less");
        emit UpdatedSellFee(sellTotalFees);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }

    function setProjectGetsTokens(bool getsTokens) external onlyOwner {
        projectGetsTokens = getsTokens;
    }

    // excludes wallets and contracts from dividends (such as CEX hotwallets, etc.)
    function excludeFromDividends(address account) external onlyOwner {
        dividendTracker.excludeFromDividends(account);
        emit ExcludeFromDividends(account);
    }

    // removes exclusion on wallets and contracts from dividends (such as CEX hotwallets, etc.)
    function includeInDividends(address account) external onlyOwner {
        dividendTracker.includeInDividends(account);
        emit IncludeInDividends(account);
    }

    // external functions

    function claim() external {
        distributeDividends();
		dividendTracker.processAccount(payable(msg.sender), false);
    }

    function distributeDividends() public {
        dividendTracker.distributeTokenDividends();
    }

    function verificationToBuy(uint8 _v, bytes32 _r, bytes32 _s) public { // anti-bot / snipe method to restrict buyers at launch.
        require(tradingActive, "trading not active");
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 hash = keccak256(abi.encodePacked(address(this), _msgSender()));
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));
        address signer = ecrecover(prefixedHash, _v, _r, _s);

        if (signer == verificationAddress) {
            addressVerified[_msgSender()] = true;
        }
    }

    // private / internal functions

    function _transfer(address from, address to, uint256 amount) internal override {

        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        // transfer of 0 is allowed, but triggers no logic.  In case of staking where a staking pool is paying out 0 rewards.
        if(amount == 0){
            super._transfer(from, to, 0);
            return;
        }

        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]){ 
            dividendTracker.distributeTokenDividends();
            super._transfer(from, to, amount);
            dividendTracker.setBalance(payable(from), balanceOf(from));
            dividendTracker.setBalance(payable(to), balanceOf(to));
            return;
        }
        
        if(!tradingActive){
            require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active.");
        }

        if(!earlyBuyPenaltyInEffect() && blockForPenaltyEnd > 0){
            require(!restrictedWallets[from] || to == owner() || to == address(0xdead), "Bots cannot transfer tokens in or out except to owner or dead address.");
        }

        if(limitsInEffect){
            if (from != owner() && to != owner() && to != address(0) && to != address(0xdead) && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]){
                
                // at launch if the transfer delay is enabled, ensure the block timestamps for purchasers is set -- during launch.  
                if (transferDelayEnabled){
                    if (to != address(dexRouter) && to != address(lpPair)){
                        require(_holderLastTransferTimestamp[tx.origin] + 4 <= block.number, "_transfer:: Transfer Delay enabled.  Only one purchase per 3 blocks allowed.");
                        _holderLastTransferTimestamp[tx.origin] = block.number;
                    }
                }
                //on buy
                if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
                    if (verificationRequired) {
                        require(addressVerified[to] == true,"Verify you are human first");
                    }
                    require(amount <= maxBuyAmount, "Buy transfer amount exceeds the max buy.");
                    require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                } 
                //on sell
                else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
                    require(amount <= maxSellAmount, "Sell transfer amount exceeds the max sell.");
                }
                else if (!_isExcludedMaxTransactionAmount[to]){
                    require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if(canSwap && swapEnabled && !swapping && automatedMarketMakerPairs[to]) {
            swapping = true;
            if(lpToEth){
                swapBackEth();
            } else {
                swapBack();
            }
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
            // bot/sniper penalty.
            if(earlyBuyPenaltyInEffect() && automatedMarketMakerPairs[from] && !automatedMarketMakerPairs[to] && buyTotalFees > 0){
                
                if(!restrictedWallets[to]){
                    restrictedWallets[to] = true;
                }
                fees = amount * buyTotalFees / FEE_DIVISOR;
        	    tokensForProject += fees * buyProjectFee / buyTotalFees;
        	    tokensForLiquidity += fees * buyLiquidityFee / buyTotalFees;
                tokensForOperations += fees * buyOperationsFee / buyTotalFees;
            }

            // on sell
            else if (automatedMarketMakerPairs[to] && sellTotalFees > 0){
                fees = amount * sellTotalFees / FEE_DIVISOR;
                tokensForLiquidity += fees * sellLiquidityFee / sellTotalFees;
                tokensForProject += fees * sellProjectFee / sellTotalFees;
                tokensForOperations += fees * sellOperationsFee / sellTotalFees;
            }

            // on buy
            else if(automatedMarketMakerPairs[from] && buyTotalFees > 0) {
        	    fees = amount * buyTotalFees / FEE_DIVISOR;
        	    tokensForProject += fees * buyProjectFee / buyTotalFees;
        	    tokensForLiquidity += fees * buyLiquidityFee / buyTotalFees;
                tokensForOperations += fees * buyOperationsFee / buyTotalFees;
            }
            
            if(fees > 0){    
                super._transfer(from, address(this), fees);
            }
        	
        	amount -= fees;
        }

        dividendTracker.distributeTokenDividends();
        super._transfer(from, to, amount);
        dividendTracker.setBalance(payable(from), balanceOf(from));
        dividendTracker.setBalance(payable(to), balanceOf(to));
    }

    // if LP pair in use is STABLECOIN, this function will be used to handle fee distribution.

    function swapTokensForSTABLECOIN(uint256 tokenAmount) private {

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(STABLECOIN);

        _approve(address(this), address(dexRouter), tokenAmount);

        dexRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(tokenHandler), block.timestamp);
    }

    function swapBack() private {

        if(projectGetsTokens && tokensForProject > 0 && balanceOf(address(this)) >= tokensForProject) {
            super._transfer(address(this), address(projectAddress), tokensForProject);
            tokensForProject = 0;
        }

        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForProject + tokensForOperations + tokensForLiquidity;
        
        if(contractBalance == 0 || totalTokensToSwap == 0) {return;}

        if(contractBalance > swapTokensAtAmount * 60){
            contractBalance = swapTokensAtAmount * 60;
        }

        if(tokensForLiquidity > 0){
            uint256 liquidityTokens = contractBalance * tokensForLiquidity / totalTokensToSwap;
            super._transfer(address(this), lpPair, liquidityTokens);
            try ILpPair(lpPair).sync(){} catch {}
            contractBalance -= liquidityTokens;
            totalTokensToSwap -= tokensForLiquidity;
        }
        
        swapTokensForSTABLECOIN(contractBalance);

        tokenHandler.sendTokenToOwner(address(STABLECOIN));
        
        uint256 stablecoinBalance = STABLECOIN.balanceOf(address(this));

        uint256 stablecoinForOperations = stablecoinBalance * tokensForOperations / totalTokensToSwap;

        tokensForProject = 0;
        tokensForOperations = 0;
        tokensForLiquidity = 0;

        if(stablecoinForOperations > 0){
            STABLECOIN.transfer(operationsAddress, stablecoinForOperations);
        }

        if(STABLECOIN.balanceOf(address(this)) > 0){
            STABLECOIN.transfer(projectAddress, STABLECOIN.balanceOf(address(this)));
        }
    }


    // if LP pair in use is ETH, this function will be used to handle fee distribution.

    function swapBackEth() private {

        if(projectGetsTokens && tokensForProject > 0 && balanceOf(address(this)) >= tokensForProject) {
            super._transfer(address(this), address(projectAddress), tokensForProject);
            tokensForProject = 0;
        }

        bool success;

        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForProject + tokensForOperations + tokensForLiquidity;
        
        if(contractBalance == 0 || totalTokensToSwap == 0) {return;}

        if(contractBalance > swapTokensAtAmount * 60){
            contractBalance = swapTokensAtAmount * 60;
        }

        if(tokensForLiquidity > 0){
            uint256 liquidityTokens = contractBalance * tokensForLiquidity / totalTokensToSwap;
            super._transfer(address(this), lpPairEth, liquidityTokens);
            try ILpPair(lpPairEth).sync(){} catch {}
            contractBalance -= liquidityTokens;
            totalTokensToSwap -= tokensForLiquidity;
        }

        swapTokensForEth(contractBalance);
        
        uint256 ethBalance = address(this).balance;

        uint256 ethForOperations = ethBalance * tokensForOperations / totalTokensToSwap;

        tokensForProject = 0;
        tokensForOperations = 0;
        tokensForLiquidity = 0;

        if(ethForOperations > 0){
            (success, ) = operationsAddress.call{value: ethForOperations}("");
        }

        if(address(this).balance > 0){
            (success, ) = projectAddress.call{value: address(this).balance}("");
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        _approve(address(this), address(dexRouter), tokenAmount);

        // make the swap
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function _excludeFromMaxTransaction(address updAds, bool isExcluded) private {
        _isExcludedMaxTransactionAmount[updAds] = isExcluded;
        emit MaxTransactionExclusion(updAds, isExcluded);
    }

    //views

    function earlyBuyPenaltyInEffect() private view returns (bool){
        return block.number < blockForPenaltyEnd;
    }

    function getBlockNumber() external view returns (uint256){
        return block.number;
    }

    function getClaimWait() external view returns(uint256) {
        return dividendTracker.claimWait();
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawableDividendOf(address account) public view returns(uint256) {
    	return dividendTracker.withdrawableDividendOf(account);
  	}

	function dividendTokenBalanceOf(address account) public view returns (uint256) {
		return dividendTracker.holderBalance(account);
	}

    function getAccountDividendsInfo(address account)
        external view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
        return dividendTracker.getAccount(account);
    }

    function getLastProcessedIndex() external view returns(uint256) {
    	return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }
    
    function getNumberOfDividends() external view returns(uint256) {
        return dividendTracker.totalBalance();
    }    
}