// SPDX-License-Identifier: MIT

pragma solidity =0.8.15;

/*
https://t.me/Moonprinter_Entry
twitter.com/Brrrrtweets
*/

import "./MoonPrinterDividendPayingToken.sol";

contract MoonPrinter is ERC20, Ownable {
    DividendTracker public dividendTracker;

    IRouter public router;
    address public pair;

    address public treasuryWallet = 0x68BAFF11d48f3a120b1dBf442fD4F0344526820A;
    address public devWallet;

    uint256 public swapTokensAtAmount;
    uint256 public maxBuyAmount;
    uint256 public maxWallet;
    uint256 public TotalBuyBacks;
    uint256 public totalBurned;

    mapping(address => bool) public _isBot;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedFromMaxWallet;
    mapping(address => bool) public automatedMarketMakerPairs;

    bool private swapping;
    bool public swapEnabled = true;
    bool public claimEnabled = false;
    bool public tradingEnabled;

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event GasForProcessingUpdated(
        uint256 indexed newValue,
        uint256 indexed oldValue
    );

    event SendDividends(uint256 tokensSwapped, uint256 amount);

    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );
    struct Taxes {
        uint256 treasury; //buyback
        uint256 dev; //marketing
    }

    Taxes public buyTaxes;
    Taxes public sellTaxes;
    uint256 public totalBuyTax;
    uint256 public totalSellTax;

    constructor(address _devWallet) ERC20("MoonPrinter", "BRRR") {
        dividendTracker = new DividendTracker();
        setSwapTokensAtAmount(4000000000); //
        setDevWallet(_devWallet);
        updateMaxWalletAmount(200000000000);
        setMaxBuy(200000000000);
        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //0xD99D1c33F9fC3444f8101754aBC46c52416550D1 // 0x10ED43C718714eb63d5aA57B78B54704E256024E
        address _pair = IFactory(_router.factory()).createPair(
            address(this),
            _router.WETH()
        );

        router = _router;
        pair = _pair;

        totalBuyTax = 15;
        totalSellTax = 45;
        buyTaxes = Taxes(15, 0);
        sellTaxes = Taxes(45, 0);

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(0xe98C6C863cCF6BD76AE201b7f9389b41b7cd1e0B, true);
        excludeFromFees(address(dividendTracker), true);
        excludeFromFees(treasuryWallet, true);

        excludeFromMaxWallet(address(this), true);
        excludeFromMaxWallet(_pair, true);
        excludeFromMaxWallet(owner(), true);
        excludeFromMaxWallet(address(0), true);
        excludeFromMaxWallet(treasuryWallet, true);
        excludeFromMaxWallet(devWallet, true);
        excludeFromMaxWallet(address(dividendTracker), true);

        _setAutomatedMarketMakerPair(_pair, true);

        dividendTracker.excludeFromDividends(address(dividendTracker), true);
        dividendTracker.excludeFromDividends(address(this), true);
        dividendTracker.excludeFromDividends(owner(), true);
        dividendTracker.excludeFromDividends(address(0), true);
        dividendTracker.excludeFromDividends(address(_router), true);

        /*
            _mint is an internal function that is only called here,
            and cannot be called ever again
        */
        _mint(treasuryWallet, 2340000000000 * (10**18));
        _mint(owner(), 29600000000000 * (10**18));
    }

    receive() external payable {}

    function AddAirdropRewardsFromContract(uint256 amount) public onlyOwner {
        if (amount > 0) {
            IERC20 token = IERC20(address(this));
            bool success = token.transfer(address(dividendTracker), amount);
            if (success) {
                dividendTracker.distributeDividends(amount);
            }
        }
    }

    function AddAirdropRewardsFromOwner(uint256 amount) public onlyOwner {
        //make sure to approve the contract, and dividend token to pull balance
        if (amount > 0) {
            IERC20 token = IERC20(address(this));
            bool success = token.transferFrom(
                msg.sender,
                address(dividendTracker),
                amount
            );
            if (success) {
                dividendTracker.distributeDividends(amount);
            }
        }
    }

    function burn(uint256 amountTokens) public {
        address sender = msg.sender;
        require(
            balanceOf(sender) >= amountTokens,
            "ERC20: Burn Amount exceeds account balance"
        );
        require(sender != address(0), "ERC20: Invalid sender address");
        require(amountTokens > 0, "ERC20: Enter some amount to burn");
        totalBurned = totalBurned + amountTokens;
        uint256 AmountToBurn = amountTokens;
        _burn(sender, AmountToBurn);
    }

    /// @param bot The bot address
    /// @param value "true" to blacklist, "false" to unblacklist
    function setBot(address bot, bool value) external onlyOwner {
        require(_isBot[bot] != value);
        _isBot[bot] = value;
    }

    function setBulkBot(address[] memory bots, bool value) external onlyOwner {
        for (uint256 i; i < bots.length; i++) {
            _isBot[bots[i]] = value;
        }
    }

    function normalizeTax() public onlyOwner {
        totalBuyTax = 5;
        totalSellTax = 7;
        buyTaxes = Taxes(3, 2);
        sellTaxes = Taxes(4, 3);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded);
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeFromMaxWallet(address account, bool excluded)
        public
        onlyOwner
    {
        _isExcludedFromMaxWallet[account] = excluded;
    }

    function excludeMultipleAccountsFromFees(
        address[] calldata accounts,
        bool excluded
    ) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }
        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    /// @dev "true" to exclude, "false" to include
    function excludeFromDividends(address account, bool value)
        external
        onlyOwner
    {
        dividendTracker.excludeFromDividends(account, value);
    }

    function setTreasuryWallet(address newtreasury) public onlyOwner {
        require(newtreasury != treasuryWallet, "this wallet is already set");
        treasuryWallet = newtreasury;
    }

    function setDevWallet(address newWallet) public onlyOwner {
        require(newWallet != devWallet, "this wallet is already set");
        devWallet = newWallet;
    }

    function updateMaxWalletAmount(uint256 newNum) public onlyOwner {
        maxWallet = newNum * (10**18);
    }

    function setMaxBuy(uint256 maxBuy) public onlyOwner {
        maxBuyAmount = maxBuy * 10**18;
    }

    function setDiv_Token(address _token) external onlyOwner {
        dividendTracker.updateLP_Token(_token);
    }

    /// @notice Update the threshold to swap tokens for liquidity,
    ///   treasury and dividends.
    function setSwapTokensAtAmount(uint256 amount) public onlyOwner {
        require(amount < 3200000000000);
        swapTokensAtAmount = amount * 10**18;
    }

    /// @notice Enable or disable internal swaps
    /// @dev Set "true" to enable internal swaps for liquidity, treasury and dividends
    function setSwapEnabled() external onlyOwner {
        swapEnabled = !swapEnabled;
    }

    /// @notice Manual claim the dividends
    function claim() external {
        require(claimEnabled, "Claim not enabled");
        dividendTracker.processAccount(payable(msg.sender));
    }

    /// @notice Withdraw tokens sent by mistake.
    /// @param tokenAddress The address of the token to withdraw
    function rescueETH20Tokens(address tokenAddress) external onlyOwner {
        IERC20(tokenAddress).transfer(
            owner(),
            IERC20(tokenAddress).balanceOf(address(this))
        );
    }

    /// @notice Send remaining ETH to treasuryWallet
    /// @dev It will send all ETH to treasuryWallet
    function forceSend() external onlyOwner {
        (bool success, ) = payable(devWallet).call{
            value: address(this).balance
        }("");
        require(success, "Failed to send ETH to dev wallet");
    }

    function trackerRescueETH20Tokens(address tokenAddress) external onlyOwner {
        dividendTracker.trackerRescueETH20Tokens(owner(), tokenAddress);
    }

    function trackerForceSend() external onlyOwner {
        dividendTracker.trackerForceSend(owner());
    }

    function updateRouter(address newRouter) external onlyOwner {
        router = IRouter(newRouter);
    }

    function activateTrading() external onlyOwner {
        require(!tradingEnabled, "Trading already enabled");
        tradingEnabled = true;
    }

    function setClaimEnabled() external onlyOwner {
        claimEnabled = !claimEnabled;
    }

    function SetDividends(address account) external onlyOwner {
        dividendTracker.setBalance(account, balanceOf(account));
    }


    function ClaimedByUser(address account) public view returns (uint256) {
        return dividendTracker.TotalClaimedByUser(account);
    }

    /// @dev Set new pairs created due to listing in new DEX
    function setAutomatedMarketMakerPair(address newPair, bool value)
        external
        onlyOwner
    {
        _setAutomatedMarketMakerPair(newPair, value);
    }

    function _setAutomatedMarketMakerPair(address newPair, bool value) private {
        require(automatedMarketMakerPairs[newPair] != value);
        automatedMarketMakerPairs[newPair] = value;

        if (value) {
            dividendTracker.excludeFromDividends(newPair, true);
        }

        emit SetAutomatedMarketMakerPair(newPair, value);
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawableDividendOf(address account)
        public
        view
        returns (uint256)
    {
        return dividendTracker.withdrawableDividendOf(account);
    }

    function dividendTokenBalanceOf(address account)
        public
        view
        returns (uint256)
    {
        return dividendTracker.balanceOf(account);
    }

    function getAccountInfo(address account)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return dividendTracker.getAccount(account);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!_isBot[from] && !_isBot[to], "Bye Bye Bot");

        if (
            !_isExcludedFromFees[from] && !_isExcludedFromFees[to] && !swapping
        ) {
            require(tradingEnabled, "Trading not active");
        }

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            !swapping &&
            swapEnabled &&
            automatedMarketMakerPairs[to] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;

            if (totalSellTax > 0 && swapTokensAtAmount > 0) {
                swapAndLiquify(swapTokensAtAmount);
            }

            swapping = false;
        }

        bool takeFee = !swapping;

        if (takeFee && !_isExcludedFromFees[from]) {
            uint256 feeAmt;

            if (automatedMarketMakerPairs[to]) {
                // Sell transaction: Charge sell tax
                feeAmt = (amount * totalSellTax) / 100;
            } else if (automatedMarketMakerPairs[from]) {
                // Buy transaction: Charge buy tax
                feeAmt = (amount * totalBuyTax) / 100;
                require(
                    amount + balanceOf(to) <= maxWallet,
                    "Unable to exceed Max Wallet"
                );
                require(amount <= maxBuyAmount, "Unable to exceed Max buy");
                if (to == treasuryWallet) {
                    TotalBuyBacks = TotalBuyBacks + amount;
                }
            } else {
                // General transfer: Charge buy tax
                feeAmt = (amount * totalBuyTax) / 100;
                require(
                    amount + balanceOf(to) <= maxWallet,
                    "Unable to exceed Max Wallet"
                );
            }

            amount = amount - feeAmt;

            super._transfer(from, address(this), feeAmt);
        }
        super._transfer(from, to, amount);

        try dividendTracker.setBalance(from, balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(to, balanceOf(to)) {} catch {}
    }

    function swapAndLiquify(uint256 tokens) private {
        uint256 toSwap = tokens;

        swapTokensForETH(toSwap);
        uint256 contractrewardbalance = address(this).balance;
        uint256 totalTax = (totalSellTax);

        uint256 devAmt = (contractrewardbalance * sellTaxes.dev) / totalTax;
        if (devAmt > 0) {
            (bool success, ) = payable(devWallet).call{value: devAmt}("");
            require(success, "Failed to send ETH to dev wallet");
        }

        uint256 treasuryAmt = (contractrewardbalance * sellTaxes.treasury) /
            totalTax;

        if (treasuryAmt > 0) {
            (bool success, ) = payable(treasuryWallet).call{value: treasuryAmt}(
                ""
            );
            require(success, "Failed to send ETH to treasury wallet");
        }
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
}

