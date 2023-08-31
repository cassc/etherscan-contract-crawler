// LINKTREE: https://linktr.ee/liqshare.io
// LANDING: liqshare.io
// X: https://twitter.com/liqshare
// MEDIUM: https://medium.com/@liqshare.io
// TELEGRAM: https://t.me/liqshareio

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./LqsDividendTracker.sol";
import "./interfaces/IStaking.sol";

contract LqsToken is ERC20, Ownable {
    IUniswapRouter public router;
    address public pair;
    address public devWallet;
    IStaking public stakingPool;
    LqsDividendTracker public dividendTracker;

    bool private swapping;
    bool public swapEnabled = true;
    bool public claimEnabled;
    bool public tradingEnabled;

    uint256 public swapTokensAtAmount;
    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
    uint256 public maxWallet;

    struct Taxes {
        uint256 liquidity;
        uint256 dev;
        uint256 stakingPool;
    }

    Taxes public buyTaxes = Taxes(3, 2, 1);
    Taxes public sellTaxes = Taxes(3, 2, 1);

    uint256 public totalBuyTax = 6;
    uint256 public totalSellTax = 6;

    mapping(address => bool) public _isBot;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedFromMaxWallet;
    mapping(address => bool) public _automatedMarketMakerPairs;

    event SendDividends(uint256 tokensSwapped, uint256 amount);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event GasForProcessingUpdated(
        uint256 indexed newValue,
        uint256 indexed oldValue
    );
    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );

    constructor(
        address _devWallet,
        address _routerAddress,
        address _stakingPool
    ) ERC20("LIQShare", "LQS") {
        dividendTracker = new LqsDividendTracker();
        setDevWallet(_devWallet);

        IUniswapRouter _router = IUniswapRouter(_routerAddress);

        address _pair = IFactory(_router.factory()).createPair(
            address(this),
            _router.WETH()
        );

        router = _router;
        pair = _pair;
        setSwapTokensAtAmount(300_000);
        updateMaxWalletAmount(2_000_000);
        setMaxBuyAndSell(2_000_000, 2_000_000);

        _setAutomatedMarketMakerPair(_pair, true);

        stakingPool = IStaking(_stakingPool);
        stakingPool.init(address(this), _pair);

        dividendTracker.updateLP_Token(_pair);

        dividendTracker.excludeFromDividends(address(dividendTracker), true);
        dividendTracker.excludeFromDividends(_stakingPool, true);
        dividendTracker.excludeFromDividends(address(this), true);
        dividendTracker.excludeFromDividends(owner(), true);
        dividendTracker.excludeFromDividends(address(0xdead), true);
        dividendTracker.excludeFromDividends(address(_router), true);

        excludeFromMaxWallet(address(_pair), true);
        excludeFromMaxWallet(address(this), true);
        excludeFromMaxWallet(address(_router), true);
        excludeFromMaxWallet(_stakingPool, true);

        excludeFromFees(owner(), true);
        excludeFromFees(_devWallet, true);
        excludeFromFees(address(this), true);
        excludeFromFees(_stakingPool, true);

        _mint(owner(), 100_000_000 * (10 ** 18));
    }

    receive() external payable {}

    function updateDividendTracker(address newAddress) public onlyOwner {
        LqsDividendTracker newDividendTracker = LqsDividendTracker(
            payable(newAddress)
        );
        newDividendTracker.excludeFromDividends(
            address(newDividendTracker),
            true
        );
        newDividendTracker.excludeFromDividends(address(this), true);
        newDividendTracker.excludeFromDividends(owner(), true);
        newDividendTracker.excludeFromDividends(address(router), true);
        dividendTracker = newDividendTracker;
    }

    /// @notice Manual claim the dividends
    function claim() external {
        require(claimEnabled, "Claim not enabled");
        dividendTracker.processAccount(payable(msg.sender));
    }

    function updateMaxWalletAmount(uint256 newNum) public onlyOwner {
        require(newNum >= 1_000_000, "Cannot set maxWallet lower than 1%");
        maxWallet = newNum * 10 ** 18;
    }

    function setMaxBuyAndSell(
        uint256 maxBuy,
        uint256 maxSell
    ) public onlyOwner {
        require(maxBuy >= 1_000_000, "Cannot set maxbuy lower than 1% ");
        require(maxSell >= 500_000, "Cannot set maxsell lower than 0.5% ");
        maxBuyAmount = maxBuy * 10 ** 18;
        maxSellAmount = maxSell * 10 ** 18;
    }

    function setSwapTokensAtAmount(uint256 amount) public onlyOwner {
        swapTokensAtAmount = amount * 10 ** 18;
    }

    function excludeFromMaxWallet(
        address account,
        bool excluded
    ) public onlyOwner {
        _isExcludedFromMaxWallet[account] = excluded;
    }

    /// @notice Withdraw tokens sent by mistake.
    /// @param tokenAddress The address of the token to withdraw
    function rescueETH20Tokens(address tokenAddress) external onlyOwner {
        IERC20(tokenAddress).transfer(
            owner(),
            IERC20(tokenAddress).balanceOf(address(this))
        );
    }

    /// @notice Send remaining ETH to dev
    /// @dev It will send all ETH to dev
    function forceSend() external onlyOwner {
        uint256 ETHbalance = address(this).balance;
        (bool success, ) = payable(devWallet).call{value: ETHbalance}("");
        require(success);
    }

    function trackerRescueETH20Tokens(address tokenAddress) external onlyOwner {
        dividendTracker.trackerRescueETH20Tokens(msg.sender, tokenAddress);
    }

    function updateRouter(address newRouter) external onlyOwner {
        router = IUniswapRouter(newRouter);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(
            _isExcludedFromFees[account] != excluded,
            "Account is already the value of 'excluded'"
        );
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    /// @dev "true" to exlcude, "false" to include
    function excludeFromDividends(
        address account,
        bool value
    ) public onlyOwner {
        dividendTracker.excludeFromDividends(account, value);
    }

    function setDevWallet(address newWallet) public onlyOwner {
        devWallet = newWallet;
    }

    function setBuyTaxes(
        uint256 _liquidity,
        uint256 _dev,
        uint256 _staking
    ) external onlyOwner {
        require(_liquidity + _dev + _staking <= 20, "Fee must be <= 20%");
        buyTaxes = Taxes(_liquidity, _dev, _staking);
        totalBuyTax = _liquidity + _dev + _staking;
    }

    function setSellTaxes(
        uint256 _liquidity,
        uint256 _dev,
        uint256 _staking
    ) external onlyOwner {
        require(_liquidity + _dev + _staking <= 20, "Fee must be <= 20%");
        sellTaxes = Taxes(_liquidity, _dev, _staking);
        totalSellTax = _liquidity + _dev + _staking;
    }

    /// @notice Enable or disable internal swaps
    /// @dev Set "true" to enable internal swaps for liquidity, treasury and dividends
    function setSwapEnabled(bool _enabled) external onlyOwner {
        swapEnabled = _enabled;
    }

    function activateTrading() external onlyOwner {
        require(!tradingEnabled, "Trading already enabled");
        tradingEnabled = true;
    }

    function setClaimEnabled(bool state) external onlyOwner {
        claimEnabled = state;
    }

    /// @param bot The bot address
    /// @param value "true" to blacklist, "false" to unblacklist
    function setBot(address bot, bool value) external onlyOwner {
        require(_isBot[bot] != value);
        _isBot[bot] = value;
    }

    function setLP_Token(address _lpToken) external onlyOwner {
        dividendTracker.updateLP_Token(_lpToken);
    }

    /// @dev Set new pairs created due to listing in new DEX
    function setAutomatedMarketMakerPair(
        address newPair,
        bool value
    ) external onlyOwner {
        _setAutomatedMarketMakerPair(newPair, value);
    }

    function _setAutomatedMarketMakerPair(address newPair, bool value) private {
        require(
            _automatedMarketMakerPairs[newPair] != value,
            "Automated market maker pair is already set to that value"
        );
        _automatedMarketMakerPairs[newPair] = value;

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

    function withdrawableDividendOf(
        address account
    ) public view returns (uint256) {
        return dividendTracker.withdrawableDividendOf(account);
    }

    function dividendTokenBalanceOf(
        address account
    ) public view returns (uint256) {
        return dividendTracker.balanceOf(account);
    }

    function getAccountInfo(
        address account
    ) external view returns (address, uint256, uint256, uint256, uint256) {
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
            if (_automatedMarketMakerPairs[to]) {
                require(
                    amount <= maxSellAmount,
                    "You are exceeding maxSellAmount"
                );
            } else if (_automatedMarketMakerPairs[from])
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
            _automatedMarketMakerPairs[to] &&
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

        // If any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if (
            !_automatedMarketMakerPairs[to] && !_automatedMarketMakerPairs[from]
        ) takeFee = false;

        if (takeFee) {
            uint256 feeAmt;
            if (_automatedMarketMakerPairs[to])
                feeAmt = (amount * totalSellTax) / 100;
            else if (_automatedMarketMakerPairs[from])
                feeAmt = (amount * totalBuyTax) / 100;

            amount = amount - feeAmt;
            super._transfer(from, address(this), feeAmt);
        }
        super._transfer(from, to, amount);

        try dividendTracker.setBalance(from, balanceOf(from)) {} catch {}
        try dividendTracker.setBalance(to, balanceOf(to)) {} catch {}
    }

    function swapAndLiquify(uint256 tokens) private {
        uint256 toSwapForLiq = ((tokens * sellTaxes.liquidity) / totalSellTax) /
            2;
        uint256 tokensToAddLiquidityWith = ((tokens * sellTaxes.liquidity) /
            totalSellTax) / 2;
        uint256 toSwapForDev = (tokens * sellTaxes.dev) / totalSellTax;
        uint256 toStakingPool = (tokens * sellTaxes.stakingPool) / totalSellTax;

        super._transfer(address(this), address(stakingPool), toStakingPool);
        try stakingPool.updateReward(toStakingPool) {} catch {}

        swapTokensForETH(toSwapForLiq);

        uint256 currentbalance = address(this).balance;

        if (currentbalance > 0) {
            // Add liquidity to uni
            addLiquidity(tokensToAddLiquidityWith, currentbalance);
        }

        swapTokensForETH(toSwapForDev);

        uint256 EthTaxBalance = address(this).balance;

        // Send ETH to dev
        uint256 devAmt = EthTaxBalance;

        if (devAmt > 0) {
            (bool success, ) = payable(devWallet).call{value: devAmt}("");
            require(success, "Failed to send ETH to dev wallet");
        }

        uint256 lpBalance = IERC20(pair).balanceOf(address(this));

        //Send LP to dividends
        uint256 dividends = lpBalance;

        if (dividends > 0) {
            bool success = IERC20(pair).transfer(
                address(dividendTracker),
                dividends
            );
            if (success) {
                dividendTracker.distributeLPDividends(dividends);
                emit SendDividends(tokens, dividends);
            }
        }
    }

    function manualLiquidityDistribution(uint256 amount) public onlyOwner {
        bool success = IERC20(pair).transferFrom(
            msg.sender,
            address(dividendTracker),
            amount
        );
        if (success) {
            dividendTracker.distributeLPDividends(amount);
        }
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // Make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // Accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // Approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tokenAmount);

        // Add the liquidity
        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // Slippage is unavoidable
            0, // Slippage is unavoidable
            address(this),
            block.timestamp
        );
    }
}