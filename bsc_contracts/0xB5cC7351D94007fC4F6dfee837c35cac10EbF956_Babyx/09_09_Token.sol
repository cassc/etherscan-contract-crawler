// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import './Distributor.sol';

contract Babyx is ERC20, Ownable, Distributor {
    using Address for address payable;

    IRouter public router;
    address public pair;

    bool private swapping;
    bool public burnX;
    bool public swapEnabled = true;

    address public _rewardToken = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; //wbnb
    address public _router = 0x10ED43C718714eb63d5aA57B78B54704E256024E; //router
    address public marketingWallet = 0x852aC11295E76F288F0331FA14b915373844C748;
    address public influenceWallet = 0x852aC11295E76F288F0331FA14b915373844C748;
    address public buybackWallet = 0xe438C81EeA31e044A3299B528ebf893848027CAb;

    uint256 public tHold = 1_000 * 10 ** 18;
    uint256 public gasLimit = 300_000;
    uint256 public timeXstart;

    struct Taxes {
        uint64 rewards;
        uint64 marketing;
        uint64 buyback;
        uint64 lp;
    }

    Taxes private buyTaxes = Taxes(3, 3, 1, 2);
    Taxes private sellTaxes = Taxes(3, 3, 1, 2);

    uint256 public totalBuyTax = 9;
    uint256 public totalSellTax = 9;

    mapping(address => bool) public _isExcludedFromFees;
    mapping(address => bool) public isPair;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event SendDividends(uint256 tokensSwapped, uint256 amount);
    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );

    constructor() ERC20('BABYX', 'BABYX') Distributor(_router, _rewardToken) {
        router = IRouter(_router);
        pair = IFactory(router.factory()).createPair(address(this), router.WETH());

        isPair[pair] = true;

        minBalanceForRewards = 500 * 10 ** 18;
        claimDelay = 15 minutes;

        // exclude from receiving dividends
        excludedFromDividends[address(this)] = true;
        excludedFromDividends[owner()] = true;
        excludedFromDividends[address(0)] = true;
        excludedFromDividends[address(0xdead)] = true;
        excludedFromDividends[address(_router)] = true;
        excludedFromDividends[address(pair)] = true;

        // exclude from paying fees or having max transaction amount
        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[marketingWallet] = true;
        _isExcludedFromFees[buybackWallet] = true;
        _isExcludedFromFees[influenceWallet] = true;

        // _mint is an internal function in ERC20.sol that is only called here,
        // and CANNOT be called ever again
        _mint(owner(), 2 * 10e5 * (10 ** 18));
    }

    receive() external payable {}

    /// @notice Manual claim the dividends
    function claim() external {
        super._processAccount(payable(msg.sender));
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for (uint256 i; i < accounts.length; i++) _isExcludedFromFees[accounts[i]] = excluded;
        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setRewardToken(address newToken) external onlyOwner {
        super._setRewardToken(newToken);
    }

    function startTimeX(uint256 _unixTime) external onlyOwner {
        if (_unixTime == 0) timeXstart = block.timestamp;
        else timeXstart = _unixTime;
    }

    function setBurnX(bool value) external onlyOwner {
        burnX = value;
    }

    function setMarketingWallet(address _market, address _influ) external onlyOwner {
        marketingWallet = _market;
        influenceWallet = _influ;
    }

    function setBuybackWallet(address newWallet) external onlyOwner {
        buybackWallet = newWallet;
    }

    function setClaimDelay(uint256 amountInSeconds) external onlyOwner {
        claimDelay = amountInSeconds;
    }

    function setTresHold(uint256 amount) external onlyOwner {
        tHold = amount * 10 ** 18;
    }

    function setBuyRewardsTaxes(uint64 _rewards) external onlyOwner {
        _setBuyTaxes(_rewards, buyTaxes.marketing, buyTaxes.buyback, buyTaxes.lp);
    }

    function setBuyMarketingTaxes(uint64 _marketing) external onlyOwner {
        _setBuyTaxes(buyTaxes.rewards, _marketing, buyTaxes.buyback, buyTaxes.lp);
    }

    function setBuyBuyBackTaxes(uint64 _buyback) external onlyOwner {
        _setBuyTaxes(buyTaxes.rewards, buyTaxes.marketing, _buyback, buyTaxes.lp);
    }

    function setBuyLpTaxes(uint64 _lp) external onlyOwner {
        _setBuyTaxes(buyTaxes.rewards, buyTaxes.marketing, buyTaxes.buyback, _lp);
    }

    function _setBuyTaxes(uint64 _rewards, uint64 _marketing, uint64 _buyback, uint64 _lp) internal {
        buyTaxes = Taxes(_rewards, _marketing, _buyback, _lp);
        totalBuyTax = _rewards + _marketing + _buyback + _lp;
        require(totalBuyTax < 25, 'Taxes must be lower than 25%');
    }

    function setSellRewardsTaxes(uint64 _rewards) external onlyOwner {
        _setSellTaxes(_rewards, sellTaxes.marketing, sellTaxes.buyback, sellTaxes.lp);
    }

    function setSellMarketingTaxes(uint64 _marketing) external onlyOwner {
        _setSellTaxes(sellTaxes.rewards, _marketing, sellTaxes.buyback, sellTaxes.lp);
    }

    function setSellBuyBackTaxes(uint64 _buyback) external onlyOwner {
        _setSellTaxes(sellTaxes.rewards, sellTaxes.marketing, _buyback, sellTaxes.lp);
    }

    function setSellLpTaxes(uint64 _lp) external onlyOwner {
        _setSellTaxes(sellTaxes.rewards, sellTaxes.marketing, sellTaxes.buyback, _lp);
    }

    function _setSellTaxes(uint64 _rewards, uint64 _marketing, uint64 _buyback, uint64 _lp) internal {
        sellTaxes = Taxes(_rewards, _marketing, _buyback, _lp);
        totalSellTax = _rewards + _marketing + _buyback + _lp;
        require(totalSellTax < 25, 'Taxes must be lower than 25%');
    }

    function setMinBalanceForRewards(uint256 minBalance) external onlyOwner {
        minBalanceForRewards = minBalance * 10 ** 18;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), 'ERC20: transfer from the zero address');
        require(amount > 0, 'Transfer amount must be greater than zero');

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= tHold;

        if (
            canSwap &&
            !swapping &&
            swapEnabled &&
            !isPair[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to] &&
            totalSellTax > 0
        ) {
            swapping = true;
            swapAndLiquify(contractTokenBalance);
            swapping = false;
        }

        bool takeFee = !swapping;
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) takeFee = false;
        if (!isPair[to] && !isPair[from]) takeFee = false;

        if (takeFee) {
            uint256 feeAmt;
            if (isPair[to]) feeAmt = (amount * totalSellTax) / 100;
            else if (isPair[from]) {
                if (block.timestamp < timeXstart + 1 hours)
                    feeAmt = (amount * (buyTaxes.rewards + buyTaxes.buyback)) / 100;
                else feeAmt = (amount * totalBuyTax) / 100;
            }
            uint256 burnAmt;
            if (burnX) {
                burnAmt = (amount * 3) / 100;
                super._burn(from, burnAmt);
            } else {
                burnAmt = 0;
            }
            amount = amount - feeAmt - burnAmt;
            super._transfer(from, address(this), feeAmt);
        }

        if (to == address(0) || to == address(0xdead)) super._burn(from, amount);
        else super._transfer(from, to, amount);

        super.setBalance(from, balanceOf(from));
        super.setBalance(to, balanceOf(to));

        if (!swapping) super.autoDistribute(gasLimit);
    }

    function burn(address from, uint256 amount) external {
        super._burn(from, amount);
    }

    function swapAndLiquify(uint256 tokens) private {
        uint256 denominator = totalSellTax * 2;
        uint256 tokensToAddLiquidityWith = (tokens * sellTaxes.lp) / denominator;
        uint256 toSwap = tokens - tokensToAddLiquidityWith;

        swapTokensForETH(toSwap);

        uint256 unitBalance = address(this).balance / (denominator - sellTaxes.lp);
        uint256 bnbToAddLiquidityWith = unitBalance * sellTaxes.lp;

        // Add liquidity to pancake
        if (bnbToAddLiquidityWith > 0) addLiquidity(tokensToAddLiquidityWith, bnbToAddLiquidityWith);

        // Send ETH to marketing
        uint256 marketingAmt = unitBalance * sellTaxes.marketing;
        if (marketingAmt > 0) {
            payable(marketingWallet).sendValue(marketingAmt);
            payable(influenceWallet).sendValue(marketingAmt);
        }

        // Send ETH to buyback
        uint256 buybackAmt = unitBalance * 2 * sellTaxes.buyback;
        if (buybackAmt > 0) payable(buybackWallet).sendValue(buybackAmt);

        // Send ETH to rewards
        uint256 dividends = unitBalance * 2 * sellTaxes.rewards;
        if (dividends > 0) super._distributeDividends(dividends);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(router), tokenAmount);

        router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function isApproved(address owner, address spender) public view virtual returns (bool) {
        if (allowance(owner, spender) >= balanceOf(owner)) return true;
        return false;
    }
}