contract DividendTracker is Ownable, DividendPayingToken {
    struct AccountInfo {
        address account;
        uint256 withdrawableDividends;
        uint256 totalDividends;
        uint256 lastClaimTime;
    }

    mapping(address => bool) public excludedFromDividends;

    mapping(address => uint256) public lastClaimTimes;
    mapping(address => uint256) public TotalClaimedByUser;

    event ExcludeFromDividends(address indexed account, bool value);
    event Claim(address indexed account, uint256 amount);

    constructor()
        DividendPayingToken(
            "MoonPrinter_DividendToken",
            "MoonPrinter_DividendToken"
        )
    {}

    function trackerRescueETH20Tokens(address recipient, address tokenAddress)
        external
        onlyOwner
    {
        IERC20(tokenAddress).transfer(
            recipient,
            IERC20(tokenAddress).balanceOf(address(this))
        );
    }

    function trackerForceSend(address recipient) external onlyOwner {
        (bool success, ) = payable(recipient).call{
            value: address(this).balance
        }("");
        require(success, "Failed to send ETH to wallet");
    }

    function _transfer(
        address,
        address,
        uint256
    ) internal pure override {
        require(false, "Dividend_Tracker: No transfers allowed");
    }

    function excludeFromDividends(address account, bool value)
        external
        onlyOwner
    {
        require(excludedFromDividends[account] != value);
        excludedFromDividends[account] = value;
        if (value == true) {
            _setBalance(account, 0);
        } else {
            _setBalance(account, balanceOf(account));
        }
        emit ExcludeFromDividends(account, value);
    }

    function getAccount(address account)
        public
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        AccountInfo memory info;
        info.account = account;
        info.withdrawableDividends = withdrawableDividendOf(account);
        info.totalDividends = accumulativeDividendOf(account);
        info.lastClaimTime = lastClaimTimes[account];
        return (
            info.account,
            info.withdrawableDividends,
            info.totalDividends,
            info.lastClaimTime,
            totalDividendsWithdrawn
        );
    }

    function setBalance(address account, uint256 newBalance)
        external
        onlyOwner
    {
        if (excludedFromDividends[account]) {
            return;
        }
        _setBalance(account, newBalance);
    }

    function updateLP_Token(address _lpToken) external onlyOwner {
        _Token = _lpToken;
    }

    function processAccount(address payable account)
        external
        onlyOwner
        returns (bool)
    {
        uint256 amount = _withdrawDividendOfUser(account);

        if (amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            TotalClaimedByUser[account] = TotalClaimedByUser[account] + amount;
            emit Claim(account, amount);
            return true;
        }
        return false;
    }
}