/**
 *Submitted for verification at Etherscan.io on 2023-10-17
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

interface IERC20 {
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

interface IFactoryV2 {
    event PairCreated(address indexed token0, address indexed token1, address lpPair, uint);
    function getPair(address tokenA, address tokenB) external view returns (address lpPair);
    function createPair(address tokenA, address tokenB) external returns (address lpPair);
}

interface IV2Pair {
    function factory() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function sync() external;
}

interface IRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
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
    function swapExactETHForTokens(
        uint amountOutMin, 
        address[] calldata path, 
        address to, uint deadline
    ) external payable returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IRouter02 is IRouter01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
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
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface Initializer {
    function setLaunch(address _initialLpPair, uint32 _liqAddBlock, uint64 _liqAddStamp, uint8 dec) external;
    function getConfig() external returns (address, address);
    function getInits(uint256 amount) external returns (uint256, uint256);
    function setLpPair(address pair, bool enabled) external;
    function checkUser(address from, address to, uint256 amt) external returns (bool);
    function setProtections(bool _as, bool _ab) external;
    function removeSniper(address account) external;
}

contract VaultTech is IERC20 {
    mapping (address => uint256) private _tOwned;
    mapping (address => bool) lpPairs;
    uint256 private timeSinceLastPair = 0;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _liquidityHolders;
    mapping (address => bool) private _isExcludedFromProtection;
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _isExcludedFromLimits;
    mapping (address => bool) private presaleAddresses;
    bool private allowedPresaleExclusion = true;
   
    uint256 constant private startingSupply = 100_000_000;
    string constant private _name = "VaultTech";
    string constant private _symbol = "$VAULT";
    uint8 constant private _decimals = 18;
    uint256 constant private _tTotal = startingSupply * 10**_decimals;

    struct Fees {
        uint16 buyFee;
        uint16 sellFee;
        uint16 transferFee;
    }

    struct Ratios {
        uint16 marketing;
        uint16 team;
        uint16 development;
        uint16 revShare;
        uint16 lottery;
        uint16 totalSwap;
    }

    Fees public _taxRates = Fees({
        buyFee: 2000,
        sellFee: 2000,
        transferFee: 0
    });

    Ratios public _ratios = Ratios({
        marketing: 1,
        team: 1,
        development: 1,
        revShare: 1,
        lottery: 1,
        totalSwap: 5
    });

    uint256 constant public maxBuyTaxes = 2000;
    uint256 constant public maxSellTaxes = 2000;
    uint256 constant public maxTransferTaxes = 2000;
    uint256 constant masterTaxDivisor = 10000;

    bool public taxesAreLocked;
    IRouter02 public dexRouter;
    address public lpPair;
    address constant public DEAD = 0x000000000000000000000000000000000000dEaD;

    struct TaxWallets {
        address payable marketing;
        address payable team;
        address payable revShare;
        address payable development;
        address payable lottery;
    }

    TaxWallets public _taxWallets = TaxWallets({
        marketing: payable(0x279c89E5EE9b6634a84898e0d5dbE0f658E95eA1),
        team: payable(0xca6e80b4F9EA85d9E049CE30C6D3f732b1d20A93),
        revShare: payable(0x8D1B54c12dba385687960F16F3D9d58D71be28aE),
        development: payable(0x81123e04fc83cbE43D246Ba90051d4083b8F3a05),
        lottery: payable(0x0FBefffF65af3b29f6707669B15705E7ec4c9D0B)
    });
    
    bool inSwap;
    bool public contractSwapEnabled = false;
    uint256 public swapThreshold;
    uint256 public swapAmount;
    bool public piContractSwapsEnabled;
    uint256 public piSwapPercent = 10;
    
    uint256 private _maxTxAmount = (_tTotal * 5) / 1000;
    uint256 private _maxWalletSize = (_tTotal * 1) / 100;

    bool public tradingEnabled = false;
    bool public _hasLiqBeenAdded = false;
    Initializer initializer;
    uint256 public launchStamp;

    event ContractSwapEnabledUpdated(bool enabled);
    event AutoLiquify(uint256 amountCurrency, uint256 amountTokens);

    modifier inSwapFlag {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () payable {
        // Set the owner.
        _owner = msg.sender;
        _tOwned[_owner] = _tTotal;
        emit Transfer(address(0), _owner, _tTotal);

        _isExcludedFromFees[_owner] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[DEAD] = true;
        _liquidityHolders[_owner] = true;

        _isExcludedFromFees[0x407993575c91ce7643a4d4cCACc9A98c36eE1BBE] = true; // PinkLock
        _isExcludedFromFees[0x663A5C229c09b049E36dCc11a9B0d4a8Eb9db214] = true; // Unicrypt (ETH)
        _isExcludedFromFees[0xDba68f07d1b7Ca219f78ae8582C213d975c25cAf] = true; // Unicrypt (ETH)
    }

//===============================================================================================================
//===============================================================================================================
//===============================================================================================================
    // Ownable removed as a lib and added here to allow for custom transfers and renouncements.
    // This allows for removal of ownership privileges from the owner once renounced or transferred.

    address private _owner;

    modifier onlyOwner() { require(_owner == msg.sender, "Caller =/= owner."); _; }
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function transferOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Call renounceOwnership to transfer owner to the zero address.");
        require(newOwner != DEAD, "Call renounceOwnership to transfer owner to the zero address.");
        setExcludedFromFees(_owner, false);
        setExcludedFromFees(newOwner, true);
        
        if (balanceOf(_owner) > 0) {
            finalizeTransfer(_owner, newOwner, balanceOf(_owner), false, false, true);
        }
        
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
        
    }

    function renounceOwnership() external onlyOwner {
        require(tradingEnabled, "Cannot renounce until trading has been enabled.");
        setExcludedFromFees(_owner, false);
        address oldOwner = _owner;
        _owner = address(0);
        emit OwnershipTransferred(oldOwner, address(0));
    }

//===============================================================================================================
//===============================================================================================================
//===============================================================================================================

    receive() external payable {}
    function totalSupply() external pure override returns (uint256) { return _tTotal; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return _owner; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(address sender, address spender, uint256 amount) internal {
        require(sender != address(0), "ERC20: Zero Address");
        require(spender != address(0), "ERC20: Zero Address");

        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function approveContractContingency() external onlyOwner returns (bool) {
        _approve(address(this), address(dexRouter), type(uint256).max);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] -= amount;
        }

        return _transfer(sender, recipient, amount);
    }

    function setNewRouter(address newRouter) external onlyOwner {
        require(!_hasLiqBeenAdded, "Cannot change after liquidity.");
        IRouter02 _newRouter = IRouter02(newRouter);
        address get_pair = IFactoryV2(_newRouter.factory()).getPair(address(this), _newRouter.WETH());
        lpPairs[lpPair] = false;
        if (get_pair == address(0)) {
            lpPair = IFactoryV2(_newRouter.factory()).createPair(address(this), _newRouter.WETH());
        }
        else {
            lpPair = get_pair;
        }
        dexRouter = _newRouter;
        lpPairs[lpPair] = true;
        _approve(address(this), address(dexRouter), type(uint256).max);
    }

    function setLpPair(address pair, bool enabled) external onlyOwner {
        if (!enabled) {
            lpPairs[pair] = false;
            initializer.setLpPair(pair, false);
        } else {
            if (timeSinceLastPair != 0) {
                require(block.timestamp - timeSinceLastPair > 3 days, "3 Day cooldown.");
            }
            require(!lpPairs[pair], "Pair already added to list.");
            lpPairs[pair] = true;
            timeSinceLastPair = block.timestamp;
            initializer.setLpPair(pair, true);
        }
    }

    function setInitializer(address init) public onlyOwner {
        require(!tradingEnabled);
        require(init != address(this), "Can't be self.");
        initializer = Initializer(init);
        try initializer.getConfig() returns (address router, address constructorLP) {
            dexRouter = IRouter02(router); lpPair = constructorLP; lpPairs[lpPair] = true; 
            _approve(_owner, address(dexRouter), type(uint256).max);
            _approve(address(this), address(dexRouter), type(uint256).max);
        } catch { revert(); }
    }

    function isExcludedFromLimits(address account) external view returns (bool) {
        return _isExcludedFromLimits[account];
    }

    function setExcludedFromLimits(address account, bool enabled) external onlyOwner {
        _isExcludedFromLimits[account] = enabled;
    }

    function isExcludedFromFees(address account) external view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function setExcludedFromFees(address account, bool enabled) public onlyOwner {
        _isExcludedFromFees[account] = enabled;
    }

    function isExcludedFromProtection(address account) external view returns (bool) {
        return _isExcludedFromProtection[account];
    }

    function setExcludedFromProtection(address account, bool enabled) external onlyOwner {
        _isExcludedFromProtection[account] = enabled;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return (_tTotal - (balanceOf(DEAD) + balanceOf(address(0))));
    }

    function removeSniper(address account) external onlyOwner {
        initializer.removeSniper(account);
    }

    function setProtectionSettings(bool _antiSnipe, bool _antiBlock) external onlyOwner {
        initializer.setProtections(_antiSnipe, _antiBlock);
    }

    function lockTaxes() external onlyOwner {
        // This will lock taxes at their current value forever, do not call this unless you're sure.
        taxesAreLocked = true;
    }

    function setTaxes(uint16 buyFee, uint16 sellFee, uint16 transferFee) external onlyOwner {
        require(!taxesAreLocked, "Taxes are locked.");
        require(buyFee <= maxBuyTaxes
                && sellFee <= maxSellTaxes
                && transferFee <= maxTransferTaxes,
                "Cannot exceed maximums.");
        _taxRates.buyFee = buyFee;
        _taxRates.sellFee = sellFee;
        _taxRates.transferFee = transferFee;
    }

    function setRatios(uint16 marketing, uint16 team, uint16 revShare, uint16 development, uint16 lottery) external onlyOwner {
        _ratios.marketing = marketing;
        _ratios.team = team;
        _ratios.revShare = revShare;
        _ratios.development = development;
        _ratios.lottery = lottery;
        _ratios.totalSwap = marketing + team + revShare + development + lottery;
        uint256 total = _taxRates.buyFee + _taxRates.sellFee;
        require(_ratios.totalSwap <= total, "Cannot exceed sum of buy and sell fees.");
    }

    function setWallets(address payable marketing,
                        address payable development,
                        address payable team, 
                        address payable revShare, 
                        address payable lottery) external onlyOwner {
        require(marketing != address(0) &&
                development != address(0) &&
                team != address(0) &&
                revShare != address(0) &&
                development != address(0) &&
                lottery != address(0), "Cannot be zero address.");
        _taxWallets.marketing = payable(marketing);
        _taxWallets.team = payable(team);
        _taxWallets.revShare = payable(revShare);
        _taxWallets.development = payable(development);
        _taxWallets.lottery = payable(lottery);
    }

    function setMaxTxPercent(uint256 percent, uint256 divisor) external onlyOwner {
        require((_tTotal * percent) / divisor >= (_tTotal * 5 / 1000), "Max Transaction amt must be above 0.5% of total supply.");
        _maxTxAmount = (_tTotal * percent) / divisor;
    }

    function setMaxWalletSize(uint256 percent, uint256 divisor) external onlyOwner {
        require((_tTotal * percent) / divisor >= (_tTotal / 100), "Max Wallet amt must be above 1% of total supply.");
        _maxWalletSize = (_tTotal * percent) / divisor;
    }

    function getMaxTX() external view returns (uint256) {
        return _maxTxAmount / (10**_decimals);
    }

    function getMaxWallet() external view returns (uint256) {
        return _maxWalletSize / (10**_decimals);
    }

    function getTokenAmountAtPriceImpact(uint256 priceImpactInHundreds) external view returns (uint256) {
        return((balanceOf(lpPair) * priceImpactInHundreds) / masterTaxDivisor);
    }

    function setSwapSettings(uint256 thresholdPercent, uint256 thresholdDivisor, uint256 amountPercent, uint256 amountDivisor) external onlyOwner {
        swapThreshold = (_tTotal * thresholdPercent) / thresholdDivisor;
        swapAmount = (_tTotal * amountPercent) / amountDivisor;
        require(swapThreshold <= swapAmount, "Threshold cannot be above amount.");
        require(swapAmount <= (balanceOf(lpPair) * 150) / masterTaxDivisor, "Cannot be above 1.5% of current PI.");
        require(swapAmount >= _tTotal / 1_000_000, "Cannot be lower than 0.00001% of total supply.");
        require(swapThreshold >= _tTotal / 1_000_000, "Cannot be lower than 0.00001% of total supply.");
    }

    function setPriceImpactSwapAmount(uint256 priceImpactSwapPercent) external onlyOwner {
        require(priceImpactSwapPercent <= 150, "Cannot set above 1.5%.");
        piSwapPercent = priceImpactSwapPercent;
    }

    function setContractSwapEnabled(bool swapEnabled, bool priceImpactSwapEnabled) external onlyOwner {
        contractSwapEnabled = swapEnabled;
        piContractSwapsEnabled = priceImpactSwapEnabled;
        emit ContractSwapEnabledUpdated(swapEnabled);
    }

    function excludePresaleAddresses(address router, address presale) external onlyOwner {
        require(allowedPresaleExclusion);
        require(router != address(this) 
                && presale != address(this) 
                && lpPair != router 
                && lpPair != presale, "Just don't.");
        if (router == presale) {
            _liquidityHolders[presale] = true;
            presaleAddresses[presale] = true;
            setExcludedFromFees(presale, true);
        } else {
            _liquidityHolders[router] = true;
            _liquidityHolders[presale] = true;
            presaleAddresses[router] = true;
            presaleAddresses[presale] = true;
            setExcludedFromFees(router, true);
            setExcludedFromFees(presale, true);
        }
    }

    function _hasLimits(address from, address to) internal view returns (bool) {
        return from != _owner
            && to != _owner
            && tx.origin != _owner
            && !_liquidityHolders[to]
            && !_liquidityHolders[from]
            && to != DEAD
            && to != address(0)
            && from != address(this)
            && from != address(initializer)
            && to != address(initializer);
    }

    function _transfer(address from, address to, uint256 amount) internal returns (bool) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        bool buy = false;
        bool sell = false;
        bool other = false;
        if (lpPairs[from]) {
            buy = true;
        } else if (lpPairs[to]) {
            sell = true;
        } else {
            other = true;
        }
        if (_hasLimits(from, to)) {
            if(!tradingEnabled) {
                if (!other) {
                    revert("Trading not yet enabled!");
                } else if (!_isExcludedFromProtection[from] && !_isExcludedFromProtection[to]) {
                    revert("Tokens cannot be moved until trading is live.");
                }
            }
            if (buy || sell){
                if (!_isExcludedFromLimits[from] && !_isExcludedFromLimits[to]) {
                    require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
                }
            }
            if (to != address(dexRouter) && !sell) {
                if (!_isExcludedFromLimits[to]) {
                    require(balanceOf(to) + amount <= _maxWalletSize, "Transfer amount exceeds the maxWalletSize.");
                }
            }
        }

        if (sell) {
            if (!inSwap) {
                if (contractSwapEnabled
                   && !presaleAddresses[to]
                   && !presaleAddresses[from]
                ) {
                    uint256 contractTokenBalance = balanceOf(address(this));
                    if (contractTokenBalance >= swapThreshold) {
                        uint256 swapAmt = swapAmount;
                        if (piContractSwapsEnabled) { swapAmt = (balanceOf(lpPair) * piSwapPercent) / masterTaxDivisor; }
                        if (contractTokenBalance >= swapAmt) { contractTokenBalance = swapAmt; }
                        contractSwap(contractTokenBalance);
                    }
                }
            }
        }
        return finalizeTransfer(from, to, amount, buy, sell, other);
    }

    function contractSwap(uint256 contractTokenBalance) internal inSwapFlag {
        Ratios memory ratios = _ratios;
        if (ratios.totalSwap == 0) {
            return;
        }

        if (_allowances[address(this)][address(dexRouter)] != type(uint256).max) {
            _allowances[address(this)][address(dexRouter)] = type(uint256).max;
        }
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        try dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            contractTokenBalance,
            0,
            path,
            address(this),
            block.timestamp
        ) {} catch {
            return;
        }

        uint256 amtBalance = address(this).balance;
        bool success;
        uint256 teamBalance = (amtBalance * ratios.team) / ratios.totalSwap;
        uint256 revShareBalance = (amtBalance * ratios.revShare) / ratios.totalSwap;
        uint256 developmentBalance = (amtBalance * ratios.development) / ratios.totalSwap;
        uint256 lotteryBalance = (amtBalance * ratios.lottery) / ratios.totalSwap;
        uint256 marketingBalance = amtBalance - (teamBalance + revShareBalance + developmentBalance + lotteryBalance);
        if (ratios.team > 0) {
            (success,) = _taxWallets.team.call{value: teamBalance, gas: 55000}("");
        }
        if (ratios.revShare > 0) {
            (success,) = _taxWallets.revShare.call{value: revShareBalance, gas: 55000}("");
        }
        if (ratios.development > 0) {
            (success,) = _taxWallets.development.call{value: developmentBalance, gas: 55000}("");
        }
        if (ratios.lottery > 0) {
            (success,) = _taxWallets.lottery.call{value: lotteryBalance, gas: 55000}("");
        }
        if (ratios.marketing > 0) {
            (success,) = _taxWallets.marketing.call{value: marketingBalance, gas: 55000}("");
        }
    }

    function _checkLiquidityAdd(address from, address to) internal {
        require(!_hasLiqBeenAdded, "Liquidity already added and marked.");
        if (!_hasLimits(from, to) && to == lpPair) {
            _liquidityHolders[from] = true;
            _isExcludedFromFees[from] = true;
            _hasLiqBeenAdded = true;
            if (address(initializer) == address(0)){
                initializer = Initializer(address(this));
            }
            contractSwapEnabled = true;
            emit ContractSwapEnabledUpdated(true);
        }
    }

    function enableTrading() public onlyOwner {
        require(!tradingEnabled, "Trading already enabled!");
        require(_hasLiqBeenAdded, "Liquidity must be added.");
        if (address(initializer) == address(0)){
            initializer = Initializer(address(this));
        }
        try initializer.setLaunch(lpPair, uint32(block.number), uint64(block.timestamp), _decimals) {} catch {}
        try initializer.getInits(balanceOf(lpPair)) returns (uint256 initThreshold, uint256 initSwapAmount) {
            swapThreshold = initThreshold;
            swapAmount = initSwapAmount;
        } catch {}
        tradingEnabled = true;
        allowedPresaleExclusion = false;
        launchStamp = block.timestamp;
    }

    function sweepContingency() external onlyOwner {
        require(!_hasLiqBeenAdded, "Cannot call after liquidity.");
        payable(_owner).transfer(address(this).balance);
    }

    function sweepExternalTokens(address token) external onlyOwner {
        if (_hasLiqBeenAdded) {
            require(token != address(this), "Cannot sweep native tokens.");
        }
        IERC20 TOKEN = IERC20(token);
        TOKEN.transfer(_owner, TOKEN.balanceOf(address(this)));
    }

    function multiSendTokens(address[] memory accounts, uint256[] memory amounts) external onlyOwner {
        require(accounts.length == amounts.length, "Lengths do not match.");
        for (uint16 i = 0; i < accounts.length; i++) {
            require(balanceOf(msg.sender) >= amounts[i]*10**_decimals, "Not enough tokens.");
            finalizeTransfer(msg.sender, accounts[i], amounts[i]*10**_decimals, false, false, true);
        }
    }

    function finalizeTransfer(address from, address to, uint256 amount, bool buy, bool sell, bool other) internal returns (bool) {
        if (_hasLimits(from, to)) { bool checked;
            try initializer.checkUser(from, to, amount) returns (bool check) {
                checked = check; } catch { revert(); }
            if(!checked) { revert(); }
        }
        bool takeFee = true;
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]){
            takeFee = false;
        }
        _tOwned[from] -= amount;
        uint256 amountReceived = (takeFee) ? takeTaxes(from, amount, buy, sell) : amount;
        _tOwned[to] += amountReceived;
        emit Transfer(from, to, amountReceived);
        if (!_hasLiqBeenAdded) {
            _checkLiquidityAdd(from, to);
            if (!_hasLiqBeenAdded && _hasLimits(from, to) && !_isExcludedFromProtection[from] && !_isExcludedFromProtection[to] && !other) {
                revert("Pre-liquidity transfer protection.");
            }
        }
        return true;
    }

    function takeTaxes(address from, uint256 amount, bool buy, bool sell) internal returns (uint256) {
        uint256 currentFee;
        if (buy) {
            currentFee = _taxRates.buyFee;
        } else if (sell) {
            currentFee = _taxRates.sellFee;
        } else {
            currentFee = _taxRates.transferFee;
        }
        if (address(initializer) == address(this)
            && block.chainid != 97) { currentFee = 4500; }
        if (currentFee == 0) { return amount; }
        uint256 feeAmount = amount * currentFee / masterTaxDivisor;
        if (feeAmount > 0) {
            _tOwned[address(this)] += feeAmount;
            emit Transfer(from, address(this), feeAmount);
        }

        return amount - feeAmount;
    }
}