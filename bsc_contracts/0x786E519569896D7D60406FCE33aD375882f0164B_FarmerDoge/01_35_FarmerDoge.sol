// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

import "./FarmerDogeDividendTracker.sol";

/// @notice Farmer Doge main contract
/// @custom:security-contact [email protected]
contract FarmerDoge is Initializable, ERC20Upgradeable, OwnableUpgradeable, PausableUpgradeable, UUPSUpgradeable {
    using SafeMath for uint256;

    /// @notice The PCS router used for internal swaps
    IUniswapV2Router02 public pancakeSwapRouter;
    /// @notice The PCS pair to send liquidity to
    address public pancakeSwapLpPair;

    /// @notice The dividend tracker is a separate un-tradable ERC20 token that is used to determine dividend payouts
    FarmerDogeDividendTracker public dividendTracker;

    /// @notice The maximum amount of tokens allowed in any one wallet (Initially max supply)
    uint256 public maxWalletAmount;

    /// @notice The maximum amount of tokens allowed in any one transaction (Initially max supply)
    uint256 public maxTxAmount;

    bool private _swapping;
    /// @notice The minimum tokens to accumulate before calling `swapAndLiquify` (Initially 0.01% of supply)
    uint256 public minimumTokensBeforeSwap;
    /// @notice The amount of gas to use to process wallet rewards during a transaction
    uint256 public gasForProcessing;

    /// @notice The wallet that will receive fees paid via the marketing tax
    address public marketingWallet;
    /// @notice The wallet that will receive LP from fees paid via the liquidity tax
    address public liquidityWallet;

    mapping(address => bool) private _isAllowedToTradeWhenDisabled;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromMaxTransactionLimit;
    mapping(address => bool) private _isExcludedFromMaxWalletLimit;
    mapping(address => bool) private automatedMarketMakerPairs;

    uint256 private _liquidityFee;
    uint256 private _marketingFee;
    uint256 private _holdersFee;
    uint256 private _totalFee;

    uint256 private liquidityFeeOnBuy;
    uint256 private liquidityFeeOnSell;
    uint256 private marketingFeeOnBuy;
    uint256 private marketingFeeOnSell;
    uint256 private holdersFeeOnBuy;
    uint256 private holdersFeeOnSell;
    uint256 private totalFeeOnBuy;
    uint256 private totalFeeOnSell;
    address[] private tokenToBNBPath;

    uint256 private _liquidityTokensToSwap;
    uint256 private _marketingTokensToSwap;
    uint256 private _holdersTokensToSwap;

    event AutomatedMarketMakerPairChange(address indexed pair, bool indexed value);
    event DividendTrackerChange(address indexed newAddress, address indexed oldAddress);
    event UniswapV2RouterChange(address indexed newAddress, address indexed oldAddress);
    event WalletChange(string indexed indentifier, address indexed newWallet, address indexed oldWallet);
    event GasForProcessingChange(uint256 indexed newValue, uint256 indexed oldValue);
    event FeeChange(string indexed identifier, uint256 liquidityFee, uint256 marketingFee, uint256 holdersFee);
    event MaxTransactionAmountChange(uint256 indexed newValue, uint256 indexed oldValue);
    event MaxWalletAmountChange(uint256 indexed newValue, uint256 indexed oldValue);
    event ExcludeFromFeesChange(address indexed account, bool isExcluded);
    event ExcludeFromMaxTransferChange(address indexed account, bool isExcluded);
    event ExcludeFromMaxWalletChange(address indexed account, bool isExcluded);
    event AllowedWhenTradingDisabledChange(address indexed account, bool isExcluded);
    event MinTokenAmountBeforeSwapChange(uint256 indexed newValue, uint256 indexed oldValue);
    event DividendsSent(uint256 tokensSwapped);
    event MarketingFundsSent(uint256 tokensSwapped);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 bnbReceived, uint256 tokensIntoLiqudity);
    event ClaimBNBOverflow();
    event DividendTokenChange(address newDividendToken);
    event ProcessedDividendTracker(
        uint256 iterations,
        uint256 claims,
        uint256 lastProcessedIndex,
        bool indexed automatic,
        uint256 gas,
        address indexed processor
    );
    event FeesApplied(uint256 liquidityFee, uint256 marketingFee, uint256 holdersFee, uint256 totalFee);
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice This function initializes the proxy contract
    /// @dev The tracker factory is create separately to avoid bloating the main contract
    function initialize(FarmerDogeDividendTracker tracker) public initializer {
        __ERC20_init("FarmerDoge", "CROP");
        __Ownable_init();
        __UUPSUpgradeable_init();

        _pause();

        marketingWallet = 0xb914fF525be446A21751343193b7366DEE3BC253;
        liquidityWallet = 0xb914fF525be446A21751343193b7366DEE3BC253;

        uint256 initialSupply = 10000000000 * (10 ** 18);

        gasForProcessing = 740000;
        minimumTokensBeforeSwap = SafeMath.div(initialSupply, 10000);

        maxWalletAmount = initialSupply;

        maxTxAmount = initialSupply;

        IUniswapV2Router02 _pancakeRouter = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

        address _pancakeSwapPair = IUniswapV2Factory(_pancakeRouter.factory())
            .createPair(address(this), _pancakeRouter.WETH());
        pancakeSwapRouter = _pancakeRouter;
        pancakeSwapLpPair = _pancakeSwapPair;

        liquidityFeeOnBuy = 1;
        liquidityFeeOnSell = 1;
        marketingFeeOnBuy = 1;
        marketingFeeOnSell = 3;
        holdersFeeOnBuy = 3;
        holdersFeeOnSell = 11;
        totalFeeOnBuy = 5;
        totalFeeOnSell = 15;

        tokenToBNBPath = new address[](2);
        tokenToBNBPath[0] = address(this);
        tokenToBNBPath[1] = pancakeSwapRouter.WETH();

        dividendTracker = tracker;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[address(dividendTracker)] = true;

        _isAllowedToTradeWhenDisabled[owner()] = true;

        _isExcludedFromMaxTransactionLimit[address(dividendTracker)] = true;
        _isExcludedFromMaxTransactionLimit[address(this)] = true;

        _isExcludedFromMaxWalletLimit[_pancakeSwapPair] = true;
        _isExcludedFromMaxWalletLimit[address(dividendTracker)] = true;
        _isExcludedFromMaxWalletLimit[address(_pancakeRouter)] = true;
        _isExcludedFromMaxWalletLimit[address(this)] = true;
        _isExcludedFromMaxWalletLimit[owner()] = true;

        _mint(owner(), initialSupply);
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    onlyOwner
    override
    {}

    receive() external payable {}

    /// @notice Pauses trading for the token
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }
    /// @notice Unpauses trading for the token
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    function initializeTracker() external onlyOwner {
        dividendTracker.setPancakeSwapRouter(pancakeSwapRouter);

        // Initial reward is BUSD
        dividendTracker.setRewardToken(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
        dividendTracker.excludeFromDividends(pancakeSwapLpPair, true);
        dividendTracker.excludeFromDividends(address(this), true);
    }

    /// @notice Sets whether an address is an LP pair or not. This is used to determine if fees should be applied or not
    /// @param pair The LP pair address to add to the list of AMMs
    /// @param value true if the address should be considered and AMM pair, false otherwise
    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        automatedMarketMakerPairs[pair] = value;
        if (value) {
            dividendTracker.excludeFromDividends(pair, true);
        }
        emit AutomatedMarketMakerPairChange(pair, value);
    }
    /// @notice Sets a boolean that determines if the account can trading when the contract is paused
    /// @param account The account to allow to trade when paused.
    /// @param allowed true if the account is allowed to trade while paused, false otherwise
    function allowTradingWhenDisabled(address account, bool allowed) external onlyOwner {
        _isAllowedToTradeWhenDisabled[account] = allowed;
        emit AllowedWhenTradingDisabledChange(account, allowed);
    }
    /// @notice Sets a boolean that determines if the account is exempt from fees
    /// @param account The account to exempt from fees
    /// @param excluded true if the account is excluded from fees, false otherwise
    function excludeFromFees(address account, bool excluded) external onlyOwner {
        require(account != address(this), "Account != contract");
        _isExcludedFromFee[account] = excluded;
        emit ExcludeFromFeesChange(account, excluded);
    }
    /// @notice Sets a boolean that determines if the account is excluded from dividends
    /// @param account The account to exempt from dividends
    /// @param excluded true if the account is excluded from dividends, false otherwise
    function excludeFromDividends(address account, bool excluded) external onlyOwner {
        dividendTracker.excludeFromDividends(account, excluded);
    }
    /// @notice Sets a boolean that determines if the account is exempt from the max transaction limit
    /// @param account The account to exempt from the max transaction limit
    /// @param excluded true if the account is exempt from the max transaction limit, false otherwise
    function excludeFromMaxTransactionLimit(address account, bool excluded) external onlyOwner {
        _isExcludedFromMaxTransactionLimit[account] = excluded;
        emit ExcludeFromMaxTransferChange(account, excluded);
    }
    /// @notice Sets a boolean that determines if the account is exempt from the max wallet limit
    /// @param account The account to exempt from the max wallet limit
    /// @param excluded true if the account is exempt from the max wallet limit, false otherwise
    function excludeFromMaxWalletLimit(address account, bool excluded) external onlyOwner {
        _isExcludedFromMaxWalletLimit[account] = excluded;
        emit ExcludeFromMaxWalletChange(account, excluded);
    }
    /// @notice Sets the liquidity and marketing wallets that will receive fees
    /// @param newLiquidityWallet The new  wallet to receive liquidity fees
    /// @param newMarketingWallet The new wallet to receive marketing fees
    function setWallets(address newLiquidityWallet, address newMarketingWallet) external onlyOwner {
        require(newLiquidityWallet != address(0), "liquidity wallet can't be 0");
        require(newMarketingWallet != address(0), "marketing wallet can't be 0");

        emit WalletChange("liquidityWallet", newLiquidityWallet, liquidityWallet);
        liquidityWallet = newLiquidityWallet;
        emit WalletChange("marketingWallet", newMarketingWallet, marketingWallet);
        marketingWallet = newMarketingWallet;
    }
    /// @notice Sets the fees that will be applied to buys (Total fees can not be greater than 15%)
    /// @param _liquidityFeeOnBuy The buy fee in % that will be send to the liquidity wallet
    /// @param _marketingFeeOnBuy The buy fee in % that will be sent to the marketing wallet
    /// @param _holdersFeeOnBuy The buy fee in % that will be used to pay dividend rewards
    function setBaseFeesOnBuy(uint256 _liquidityFeeOnBuy, uint256 _marketingFeeOnBuy, uint256 _holdersFeeOnBuy) public onlyOwner {
        require((_liquidityFeeOnBuy + _marketingFeeOnBuy + _holdersFeeOnBuy) <= 15, "Buy taxes !> 15%");
        liquidityFeeOnBuy = _liquidityFeeOnBuy;
        marketingFeeOnBuy = _marketingFeeOnBuy;
        holdersFeeOnBuy = _holdersFeeOnBuy;
        totalFeeOnBuy = _liquidityFeeOnBuy + _marketingFeeOnBuy + _holdersFeeOnBuy;
        emit FeeChange("baseFees-Buy", _liquidityFeeOnBuy, _marketingFeeOnBuy, _holdersFeeOnBuy);
    }
    /// @notice Sets the fees that will be applied to sells (Total fees can not be greater than 15%)
    /// @param _liquidityFeeOnSell The sell fee in % that will be send to the liquidity wallet
    /// @param _marketingFeeOnSell The sell fee in % that will be sent to the marketing wallet
    /// @param _holdersFeeOnSell The sell fee in % that will be used to pay dividend rewards
    function setBaseFeesOnSell(uint256 _liquidityFeeOnSell, uint256 _marketingFeeOnSell, uint256 _holdersFeeOnSell) public onlyOwner {
        require((_liquidityFeeOnSell + _marketingFeeOnSell + _holdersFeeOnSell) <= 15, "Sell taxes !> 15%");
        liquidityFeeOnSell = _liquidityFeeOnSell;
        marketingFeeOnSell = _marketingFeeOnSell;
        holdersFeeOnSell = _holdersFeeOnSell;
        totalFeeOnSell = _liquidityFeeOnSell + _marketingFeeOnSell + _holdersFeeOnSell;
        emit FeeChange("baseFees-Sell", _liquidityFeeOnSell, _marketingFeeOnSell, _holdersFeeOnSell);
    }
    /// @notice The amount of gas that will be used to process dividends in each transaction (Must be < 150000)
    /// @param gas The amount of gas used to process wallets during transactions
    function setGasForProcessing(uint256 gas) public onlyOwner {
        require(gas <= 1500000, "Gas for processing > 1500000");
        emit GasForProcessingChange(gas, gasForProcessing);
        gasForProcessing = gas;
    }
    /// @notice The maximum transaction amount (Must be > 1% of supply)
    /// @param newMaxTxAmount The maximum transaction amount to set
    function setMaxTransactionAmount(uint256 newMaxTxAmount) public onlyOwner {
        require((newMaxTxAmount >= (totalSupply().div(100))), "Error: max tx lower than 1%");
        emit MaxTransactionAmountChange(newMaxTxAmount, maxTxAmount);
        maxTxAmount = newMaxTxAmount;
    }
    /// @notice The maximum wallet amount (Must be > 1% of supply)
    /// @param newMaxWalletAmount The maximum wallet amount to set
    function setMaxWalletAmount(uint256 newMaxWalletAmount) public onlyOwner {
        require((newMaxWalletAmount >= (totalSupply().div(100))), "Error: max wallet lower than 1%");
        emit MaxWalletAmountChange(newMaxWalletAmount, maxWalletAmount);
        maxWalletAmount = newMaxWalletAmount;
    }
    /// @notice The minimum amount of tokens to accumlate before calling `swapAndLiquify`
    /// @param newMinTokensBeforeSwap The minimum tokens before swap to set
    function setMinimumTokensBeforeSwap(uint256 newMinTokensBeforeSwap) public onlyOwner {
        require(newMinTokensBeforeSwap >= 10 ** 18, "Min must be >= 10**18" );
        emit MinTokenAmountBeforeSwapChange(newMinTokensBeforeSwap, minimumTokensBeforeSwap);
        minimumTokensBeforeSwap = newMinTokensBeforeSwap;
    }
    /// @notice The new reward token to pay out in dividends in
    /// @param newDividendToken The new token to set that the dividends will be paid in
    function setDividendToken(address newDividendToken) external onlyOwner {
        emit DividendTokenChange(newDividendToken);
        dividendTracker.setRewardToken(newDividendToken);
    }
    /// @notice Claims BNB overflow from math precision remainders
    function claimBNBOverflow() external onlyOwner {
        (bool success,) = address(owner()).call{value : address(this).balance}("");
        if (success) {
            emit ClaimBNBOverflow();
        }
    }
    /// @notice Get the fees incurred on buys
    /// @return liquidityFee The buy fee applied to liquidity
    /// @return marketingFee The buy fee applied to marketing
    /// @return holdersFee The buy fee applied to rewards for the holders
    function getBaseBuyFees() external view returns (uint256 liquidityFee, uint256 marketingFee, uint256 holdersFee){
        return (liquidityFeeOnBuy, marketingFeeOnBuy, holdersFeeOnBuy);
    }
    /// @notice Get the fees incurred on sells
    /// @return liquidityFee The sell fee applied to liquidity
    /// @return marketingFee The sell fee applied to marketing
    /// @return holdersFee The sell fee applied to rewards for the holders
    function getBaseSellFees() external view returns (uint256 liquidityFee, uint256 marketingFee, uint256 holdersFee){
        return (liquidityFeeOnSell, marketingFeeOnSell, holdersFeeOnSell);
    }
    /// @notice Allows retrieval of any ERC20 token that was sent to the contract address
    /// @return success true if the transfer succeeded, false otherwise
    function rescueToken(address tokenAddress) public onlyOwner returns (bool success) {
        return ERC20(tokenAddress).transfer(msg.sender, ERC20(tokenAddress).balanceOf(address(this)));
    }
    /// @notice The main function called during a transfer.  First it determines if a transfer is possible by making
    /// sure the contract is not paused and that all limits are adhered to. Taxes are adjust based on whether or not
    /// the transaction is being made by an AMM (no wallet to wallet taxes). If the amount of accumulated tokens
    /// is greater than the minimum required to swap then `swapAndLiquify` is called which pays out liquidity
    /// taxes, marketing taxes and sends bnb for dividends to the tracker. Fees are applied and the dividend
    /// tracker token balances are updated to reflect the post transfer token amounts.
    /// @param from Where the tokens are being transferred from
    /// @param to Where the tokens are being transferred to
    /// @param amount The amount of tokens to transfer
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "tx from 0");
        require(to != address(0), "tx to 0");
        require(_isExcludedFromFee[address(this)], "ca must be exempt from fees");

        if (amount == 0) {
            return;
        }

        bool isBuyFromLp = automatedMarketMakerPairs[from];
        bool isSelltoLp = automatedMarketMakerPairs[to];

        if (!_isAllowedToTradeWhenDisabled[from] && !_isAllowedToTradeWhenDisabled[to]) {
            require(!paused(), "Trading disabled");
            if (!_isExcludedFromMaxTransactionLimit[to] && !_isExcludedFromMaxTransactionLimit[from]) {
                require(amount <= maxTxAmount, "Exceeds max");
            }
            if (!_isExcludedFromMaxWalletLimit[to]) {
                require(balanceOf(to).add(amount) <= maxWalletAmount, "Exceeds max");
            }
        }
        _adjustTaxes(isBuyFromLp, isSelltoLp);
        if (
            !paused() &&
        balanceOf(address(this)) >= minimumTokensBeforeSwap &&
        !_swapping &&
        _totalFee > 0 &&
        isSelltoLp &&
        (from != liquidityWallet || from != marketingWallet) &&
        (to != liquidityWallet || to != marketingWallet)
        ) {
            _swapping = true;
            _swapAndLiquify();
            _swapping = false;
        }
        if (!_swapping && !paused() && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            uint256 fee = amount.mul(_totalFee).div(100);
            _liquidityTokensToSwap += amount.mul(_liquidityFee).div(100);
            _marketingTokensToSwap += amount.mul(_marketingFee).div(100);
            _holdersTokensToSwap += amount.mul(_holdersFee).div(100);
            amount = amount.sub(fee);
            if (fee > 0) {
                super._transfer(from, address(this), fee);
                emit FeesApplied(_liquidityFee, _marketingFee, _holdersFee, _totalFee);
            }
        }
        super._transfer(from, to, amount);

        dividendTracker.setBalance(payable(from), balanceOf(from));
        dividendTracker.setBalance(payable(to), balanceOf(to));
        if (!_swapping && gasForProcessing > 0) {
            (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) = dividendTracker.process(gasForProcessing);
            emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gasForProcessing, msg.sender);
        }

    }

    /// @notice Adjusts taxes to remove wallet to wallet taxing
    /// @param isBuyFromLp true if this buy is coming from an AMM
    /// @param isSellToLp true if this sell is coming from an AMM
    function _adjustTaxes(bool isBuyFromLp, bool isSellToLp) private {

        if (!isBuyFromLp && !isSellToLp) {
            _liquidityFee = 0;
            _marketingFee = 0;
            _holdersFee = 0;
            _totalFee = 0;
        } else if (isSellToLp && isBuyFromLp) {
            _liquidityFee = 2;
            _marketingFee = 3;
            _holdersFee = 10;
            _totalFee = _liquidityFee + _marketingFee + _holdersFee;
        }else if (isSellToLp) {
            _liquidityFee = liquidityFeeOnSell;
            _marketingFee = marketingFeeOnSell;
            _holdersFee = holdersFeeOnSell;
            _totalFee = _liquidityFee + _marketingFee + _holdersFee;
        } else {
            _liquidityFee = liquidityFeeOnBuy;
            _marketingFee = marketingFeeOnBuy;
            _holdersFee = holdersFeeOnBuy;
            _totalFee = _liquidityFee + _marketingFee + _holdersFee;
        }
    }

    /// @notice Takes accumulated taxes disperses them to the proper place (marketing, lp or dividends)
    function _swapAndLiquify() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 initialBNBBalance = address(this).balance;
        uint256 amountToLiquify = _liquidityTokensToSwap.div(2);
        uint256 amountToSwap = contractBalance.sub(amountToLiquify);

        _swapTokensForBNB(amountToSwap);
        uint256 bnbBalanceAfterSwap = address(this).balance.sub(initialBNBBalance);

        uint256 totalBNBFee = _liquidityTokensToSwap.add(_marketingTokensToSwap).add(_holdersTokensToSwap).sub(_liquidityTokensToSwap.div(2));
        if (totalBNBFee > 0) {
            uint256 amountBNBLiquidity = bnbBalanceAfterSwap.mul(_liquidityTokensToSwap).div(totalBNBFee).div(2);
            uint256 amountBNBMarketing = bnbBalanceAfterSwap.mul(_marketingTokensToSwap).div(totalBNBFee);
            uint256 amountBNBHolders = bnbBalanceAfterSwap.sub(amountBNBLiquidity.add(amountBNBMarketing));

            (bool success,) = payable(marketingWallet).call{value : amountBNBMarketing, gas : 30000}("");
            if (success) {
                emit MarketingFundsSent(amountBNBMarketing);
            }

            if (amountToLiquify > 0) {
                _addLiquidity(amountToLiquify, amountBNBLiquidity);
                emit SwapAndLiquify(amountToSwap, amountBNBLiquidity, amountToLiquify);
            }

            (bool dividendSuccess,) = address(dividendTracker).call{value : amountBNBHolders}("");
            if (dividendSuccess) {
                emit DividendsSent(amountBNBHolders);
            }

            _liquidityTokensToSwap = 0;
            _marketingTokensToSwap = 0;
            _holdersTokensToSwap = 0;
        }
    }

    /// @notice Internal swap of tokens to BNB
    /// @param tokenAmount The amount of tokens to swap to BNB
    function _swapTokensForBNB(uint256 tokenAmount) private {
        _approve(address(this), address(pancakeSwapRouter), tokenAmount);
        pancakeSwapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            tokenToBNBPath,
            address(this),
            block.timestamp
        );
    }

    /// @notice Adds liquidity to the LP
    /// @param tokenAmount The amount of tokens to add to the LP
    /// @param bnbAmount The amount of bnb to add to the LP
    function _addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        _approve(address(this), address(pancakeSwapRouter), tokenAmount);
        pancakeSwapRouter.addLiquidityETH{value : bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liquidityWallet,
            block.timestamp
        );
    }

    function getImplVersion() public view returns (uint256){
        return 3;
    }
}