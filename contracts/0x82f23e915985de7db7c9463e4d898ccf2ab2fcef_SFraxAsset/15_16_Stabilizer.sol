// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

// ====================================================================
// ====================== Stabilizer.sol ==============================
// ====================================================================

/**
 * @title Stabilizer
 * @dev Implementation:
 * Allows to take debt by minting sweep and repaying by burning sweep
 * Allows to buy and sell sweep in an AMM
 * Allows auto invest according the borrower configuration
 * Allows auto repays by the balancer to control sweep price
 * Allow liquidate the Asset when is defaulted
 * Repayments made by burning sweep
 * EquityRatio = Junior / (Junior + Senior)
 */

import "../AMM/IAMM.sol";
import "../Common/Owned.sol";
import "../Libraries/Chainlink.sol";
import "../Libraries/OvnMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Stabilizer is Owned, Pausable, ReentrancyGuard {
    using Math for uint256;

    IERC20Metadata public usdx;
    IPriceFeed public oracleUsdx;

    // Variables
    string public name;
    address public borrower;
    int256 public minEquityRatio; // Minimum Equity Ratio. 10000 is 1%
    uint256 public sweepBorrowed;
    uint256 public loanLimit;

    uint256 public callTime;
    uint256 public callDelay; // 86400 is 1 day
    uint256 public callAmount;

    uint256 public spreadFee; // 10000 is 1%
    uint256 public spreadDate;
    string public link;

    int256 public autoInvestMinRatio; // 10000 is 1%
    uint256 public autoInvestMinAmount;
    bool public autoInvestEnabled;

    bool public settingsEnabled;

    uint256 public startingTime;
    uint256 public startingPrice;
    uint256 public decreaseFactor; // 10000 is 1%
    uint256 public minLiquidationRatio; // 100000 is 10%
    bool public auctionAllowed;

    // Constants for various precisions
    uint256 private constant DAY_SECONDS = 60 * 60 * 24; // seconds of Day
    uint256 private constant DAYS_ONE_YEAR = 365; // days of Year
    uint256 private constant PRECISION = 1e6;
    uint256 private constant ORACLE_FREQUENCY = 1 days;

    /* ========== Events ========== */

    event Borrowed(uint256 indexed sweepAmount);
    event Repaid(uint256 indexed sweepAmount);
    event Withdrawn(address indexed token, uint256 indexed amount);
    event PayFee(uint256 indexed sweepAmount);
    event Bought(uint256 indexed sweepAmount);
    event Sold(uint256 indexed sweepAmount);
    event BoughtSWEEP(uint256 indexed sweepAmount);
    event SoldSWEEP(uint256 indexed usdxAmount);
    event LoanLimitChanged(uint256 loanLimit);
    event Proposed(address indexed borrower);
    event Rejected(address indexed borrower);
    event SweepBorrowedChanged(uint256 indexed sweepAmount);

    event Liquidated(address indexed user);

    event AutoCalled(uint256 indexed sweepAmount);
    event AutoInvested(uint256 indexed sweepAmount);
    event CallCancelled(uint256 indexed sweepAmount);

    event ConfigurationChanged(
        int256 indexed minEquityRatio,
        uint256 indexed spreadFee,
        uint256 loanLimit,
        uint256 decreaseFactor,
        uint256 callDelay,
        int256 autoInvestMinRatio,
        uint256 autoInvestMinAmount,
        uint256 minLiquidationRatio,
        bool autoInvestEnabled,
        bool _auctionAllowed,
        string url
    );

    /* ========== Errors ========== */

    error NotBorrower();
    error NotBalancer();
    error NotSweep();
    error SettingsDisabled();
    error OverZero();
    error AssetDefaulted();
    error AuctionNotActive();
    error ActionNotAllowed();
    error InvalidMinter();
    error NotEnoughBalance();
    error EquityRatioExcessed();
    error InvalidToken();
    error SpreadNotEnough();
    error NotDefaulted();
    error NotAutoInvest();
    error NotAutoInvestMinAmount();
    error NotAutoInvestMinRatio();

    /* ========== Modifies ========== */

    modifier onlyBorrower() {
        _onlyBorrower();
        _;
    }

    modifier onlySettingsEnabled() {
        _onlySettingsEnabled();
        _;
    }

    modifier validAmount(uint256 amount) {
        _validAmount(amount);
        _;
    }

    constructor(
        string memory _name,
        address _sweep,
        address _usdx,
        address _oracleUsdx,
        address _borrower
    ) Owned(_sweep) {
        if (_borrower == address(0)) revert ZeroAddressDetected();
        name = _name;
        usdx = IERC20Metadata(_usdx);
        oracleUsdx = IPriceFeed(_oracleUsdx);
        borrower = _borrower;
        settingsEnabled = true;
    }

    /* ========== Views ========== */

    /**
     * @notice Defaulted
     * @return bool that tells if stabilizer is in default.
     */
    function isDefaulted() public view returns (bool) {
        return
            (callDelay > 0 && callAmount > 0 && block.timestamp > callTime) ||
            (sweepBorrowed > 0 && getEquityRatio() < minEquityRatio);
    }

    /**
     * @notice Get Equity Ratio
     * @return the current equity ratio based in the internal storage.
     * @dev this value have a precision of 6 decimals.
     */
    function getEquityRatio() public view returns (int256) {
        return _calculateEquityRatio(0, 0);
    }

    /**
     * @notice Get Spread Amount
     * fee = borrow_amount * spread_ratio * (time / time_per_year)
     * @return uint256 calculated spread amount.
     */
    function accruedFee() public view returns (uint256) {
        if (sweepBorrowed > 0) {
            uint256 period = (block.timestamp - spreadDate) / DAY_SECONDS;
            return
                (sweepBorrowed * spreadFee * period) /
                (DAYS_ONE_YEAR * PRECISION);
        }

        return 0;
    }

    /**
     * @notice Get Debt Amount
     * debt = borrow_amount + spread fee
     * @return uint256 calculated debt amount.
     */
    function getDebt() public view returns (uint256) {
        return sweepBorrowed + accruedFee();
    }

    /**
     * @notice Get Current Value
     * value = sweep balance + usdx balance
     * @return uint256.
     */
    function currentValue() public view virtual returns (uint256) {
        (uint256 usdxBalance, uint256 sweepBalance) = _balances();
        uint256 sweepInUsd = sweep.convertToUSD(sweepBalance);
        uint256 usdxInUsd = _oracleUsdxToUsd(usdxBalance);

        return usdxInUsd + sweepInUsd;
    }

    /**
     * @notice Get AMM from Sweep
     * @return address.
     */
    function amm() public view virtual returns (IAMM) {
        return IAMM(sweep.amm());
    }

    /**
     * @notice Get Junior Tranche Value
     * @return int256 calculated junior tranche amount.
     */
    function getJuniorTrancheValue() external view returns (int256) {
        uint256 seniorTrancheInUSD = sweep.convertToUSD(sweepBorrowed);
        uint256 totalValue = currentValue();

        return int256(totalValue) - int256(seniorTrancheInUSD);
    }

    /**
     * @notice Returns the SWEEP required to liquidate the stabilizer in the auction.
     * @return auctionPrice
     */
    function getAuctionAmount() public view returns (uint256) {
        uint256 minPrice = sweepBorrowed * (PRECISION - minLiquidationRatio) / PRECISION;
        uint256 timeElapsed = (block.timestamp - startingTime) / 5 minutes;
        uint256 ratio = timeElapsed * decreaseFactor;

        if(ratio > PRECISION) return minPrice;

        uint256 decreaseRatio = PRECISION - ratio;
        uint256 auctionPrice = (startingPrice * decreaseRatio) / PRECISION;

        return minPrice > auctionPrice ? minPrice : auctionPrice;
    }

    /* ========== Settings ========== */

    /**
     * @notice Pause
     * @dev Stops investment actions.
     */
    function pause() external onlyMultisigOrGov {
        _pause();
    }

    /**
     * @notice Unpause
     * @dev Start investment actions.
     */
    function unpause() external onlyMultisigOrGov {
        _unpause();
    }

    /**
     * @notice Configure intial settings
     * @param _minEquityRatio The minimum equity ratio can be negative.
     * @param _spreadFee The fee that the protocol will get for providing the loan when the stabilizer takes debt
     * @param _loanLimit How much debt a Stabilizer can take in SWEEP.
     * @param _decreaseFactor A percentage that will be discounted from the price as time passes from the auction start.
     * @param _callDelay Time in seconds after AutoCall until the Stabilizer gets defaulted if the debt is not paid in that period
     * @param _autoInvestMinRatio Minimum equity ratio that should be kept to allow the execution of an auto invest
     * @param _autoInvestMinAmount Minimum amount to be invested to allow the execution of an auto invest
     * @param _autoInvestEnabled Represents if an auto invest execution is allowed or not
     * @param _auctionAllowed Represents if an auction is allowed or not
     * @param _url A URL link to a Web page that describes the borrower and the asset
     * @dev Sets the initial configuration of the Stabilizer.
     * This configuration will be analyzed by the protocol and if accepted,
     * used to include the Stabilizer in the minter's whitelist of Sweep.
     * The minimum equity ratio can not be less than 1%
     */
    function configure(
        int256 _minEquityRatio,
        uint256 _spreadFee,
        uint256 _loanLimit,
        uint256 _decreaseFactor,
        uint256 _callDelay,
        int256 _autoInvestMinRatio,
        uint256 _autoInvestMinAmount,
        uint256 _minLiquidationRatio,
        bool _autoInvestEnabled,
        bool _auctionAllowed,
        string calldata _url
    ) external onlyBorrower onlySettingsEnabled {
        minEquityRatio = _minEquityRatio;
        spreadFee = _spreadFee;
        loanLimit = _loanLimit;
        decreaseFactor = _decreaseFactor;
        callDelay = _callDelay;
        autoInvestMinRatio = _autoInvestMinRatio;
        autoInvestMinAmount = _autoInvestMinAmount;
        minLiquidationRatio = _minLiquidationRatio;
        autoInvestEnabled = _autoInvestEnabled;
        auctionAllowed = _auctionAllowed;
        link = _url;

        emit ConfigurationChanged(
            _minEquityRatio,
            _spreadFee,
            _loanLimit,
            decreaseFactor,
            _callDelay,
            _autoInvestMinRatio,
            _autoInvestMinAmount,
            _minLiquidationRatio,
            _autoInvestEnabled,
            _auctionAllowed,
            _url
        );
    }

    /**
     * @notice Changes the account that control the global configuration to the protocol/governance admin
     * @dev after disable settings by admin
     * the protocol will evaluate adding the stabilizer to the minter list.
     */
    function propose() external onlyBorrower {
        settingsEnabled = false;

        emit Proposed(borrower);
    }

    /**
     * @notice Changes the account that control the global configuration to the borrower
     * @dev after enable settings for the borrower
     * he/she should edit the values to align to the protocol requirements
     */
    function reject() external onlyGov {
        settingsEnabled = true;

        emit Rejected(borrower);
    }

    /* ========== Actions ========== */

    /**
     * @notice Borrows Sweep
     * Asks the stabilizer to mint a certain amount of sweep token.
     * @param sweepAmount.
     * @dev Increases the sweepBorrowed (senior tranche).
     */
    function borrow(
        uint256 sweepAmount
    )
        external
        onlyBorrower
        whenNotPaused
        validAmount(sweepAmount)
        nonReentrant
    {
        if (!sweep.isValidMinter(address(this))) revert InvalidMinter();

        uint256 sweepAvailable = loanLimit - sweepBorrowed;
        if (sweepAvailable < sweepAmount) revert NotEnoughBalance();

        int256 currentEquityRatio = _calculateEquityRatio(sweepAmount, 0);
        if (currentEquityRatio < minEquityRatio) revert EquityRatioExcessed();

        _borrow(sweepAmount);
    }

    /**
     * @notice Repays Sweep
     * Burns the sweep amount to reduce the debt (senior tranche).
     * @param sweepAmount Amount to be burnt by Sweep.
     * @dev Decreases the sweep borrowed.
     */
    function repay(uint256 sweepAmount) external onlyBorrower nonReentrant {
        _repay(sweepAmount);
    }

    /**
     * @notice Pay the spread to the treasury
     */
    function payFee() external onlyBorrower nonReentrant {
        uint256 spreadAmount = accruedFee();
        spreadDate = block.timestamp;

        uint256 sweepBalance = sweep.balanceOf(address(this));

        if (spreadAmount > sweepBalance) revert SpreadNotEnough();

        if (spreadAmount > 0) {
            TransferHelper.safeTransfer(
                address(sweep),
                sweep.treasury(),
                spreadAmount
            );

            emit PayFee(spreadAmount);
        }
    }

    /**
     * @notice Set Loan Limit.
     * @param newLoanLimit.
     * @dev How much debt an Stabilizer can take in SWEEP.
     */
    function setLoanLimit(uint256 newLoanLimit) external {
        if (msg.sender != sweep.balancer()) revert NotBalancer();
        loanLimit = newLoanLimit;

        emit LoanLimitChanged(newLoanLimit);
    }

    /**
     * @notice Update Sweep Borrowed Amount.
     * @param amount.
     */
    function updateSweepBorrowed(uint256 amount) external {
        if (msg.sender != address(sweep)) revert NotSweep();
        sweepBorrowed = amount;

        emit SweepBorrowedChanged(amount);
    }

    /**
     * @notice Auto Call.
     * @param sweepAmount to repay.
     * @dev Strategy:
     * 1) repays debt with SWEEP balance
     * 2) repays remaining debt by divesting
     * 3) repays remaining debt by buying on SWEEP in the AMM
     */
    function autoCall(
        uint256 sweepAmount,
        uint256 price,
        uint256 slippage
    ) external nonReentrant {
        if (msg.sender != sweep.balancer()) revert NotBalancer();
        (uint256 usdxBalance, uint256 sweepBalance) = _balances();
        uint256 repayAmount = sweepAmount.min(sweepBorrowed);

        if (callDelay > 0) {
            callTime = block.timestamp + callDelay;
            callAmount = repayAmount;
        }

        if (sweepBalance < repayAmount) {
            uint256 missingSweep = repayAmount - sweepBalance;
            uint256 sweepInUsd = sweep.convertToUSD(missingSweep);
            uint256 missingUsdx = _oracleUsdToUsdx(sweepInUsd);

            if (missingUsdx > usdxBalance) {
                _divest(missingUsdx - usdxBalance, slippage);
            }

            if (usdx.balanceOf(address(this)) > 0) {
                uint256 missingUsd = _oracleUsdxToUsd(missingUsdx);
                uint256 sweepInUsdx = missingUsd.mulDiv(
                    10 ** sweep.decimals(),
                    price
                );
                uint256 minAmountOut = OvnMath.subBasisPoints(
                    sweepInUsdx,
                    slippage
                );
                _buy(missingUsdx, minAmountOut);
            }
        }

        if (sweep.balanceOf(address(this)) > 0 && repayAmount > 0) {
            _repay(repayAmount);
        }

        emit AutoCalled(sweepAmount);
    }

    /**
     * @notice Cancel Call
     * @dev Cancels the auto call request by clearing variables for an asset
     * that has a callDelay: meaning that it does not autorepay.
     */
    function cancelCall() external {
        if (msg.sender != sweep.balancer()) revert NotBalancer();
        callAmount = 0;
        callTime = 0;
        emit CallCancelled(callAmount);
    }

    /**
     * @notice Auto Invest.
     * @param sweepAmount to mint.
     * @param price.
     * @param slippage.
     */
    function autoInvest(
        uint256 sweepAmount,
        uint256 price,
        uint256 slippage
    ) external nonReentrant {
        if (msg.sender != sweep.balancer()) revert NotBalancer();
        uint256 sweepLimit = sweep.minters(address(this)).maxAmount;
        uint256 sweepAvailable = sweepLimit - sweepBorrowed;
        sweepAmount = sweepAmount.min(sweepAvailable);
        int256 currentEquityRatio = _calculateEquityRatio(sweepAmount, 0);

        if (!autoInvestEnabled) revert NotAutoInvest();
        if (sweepAmount < autoInvestMinAmount) revert NotAutoInvestMinAmount();
        if (currentEquityRatio < autoInvestMinRatio)
            revert NotAutoInvestMinRatio();

        _borrow(sweepAmount);

        uint256 usdAmount = sweepAmount.mulDiv(price, 10 ** sweep.decimals());
        uint256 usdInUsdx = _oracleUsdToUsdx(usdAmount);
        uint256 minAmountOut = OvnMath.subBasisPoints(usdInUsdx, slippage);
        uint256 usdxAmount = _sell(sweepAmount, minAmountOut);

        _invest(usdxAmount, 0, slippage);

        emit AutoInvested(sweepAmount);
    }

    /**
     * @notice Buy
     * Buys sweep amount from the stabilizer's balance to the AMM (swaps USDX to SWEEP).
     * @param usdxAmount Amount to be changed in the AMM.
     * @param amountOutMin Minimum amount out.
     * @dev Increases the sweep balance and decrease usdx balance.
     */
    function buySweepOnAMM(
        uint256 usdxAmount,
        uint256 amountOutMin
    )
        external
        onlyBorrower
        whenNotPaused
        nonReentrant
        returns (uint256 sweepAmount)
    {
        sweepAmount = _buy(usdxAmount, amountOutMin);

        emit Bought(sweepAmount);
    }

    /**
     * @notice Sell Sweep
     * Sells sweep amount from the stabilizer's balance to the AMM (swaps SWEEP to USDX).
     * @param sweepAmount.
     * @param amountOutMin Minimum amount out.
     * @dev Decreases the sweep balance and increase usdx balance
     */
    function sellSweepOnAMM(
        uint256 sweepAmount,
        uint256 amountOutMin
    )
        external
        onlyBorrower
        whenNotPaused
        nonReentrant
        returns (uint256 usdxAmount)
    {
        usdxAmount = _sell(sweepAmount, amountOutMin);

        emit Sold(sweepAmount);
    }

    /**
     * @notice Buy Sweep with Stabilizer
     * Buys sweep amount from the stabilizer's balance to the Borrower (swaps USDX to SWEEP).
     * @param usdxAmount.
     * @dev Decreases the sweep balance and increase usdx balance
     */
    function swapUsdxToSweep(
        uint256 usdxAmount
    ) external onlyBorrower whenNotPaused validAmount(usdxAmount) nonReentrant {
        uint256 usdxInUsd = _oracleUsdxToUsd(usdxAmount);
        uint256 sweepAmount = sweep.convertToSWEEP(usdxInUsd);
        uint256 sweepBalance = sweep.balanceOf(address(this));
        if (sweepAmount > sweepBalance) revert NotEnoughBalance();

        TransferHelper.safeTransferFrom(
            address(usdx),
            msg.sender,
            address(this),
            usdxAmount
        );
        TransferHelper.safeTransfer(address(sweep), msg.sender, sweepAmount);

        emit BoughtSWEEP(sweepAmount);
    }

    /**
     * @notice Sell Sweep with Stabilizer
     * Sells sweep amount to the stabilizer (swaps SWEEP to USDX).
     * @param sweepAmount.
     * @dev Decreases the sweep balance and increase usdx balance
     */
    function swapSweepToUsdx(
        uint256 sweepAmount
    )
        external
        onlyBorrower
        whenNotPaused
        validAmount(sweepAmount)
        nonReentrant
    {
        uint256 sweepInUsd = sweep.convertToUSD(sweepAmount);
        uint256 usdxAmount = _oracleUsdToUsdx(sweepInUsd);
        uint256 usdxBalance = usdx.balanceOf(address(this));

        if (usdxAmount > usdxBalance) revert NotEnoughBalance();

        TransferHelper.safeTransferFrom(
            address(sweep),
            msg.sender,
            address(this),
            sweepAmount
        );
        TransferHelper.safeTransfer(address(usdx), msg.sender, usdxAmount);

        emit SoldSWEEP(usdxAmount);
    }

    /**
     * @notice Withdraw SWEEP
     * Takes out sweep balance if the new equity ratio is higher than the minimum equity ratio.
     * @param token.
     * @param amount.
     * @dev Decreases the sweep balance.
     */
    function withdraw(
        address token,
        uint256 amount
    ) external onlyBorrower whenNotPaused validAmount(amount) nonReentrant {
        if (amount > IERC20Metadata(token).balanceOf(address(this)))
            revert NotEnoughBalance();

        if (sweepBorrowed > 0) {
            if (token != address(sweep) && token != address(usdx))
                revert InvalidToken();

            uint256 usdAmount = token == address(sweep)
                ? sweep.convertToUSD(amount)
                : _oracleUsdxToUsd(amount);
            int256 currentEquityRatio = _calculateEquityRatio(0, usdAmount);
            if (currentEquityRatio < minEquityRatio)
                revert EquityRatioExcessed();
        }

        TransferHelper.safeTransfer(token, msg.sender, amount);

        emit Withdrawn(token, amount);
    }

    /**
     * @notice Start auction
     * Initiates a dutch auction for liquidation.
     */
    function startAuction() external {
        if (!isDefaulted()) revert NotDefaulted();
        if(!auctionAllowed || startingPrice > 0) revert ActionNotAllowed();

        startingTime = block.timestamp;
        uint256 minEquity = (PRECISION - uint256(minEquityRatio));
        startingPrice = getDebt() * PRECISION / minEquity;
    }

    /**
     * @notice Buy auction
     * Allows a user to participate in the auction by buying assets
     */
    function buyAuction() external nonReentrant {
        if(startingTime == 0) revert AuctionNotActive();
        uint256 debt = getAuctionAmount();
        address token = _getToken();
        _liquidate(token, debt);
    }

    /* ========== Internals ========== */

    /**
     * @notice Invest To Asset.
     */
    function _invest(uint256, uint256, uint256) internal virtual {}

    /**
     * @notice Divest From Asset.
     */
    function _divest(uint256, uint256) internal virtual returns (uint256) {}

    /**
     * @notice Get asset address to liquidate.
     */
    function _getToken() internal virtual returns (address) {}

    /**
     * @notice Stop the auction.
     */
    function _stopAuction() internal {
        startingTime = 0;
        startingPrice = 0;
    }

    /**
     * @notice Liquidates
     * A liquidator repays the debt in sweep and gets the same value
     * of the assets that the stabilizer holds at a discount
     */
    function _liquidate(
        address token,
        uint256 debt
    ) internal {
        if (!isDefaulted()) revert NotDefaulted();
        address self = address(this);
        uint256 usdxBalance = usdx.balanceOf(self);
        uint256 tokenBalance = IERC20Metadata(token).balanceOf(self);
        uint256 sweepBalance = sweep.balanceOf(self);
        if(debt > sweepBalance) {
            // Takes SWEEP from the liquidator and repays debt
            TransferHelper.safeTransferFrom(
                address(sweep),
                msg.sender,
                self,
                debt - sweepBalance
            );
        }

        // Gives all the assets to the liquidator
        TransferHelper.safeTransfer(address(usdx), msg.sender, usdxBalance);
        TransferHelper.safeTransfer(token, msg.sender, tokenBalance);

        _repay(debt);

        emit Liquidated(msg.sender);
    }

    function _buy(
        uint256 usdxAmount,
        uint256 amountOutMin
    ) internal returns (uint256) {
        uint256 usdxBalance = usdx.balanceOf(address(this));
        usdxAmount = usdxAmount.min(usdxBalance);
        if (usdxAmount == 0) revert NotEnoughBalance();

        IAMM _amm = amm();
        TransferHelper.safeApprove(address(usdx), address(_amm), usdxAmount);
        uint256 sweepAmount = _amm.buySweep(
            address(usdx),
            usdxAmount,
            amountOutMin
        );

        return sweepAmount;
    }

    function _sell(
        uint256 sweepAmount,
        uint256 amountOutMin
    ) internal returns (uint256) {
        uint256 sweepBalance = sweep.balanceOf(address(this));
        sweepAmount = sweepAmount.min(sweepBalance);
        if (sweepAmount == 0) revert NotEnoughBalance();

        IAMM _amm = amm();
        TransferHelper.safeApprove(address(sweep), address(_amm), sweepAmount);
        uint256 usdxAmount = _amm.sellSweep(
            address(usdx),
            sweepAmount,
            amountOutMin
        );

        return usdxAmount;
    }

    function _borrow(uint256 sweepAmount) internal {
        uint256 spreadAmount = accruedFee();
        sweep.mint(sweepAmount);
        sweepBorrowed += sweepAmount;
        spreadDate = block.timestamp;

        if (spreadAmount > 0) {
            TransferHelper.safeTransfer(
                address(sweep),
                sweep.treasury(),
                spreadAmount
            );
            emit PayFee(spreadAmount);
        }

        emit Borrowed(sweepAmount);
    }

    function _repay(uint256 sweepAmount) internal {
        uint256 sweepBalance = sweep.balanceOf(address(this));
        sweepAmount = sweepAmount.min(sweepBalance);

        if (sweepAmount == 0) revert NotEnoughBalance();

        callAmount = (callAmount > sweepAmount)
            ? (callAmount - sweepAmount)
            : 0;

        if (callDelay > 0 && callAmount == 0) callTime = 0;

        uint256 spreadAmount = accruedFee();
        spreadDate = block.timestamp;

        sweepAmount = sweepAmount - spreadAmount;
        if (sweepBorrowed < sweepAmount) {
            sweepAmount = sweepBorrowed;
            sweepBorrowed = 0;
        } else {
            sweepBorrowed -= sweepAmount;
        }

        TransferHelper.safeTransfer(
            address(sweep),
            sweep.treasury(),
            spreadAmount
        );

        TransferHelper.safeApprove(address(sweep), address(this), sweepAmount);
        sweep.burn(sweepAmount);

        emit Repaid(sweepAmount);
        if(!isDefaulted()) _stopAuction();
    }

    /**
     * @notice Calculate Equity Ratio
     * Calculated the equity ratio based on the internal storage.
     * @param sweepDelta Variation of SWEEP to recalculate the new equity ratio.
     * @param usdDelta Variation of USD to recalculate the new equity ratio.
     * @return the new equity ratio used to control the Mint and Withdraw functions.
     * @dev Current Equity Ratio percentage has a precision of 4 decimals.
     */
    function _calculateEquityRatio(
        uint256 sweepDelta,
        uint256 usdDelta
    ) internal view returns (int256) {
        uint256 currentValue_ = currentValue();
        uint256 sweepDeltaInUsd = sweep.convertToUSD(sweepDelta);
        uint256 totalValue = currentValue_ + sweepDeltaInUsd - usdDelta;

        if (totalValue == 0) {
            if (sweepBorrowed > 0) return -1e6;
            else return 0;
        }

        uint256 seniorTrancheInUsd = sweep.convertToUSD(
            sweepBorrowed + sweepDelta
        );

        // 1e6 is decimals of the percentage result
        int256 currentEquityRatio = ((int256(totalValue) -
            int256(seniorTrancheInUsd)) * 1e6) / int256(totalValue);

        if (currentEquityRatio < -1e6) currentEquityRatio = -1e6;

        return currentEquityRatio;
    }

    /**
     * @notice Get Balances of the usdx and SWEEP.
     **/
    function _balances()
        internal
        view
        returns (uint256 usdxBalance, uint256 sweepBalance)
    {
        usdxBalance = usdx.balanceOf(address(this));
        sweepBalance = sweep.balanceOf(address(this));
    }

    function _onlyBorrower() internal view {
        if (msg.sender != borrower) revert NotBorrower();
    }

    function _onlySettingsEnabled() internal view {
        if (!settingsEnabled) revert SettingsDisabled();
    }

    function _validAmount(uint256 amount) internal pure {
        if (amount == 0) revert OverZero();
    }

    function _oracleUsdxToUsd(
        uint256 usdxAmount
    ) internal view returns (uint256) {
        return
            ChainlinkLibrary.convertTokenToUsd(
                usdxAmount,
                usdx.decimals(),
                oracleUsdx
            );
    }

    function _oracleUsdToUsdx(
        uint256 usdAmount
    ) internal view returns (uint256) {
        return
            ChainlinkLibrary.convertUsdToToken(
                usdAmount,
                usdx.decimals(),
                oracleUsdx
            );
    }
}