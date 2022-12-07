//SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../abstracts/Auth.sol";
import "../abstracts/BEP20.sol";
import "../interfaces/IBEP20.sol";
import "../interfaces/IBEP20Metadata.sol";
import "../interfaces/IDEXFactory.sol";
import "../interfaces/IDEXRouter.sol";
import "../interfaces/IPinkAntiBot.sol";
import "../libs/SafeBEP20.sol";
import "./MemeRoyaleDividendTracker.sol";

contract MemeRoyale is BEP20, Auth {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    address private constant ADDR_DEAD =
        0x000000000000000000000000000000000000dEaD;
    address private constant ADDR_ZERO =
        0x0000000000000000000000000000000000000000;

    string private constant TOKEN_NAME = "MemeRoyale";
    string private constant TOKEN_SYMBOL = "ROYALE";
    uint256 private constant TOTAL_SUPPLY = 1 * 10**17 * 10**18;

    // Exemption Lists
    mapping(address => bool) private _feeExempt;
    mapping(address => bool) private _maxWalletExempt;
    mapping(address => bool) private _maxSellTxSizeExempt;
    mapping(address => bool) private _sellCooldownExempt;

    // Anti-Whale Features
    uint256 public maxWalletSize = 5 * 10**14 * 10**18;
    uint256 public maxSellTxSize = 5 * 10**13 * 10**18;

    // Anti Whale Feature: Sell Cooldown
    bool public sellCooldownEnabled = true;
    uint8 public sellCooldownPeriod = 60;
    mapping(address => uint256) private _sellCooldowns;

    // Fees
    uint256 public marketingFee = 300;
    uint256 public reflectionFee = 200;
    uint256 public liquidityFee = 200;
    uint256 public burnFee = 100;
    uint256 public totalFees =
        marketingFee + reflectionFee + liquidityFee + burnFee;

    // Automated Market Makers
    mapping(address => bool) public amms;

    // Addresses
    address public pair;
    address public marketingWallet;

    // Swap Settings
    bool public swapEnabled = true;
    uint256 public swapThreshold = TOTAL_SUPPLY.div(10000);
    bool private _swapping;

    // Dividend Tracker
    MemeRoyaleDividendTracker public dividendTracker;
    uint256 dividendTrackerGas = 300000;

    // Anti-Bot
    IPinkAntiBot public pinkAntiBot;
    bool public pinkAntiBotEnabled = true;

    IDEXRouter public router;

    // Events
    event FeesUpdated(uint256 previous, uint256 next);
    event MaxWalletSizeUpdated(uint256 previous, uint256 next);
    event MaxSellTxSizeUpdated(uint256 previous, uint256 next);
    event MarketingWalletUpdated(address previous, address next);
    event SellCooldownUpdated(
        bool previousEnabled,
        uint8 previousPeriod,
        bool nextEnabled,
        uint8 nextPeriod
    );
    event UnhandledError(bytes reason);

    constructor(
        address initialOwner,
        address[3] memory _addrs // 0 = Router, 1 = Pink Anti Bot, 2 = Marketing
    ) Auth(initialOwner) BEP20(TOKEN_NAME, TOKEN_SYMBOL) {
        router = IDEXRouter(_addrs[0]);
        pair = IDEXFactory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );

        _approve(address(this), address(router), type(uint256).max);

        dividendTracker = new MemeRoyaleDividendTracker(address(this), 0);

        marketingWallet = _addrs[2];

        amms[pair] = true;

        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(ADDR_DEAD);
        dividendTracker.excludeFromDividends(ADDR_ZERO);
        dividendTracker.excludeFromDividends(_addrs[0]);
        dividendTracker.excludeFromDividends(initialOwner);
        dividendTracker.excludeFromDividends(address(pair));

        _feeExempt[initialOwner] = true;
        _feeExempt[address(this)] = true;
        _feeExempt[ADDR_DEAD] = true;
        _feeExempt[marketingWallet] = true;
        _feeExempt[address(dividendTracker)] = true;

        _maxWalletExempt[initialOwner] = true;
        _maxWalletExempt[address(this)] = true;
        _maxWalletExempt[ADDR_DEAD] = true;
        _maxWalletExempt[marketingWallet] = true;
        _maxWalletExempt[address(dividendTracker)] = true;

        _maxSellTxSizeExempt[initialOwner] = true;
        _maxSellTxSizeExempt[address(this)] = true;
        _maxSellTxSizeExempt[ADDR_DEAD] = true;
        _maxSellTxSizeExempt[marketingWallet] = true;
        _maxSellTxSizeExempt[address(dividendTracker)] = true;

        _sellCooldownExempt[initialOwner] = true;
        _sellCooldownExempt[address(this)] = true;
        _sellCooldownExempt[marketingWallet] = true;
        _sellCooldownExempt[address(dividendTracker)] = true;

        _mint(initialOwner, TOTAL_SUPPLY);

        pinkAntiBot = IPinkAntiBot(_addrs[1]);
        pinkAntiBot.setTokenOwner(initialOwner);
    }

    receive() external payable {}

    // #region Transfer and Fees
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != ADDR_ZERO, "MRO: transfer-from-zero");
        require(to != ADDR_ZERO, "MRO: transfer-to-zero");

        if (amount == 0 || _swapping || from == address(dividendTracker)) {
            super._transfer(from, to, amount);

            try dividendTracker.setBalance(payable(to), balanceOf(to), false) {} catch {}
        } else {
            if (_shouldSwapBack(from)) {
                _swapping = true;
                _swapBack();
                _swapping = false;
            }

            bool takeFee = _shouldTakeFee(from, to);
            uint256 amountAfterFees = amount;

            if (takeFee) {
                amountAfterFees = _takeFee(from, amount);
            }

            _preTransferCheck(from, to, amount, amountAfterFees);

            bool isSell = amms[to];

            if (isSell && sellCooldownEnabled) {
                _sellCooldowns[from] = block.timestamp + sellCooldownPeriod;
            }

            super._transfer(from, to, amountAfterFees);

            // Dividend Tracking and distribution
            try dividendTracker.setBalance(payable(from), balanceOf(from), true) {} catch {}
            try dividendTracker.setBalance(payable(to), balanceOf(to), true) {} catch {}

            try dividendTracker.process(dividendTrackerGas) {} catch {}
        }
    }

    /**
     * @dev Performs anti-whale, anti-bot and cooldown checks prior to a transfer.
     */
    function _preTransferCheck(
        address from,
        address to,
        uint256 originalAmount,
        uint256 transferAmount
    ) internal virtual {
        uint256 heldTokens = balanceOf(to);

        require(
            amms[to] ||
                _maxWalletExempt[to] ||
                isAuthorized(from) ||
                (heldTokens + transferAmount) <= maxWalletSize,
            "MRO: max-wallet-exceeded"
        );
        require(
            !amms[to] ||
                originalAmount <= maxSellTxSize ||
                _maxSellTxSizeExempt[from] ||
                isAuthorized(from),
            "MRO: max-tx-size-exceeded"
        );
        require(
            !amms[to] ||
                !sellCooldownEnabled ||
                _sellCooldownExempt[from] ||
                isAuthorized(from) ||
                _sellCooldowns[from] <= block.timestamp,
            "MRO: sell-cooldown"
        );

        if (pinkAntiBotEnabled) {
            pinkAntiBot.onPreTransferCheck(from, to, originalAmount);
        }
    }

    /**
     * @dev Takes the correct fee amount
     */
    function _takeFee(address from, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(totalFees).div(10000);

        super._transfer(from, address(this), feeAmount);

        return amount.sub(feeAmount);
    }

    /**
     * @dev Determines if a fee should be charged for the given transaction
     */
    function _shouldTakeFee(address from, address to)
        internal
        view
        returns (bool)
    {
        return !_feeExempt[from] && !_feeExempt[to] && (amms[from] || amms[to]);
    }

    // #endregion

    // #region Swapback
    /**
     * @dev Contract swaps back when: enabled, not already swapping, from address isn't an AMM and threshold is met.
     */
    function _shouldSwapBack(address from) internal view returns (bool) {
        return
            swapEnabled &&
            !_swapping &&
            !amms[from] &&
            (balanceOf(address(this)) >= swapThreshold);
    }

    /**
     * Executes the actual swapback
     */
    function _swapBack() internal {
        uint256 amountToLiquify = swapThreshold
            .mul(liquidityFee)
            .div(totalFees)
            .div(2);
        uint256 amountToReflect = swapThreshold.mul(reflectionFee).div(
            totalFees
        );
        uint256 amountToBurn = swapThreshold.mul(burnFee).div(totalFees);
        uint256 amountToSwap = swapThreshold
            .sub(amountToLiquify)
            .sub(amountToReflect)
            .sub(amountToBurn);

        uint256 nativeBalanceBefore = address(this).balance;
        _swapForNative(amountToSwap);
        uint256 receivedNativeTokens = address(this).balance.sub(
            nativeBalanceBefore
        );

        // Early return in case an error occurs.
        if (receivedNativeTokens <= 0) {
            return;
        }

        // Deposit to dividend tracker and tell it how much we added
        super._transfer(address(this), address(dividendTracker), amountToReflect);
        try dividendTracker.distributeDividends(amountToReflect) {} catch {}

        // Burn
        _burn(address(this), amountToBurn);

        uint256 totalNativeFees = totalFees.div(2);
        uint256 nativeForLiquidity = receivedNativeTokens
            .mul(liquidityFee)
            .div(totalNativeFees)
            .div(2);

        uint256 spentNative = nativeForLiquidity;

        if (nativeForLiquidity > 0) {
            spentNative = _addLiquidity(amountToLiquify, nativeForLiquidity);
        }

        uint256 nativeForMarketing = receivedNativeTokens.sub(spentNative);

        if (nativeForMarketing > 0) {
            payable(marketingWallet).transfer(nativeForMarketing);
        }
    }

    /**
     * @dev Adds liquidity
     */
    function _addLiquidity(uint256 tokenAmount, uint256 nativeTokenAmount)
        private
        returns (uint256 spentNative)
    {
        _approve(address(this), address(router), tokenAmount);

        (, spentNative, ) = router.addLiquidityETH{value: nativeTokenAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0),
            block.timestamp
        );
    }

    /**
     * Swaps our own token for the pair-native (WBNB) token.
     */
    function _swapForNative(uint256 amount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), amount);

        try
            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                amount,
                0, // Accept any amount
                path,
                address(this),
                block.timestamp
            )
        {} catch (bytes memory reason) {
            emit UnhandledError(reason);
        }
    }

    // #endregion

    // #region Utility
    function getCirculatingSupply() public view returns (uint256) {
        return TOTAL_SUPPLY.sub(balanceOf(ADDR_DEAD)).sub(balanceOf(ADDR_ZERO));
    }

    // #endregion

    // #region Dividends

    /**
     * @dev Updates the claim wait
     */
    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }

    /**
     * @dev Retrieve the claim wait
     */
    function getClaimWait() external view returns (uint256) {
        return dividendTracker.claimWait();
    }

    /**
     * @dev Updates the minimum token balance before getting dividends
     */
    function updateMinimumTokenBalanceForDividends(uint256 amount) external onlyOwner
    {
        dividendTracker.updateMinimumTokenBalanceForDividends(amount);
    }

    /**
     * @dev Retrieves the minimum token balance before getting dividends 
     */
    function getMinimumTokenBalanceForDividends() external view returns (uint256)
    {
        return dividendTracker.minimumTokenBalanceForDividends();
    }

    /**
     * @dev Manually claim dividends
     */
    function claim() external {
        dividendTracker.processAccount(payable(msg.sender), false);
    }

    /**
     * @dev Manually process dividend tracker with the given amount of gas
     */
    function processDividendTracker(uint256 gas) external {
        dividendTracker.process(gas);
    }

    /**
     * @dev Retrieve information about dividends for the given account 
     */
    function getAccountDividendsInfo(address account) external view
        returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return dividendTracker.getAccount(account);
    }

    // #region Administration

    /**
     * @dev Exempts or subjects an address from receiving reflection rewards.
     */
    function setReflectionExempt(address holder, bool exempt) external authorized
    {
        if (exempt) {
            dividendTracker.excludeFromDividends(holder);
        } else {
            dividendTracker.includeInDividends(holder, balanceOf(holder));
        }
    }

    /**
     * @dev Returns if an address is exempt from dividends
     */
    function isReflectionExempt(address holder) external view returns (bool)
    {
        return dividendTracker.isExcludedFromDividends(holder);
    }

    /**
     * @dev Enables or disables the anti-bot functionality
     */
    function setAntiBot(bool nextEnabled) external authorized {
        require(pinkAntiBotEnabled != nextEnabled, "MRO: value-already-set");

        pinkAntiBotEnabled = nextEnabled;
    }

    /**
     * @dev Updates the sell cooldown status and/or period. The interval cannot be more than 60 minutes.
     */
    function setSellCooldown(bool nextEnabled, uint8 nextPeriodInSeconds)
        external
        authorized
    {
        require(nextPeriodInSeconds <= 60, "MRO: period-gt-60-min");

        emit SellCooldownUpdated(
            sellCooldownEnabled,
            sellCooldownPeriod,
            nextEnabled,
            nextPeriodInSeconds
        );

        sellCooldownEnabled = nextEnabled;
        sellCooldownPeriod = nextPeriodInSeconds;
    }

    /**
     * @dev Exempts or subjects a given holder to the sell cooldown
     */
    function setSellCooldownExempt(address holder, bool exempt)
        external
        authorized
    {
        require(
            _sellCooldownExempt[holder] != exempt,
            "MRO: value-already-set"
        );

        _sellCooldownExempt[holder] = exempt;
    }

    /**
     * @dev Sets status of the automated swapback feature.
     */
    function setSwapEnabled(bool enabled) external authorized {
        require(swapEnabled != enabled, "MRO: value-already-set");

        swapEnabled = enabled;
    }

    /**
     * @dev Sets the threshold at which the contract will automatically swap, when enabled.
     */
    function setSwapThreshold(uint256 nextThreshold) external authorized {
        require(swapThreshold != nextThreshold, "MRO: value-already-set");

        swapThreshold = nextThreshold;
    }

    /**
     * @dev Exempts or subjects the given holder to transaction fees.
     */
    function setFeeExempt(address holder, bool exempt) external authorized {
        require(_feeExempt[holder] != exempt, "MRO: already-set");

        _feeExempt[holder] = exempt;
    }

    /**
     * @dev Sets the maximum wallet size, must be at least 1% of total supply.
     */
    function setMaxWalletSize(uint256 nextMaxWalletPerc) external authorized {
        require(nextMaxWalletPerc >= 100, "MRO: max-wallet-lt-1-perc");

        uint256 nextMaxWalletSize = TOTAL_SUPPLY.div(10000).mul(
            nextMaxWalletPerc
        );
        emit MaxWalletSizeUpdated(maxWalletSize, nextMaxWalletSize);
        maxWalletSize = nextMaxWalletSize;
    }

    /**
     * @dev Exempts or subjects the given holder to max wallet size.
     */
    function setMaxWalletExempt(address holder, bool exempt)
        external
        authorized
    {
        require(_maxWalletExempt[holder] != exempt, "MRO: already-set");

        _maxWalletExempt[holder] = exempt;
    }

    /**
     * @dev Sets the maximum sell transaction size amount, must be at least 0.5% of total supply.
     */
    function setMaxSellTxSize(uint256 nextMaxSellTxSizePerc)
        external
        authorized
    {
        require(nextMaxSellTxSizePerc >= 50, "MRO: max-tx-lt-.5-perc");

        uint256 nextMaxSellTxSize = TOTAL_SUPPLY.div(10000).mul(
            nextMaxSellTxSizePerc
        );
        emit MaxSellTxSizeUpdated(maxSellTxSize, nextMaxSellTxSize);

        maxSellTxSize = nextMaxSellTxSize;
    }

    /**
     * @dev Exempts or subjects the given holder to the maximum sell-transaction size.
     */
    function setMaxSellTxSizeExempt(address holder, bool exempt)
        external
        authorized
    {
        require(_maxSellTxSizeExempt[holder] != exempt, "MRO: already-set");

        _maxSellTxSizeExempt[holder] = exempt;
    }

    /**
     * @dev Exempts or subjects given holder from all limitations (fees, wallet and tx)
     */
    function setExempt(address holder, bool exempt) external authorized {
        _feeExempt[holder] = exempt;
        _maxWalletExempt[holder] = exempt;
        _maxSellTxSizeExempt[holder] = exempt;
    }

    /**
     * @dev Marks an address as automated market maker (or not) and exempts it from reflections.
     */
    function setAmm(address amm, bool isMaker) external authorized {
        require(amms[amm] != isMaker, "MRO: already-set");

        amms[amm] = isMaker;

        if (isMaker) {
            dividendTracker.excludeFromDividends(amm);
        } else {
            dividendTracker.includeInDividends(amm, balanceOf(amm));
        }
    }

    /**
     * @dev Update the marketing wallet address and automatically exempt it from fees and max wallet size.
     */
    function setMarketingWallet(address nextMarketingWallet)
        external
        authorized
    {
        require(
            nextMarketingWallet != marketingWallet,
            "MRO: value-already-set"
        );

        _feeExempt[nextMarketingWallet] = true;
        _maxSellTxSizeExempt[marketingWallet] = true;
        _maxWalletExempt[marketingWallet] = true;

        emit MarketingWalletUpdated(marketingWallet, nextMarketingWallet);

        marketingWallet = nextMarketingWallet;
    }

    /**
     * @dev Updates the fees, checks for a cumulative maximum fee of 20% and a single-fee maximum of 10%
     */
    function setFees(
        uint256 nextMarketingFee,
        uint256 nextReflectionFee,
        uint256 nextBurnFee,
        uint256 nextLiquidityFee
    ) external authorized {
        require(
            (nextMarketingFee +
                nextReflectionFee +
                nextBurnFee +
                nextLiquidityFee) <= 2000,
            "MRO: fees-exceed-20p"
        );
        require(
            nextMarketingFee <= 1000 &&
                nextReflectionFee <= 1000 &&
                nextBurnFee <= 1000 &&
                nextLiquidityFee <= 1000,
            "MRO: single-fee-exceeds-10p"
        );

        marketingFee = nextMarketingFee;
        reflectionFee = nextReflectionFee;
        burnFee = nextBurnFee;
        liquidityFee = nextLiquidityFee;

        emit FeesUpdated(
            totalFees,
            nextMarketingFee +
                nextReflectionFee +
                nextBurnFee +
                nextLiquidityFee
        );

        totalFees =
            nextMarketingFee +
            nextReflectionFee +
            nextBurnFee +
            nextLiquidityFee;
    }

    // #endregion

    // #region Rescue

    /**
     * @dev Rescues stuck balance of any BEP20-Token.
     */
    function rescueBalance(IBEP20 token, uint256 percentage)
        external
        authorized
    {
        require(
            percentage >= 0 && percentage <= 100,
            "MRO: value-not-between-0-and-100"
        );

        uint256 balance = token.balanceOf(address(this));

        require(balance > 0, "MRO: contract-has-no-balance");
        token.transfer(_msgSender(), balance.mul(percentage).div(100));
    }

    /**
     * @dev Rescues stuck balance of our own token.
     */
    function rescueOwnBalance(uint256 percentage) external authorized {
        require(
            percentage >= 0 && percentage <= 100,
            "MRO: value-not-between-0-and-100"
        );

        uint256 amount = balanceOf(address(this));

        super._transfer(
            address(this),
            _msgSender(),
            amount.mul(percentage).div(100)
        );
    }

    /**
     * Rescues stuck native (BRISE) balance.
     */
    function rescueNativeBalance(uint256 percentage) external authorized {
        require(
            percentage >= 0 && percentage <= 100,
            "MRO: value-not-between-0-and-100"
        );

        uint256 nativeAmount = address(this).balance;
        payable(_msgSender()).transfer(nativeAmount.mul(percentage).div(100));
    }
    // #endregion
}