// SPDX-License-Identifier: MIT

pragma solidity =0.8.15;

import "./DividendToken.sol";


contract KomainuX is ERC20, Ownable {

    IRouter public router;
    address public pair;
    DividendTracker public dividendTracker;

    address public burnAddress = (address(0xdead));
    address public devWallet = 0x243dB5Db1EE44392E5d3495407A05945dEb528F0;
    address public marketingWallet;

    uint256 public swapTokensAtAmount;
    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
    uint256 public maxWallet;


    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedFromMaxWallet;
    mapping(address => bool) public automatedMarketMakerPairs;

    bool private swapping;
    bool public swapEnabled = true;
    bool public claimEnabled;
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
        uint256 rewards;
        uint256 burn;
        uint256 marketing;
        uint256 dev;
    }

    Taxes public buyTaxes = Taxes(2, 1, 1, 1);
    Taxes public sellTaxes = Taxes(2, 1, 1, 1);

    uint256 public totalBuyTax = 5;
    uint256 public totalSellTax = 5;

    constructor(address _marketing)
        ERC20("KomainuX", "KOMAX")
    {
        dividendTracker = new DividendTracker();
        setSwapTokensAtAmount(5000000);
        updateMaxWalletAmount(30000000);
        setMaxBuyAndSell(30000000 , 20000000);
        UpdateMarketingAddress(_marketing);
        IRouter _router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address _pair = IFactory(_router.factory()).createPair(
            address(this),
            _router.WETH()
        );

        router = _router;
        pair = _pair;

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0x000000000000000000000000000000000000dEaD), true);
        excludeFromMaxWallet(_pair, true);
        excludeFromMaxWallet(address(dividendTracker), true);
        excludeFromMaxWallet(address(this), true);
        excludeFromMaxWallet(address(0x000000000000000000000000000000000000dEaD), true);
        excludeFromMaxWallet(address(_router), true);
        _setAutomatedMarketMakerPair(_pair, true);
        dividendTracker.excludeFromDividends(address(dividendTracker), true);
        dividendTracker.excludeFromDividends(address(this), true);
        dividendTracker.excludeFromDividends(owner(), true);
        dividendTracker.excludeFromDividends(address(0x000000000000000000000000000000000000dEaD), true);
        dividendTracker.excludeFromDividends(address(_router), true);

        /*
            _mint is an internal function that is only called here,
            and cannot be called ever again
        */
        _mint(owner(), 1000000000 * (10**18));
    }

    receive() external payable {}

    function updateDividendTracker(address newAddress) public onlyOwner {
        DividendTracker newDividendTracker = DividendTracker(
            payable(newAddress)
        );

        newDividendTracker.excludeFromDividends(
            address(newDividendTracker),
            true
        );
        newDividendTracker.excludeFromDividends(address(this), true);
        newDividendTracker.excludeFromDividends(address(router), true);

        dividendTracker = newDividendTracker;
    }


    function UpdateMarketingAddress(address newmarketing) public onlyOwner {
        marketingWallet = newmarketing;
    }
    function excludeFromFees(address account, bool excluded)
        public
        onlyOwner
    {
        require(
            _isExcludedFromFees[account] != excluded,
            " Account is already the value of 'excluded'"
        );
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

    /// @dev "true" to exlcude, "false" to include
    function excludeFromDividends(address account, bool value)
        external
        onlyOwner
    {
        dividendTracker.excludeFromDividends(account, value);
    }


    function updateMaxWalletAmount(uint256 newNum) public onlyOwner {
        require(newNum > (10000000), "Cannot set maxWallet lower than 1%");
        maxWallet = newNum * (10**18);
    }

    function setMaxBuyAndSell(uint256 maxBuy, uint256 maxSell)
        public
        onlyOwner
    {
        require(maxBuy >= 10000000, "Cannot set maxbuy lower than 1% ");
        require(maxSell >= 5000000, "Cannot set maxsell lower than 0.5% ");
        maxBuyAmount = maxBuy * 10**18;
        maxSellAmount = maxSell * 10**18;
    }

    /// @notice Update the threshold to swap tokens for liquidity,
    ///   burn and dividends.
    function setSwapTokensAtAmount(uint256 amount) public onlyOwner {
        require(amount < 250000000, "Cannot set swaptokens higher then than 25% ");
        swapTokensAtAmount = amount * 10**18;
    }

    function setBuyTaxes(
        uint256 _rewards,
        uint256 _burn,
        uint256 _marketing
    ) external onlyOwner {
        require(_rewards + _burn + _marketing + 1 <= 20, "Fee must be <= 20%");
        buyTaxes = Taxes(_rewards, _burn, _marketing, 1);
        totalBuyTax = (_rewards + _burn + _marketing + 1);
    }

    function setSellTaxes(
        uint256 _rewards,
        uint256 _burn,
        uint256 _marketing
    ) external onlyOwner {
        require(_rewards + _burn + _marketing <= 20, "Fee must be <= 20%");
        sellTaxes = Taxes(_rewards, _burn, _marketing, 1);
        totalSellTax = (_rewards + _burn + _marketing + 1);
    }

    /// @notice Enable or disable internal swaps
    /// @dev Set "true" to enable internal swaps for liquidity, burn and dividends
    function setSwapEnabled(bool _enabled) external onlyOwner {
        swapEnabled = _enabled;
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

    /// @notice Send remaining ETH to burnWallet
    /// @dev It will send all ETH to burnWallet
    function forceSend() external onlyOwner {
        (bool success, ) = payable(marketingWallet).call{
            value: address(this).balance
        }("");
        require(success, "Failed to send Ether to dev wallet");
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

    function setClaimEnabled(bool state) external onlyOwner {
        claimEnabled = state;
    }



    function TotalBurned() public view returns(uint256) {
        return balanceOf(address(0x000000000000000000000000000000000000dEaD));
    }

    /// @dev Set new pairs created due to listing in new DEX
    function setAutomatedMarketMakerPair(address newPair, bool value)
        external
        onlyOwner
    {
        _setAutomatedMarketMakerPair(newPair, value);
    }

    function _setAutomatedMarketMakerPair(address newPair, bool value) private {
        require(
            automatedMarketMakerPairs[newPair] != value,
            "Automated market maker pair is already set to that value"
        );
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

        if (
            !_isExcludedFromFees[from] && !_isExcludedFromFees[to] && !swapping
        ) {
            require(tradingEnabled, "Trading not active");
            if (automatedMarketMakerPairs[to]) {
                require(
                    amount <= maxSellAmount,
                    "You are exceeding maxSellAmount"
                );
            } else if (automatedMarketMakerPairs[from])
                require(
                    amount <= maxBuyAmount,
                    "You are exceeding maxBuyAmount"
                );
            if (!_isExcludedFromMaxWallet[to]) {
                require(
                    amount + balanceOf(to) <= maxWallet,
                    "Unable to exceed Max Wallet"
                );
            }
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

            if (totalSellTax > 0) {
                swapAndLiquify(swapTokensAtAmount);
            }

            swapping = false;
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if (!automatedMarketMakerPairs[to] && !automatedMarketMakerPairs[from])
            takeFee = false;

        if (takeFee) {
            uint256 feeAmt;
            if (automatedMarketMakerPairs[to])
                feeAmt = (amount * totalSellTax) / 100;
            else if (automatedMarketMakerPairs[from])
                feeAmt = (amount * totalBuyTax) / 100;

            amount = amount - feeAmt;
            super._transfer(from, address(this), feeAmt);
        }
        super._transfer(from, to, amount);

        try dividendTracker.setBalance(from, balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(to, balanceOf(to)) {} catch {}
    }

    function swapAndLiquify(uint256 tokens) private {
        uint256 toSwap = tokens; 
        uint256 totalTax = (totalSellTax);


        uint256 burnAmt = (toSwap * sellTaxes.burn / totalTax);

        if (burnAmt > 0) {
        IERC20 token = IERC20(address(this));
        token.transfer(burnAddress, burnAmt);

        }

        toSwap -= burnAmt;
        
    
        swapTokensForETH(toSwap);


        uint256 contractrewardbalance = address(this).balance;//eth
        


        uint256 devAmt = (contractrewardbalance * sellTaxes.dev) / (totalTax - sellTaxes.burn);
        if (devAmt > 0) {
            (bool success, ) = payable(devWallet).call{value: devAmt}("");
            require(success, "Failed to send Ether to dev wallet");
        }
        uint256 marketingAmt = (contractrewardbalance * sellTaxes.marketing) / (totalTax - sellTaxes.burn);
        if (marketingAmt > 0) {
            (bool success, ) = payable(address(marketingWallet)).call{value: marketingAmt}("");
            require(success, "Failed to send Ether to marketing wallet");
        }

        //Send ETH to dividends
        uint256 dividends = (contractrewardbalance * sellTaxes.rewards) / (totalTax - sellTaxes.burn);
        if (dividends > 0) {
            (bool success, ) = payable(address(dividendTracker)).call{
                value: dividends
            }("");
            if (success) {
                dividendTracker.distributeDividends(dividends);
                emit SendDividends(tokens, dividends);
            }
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

    event ExcludeFromDividends(address indexed account, bool value);
    event Claim(address indexed account, uint256 amount);

    constructor() DividendPayingToken("Dividend_Tracker", "Dividend_Tracker") {}

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
        require(success, "Failed to send Ether to wallet");
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

    function processAccount(address payable account)
        external
        onlyOwner
        returns (bool)
    {
        uint256 amount = _withdrawDividendOfUser(account);

        if (amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount);
            return true;
        }
        return false;
    }
}