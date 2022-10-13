// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.4;

import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Kiko} from "../../libraries/Kiko.sol";
import {ShareMathKiko} from "../../libraries/ShareMathKiko.sol";
import {ExoticOracleInterface} from "../../interfaces/ExoticOracleInterface.sol";

contract KikoVault is 
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    ERC20Upgradeable
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using ShareMathKiko for Kiko.DepositReceipt;

    /************************************************
     *  NON UPGRADEABLE STORAGE
     ***********************************************/

    /// @notice Stores the user's pending deposit for the round
    mapping(address => Kiko.DepositReceipt) public depositReceipts;

    /// @notice On every round's close, the pricePerShare value of an rTHETA token is stored
    /// This is used to determine the number of shares to be returned
    /// to a user with their DepositReceipt.depositAmount
    mapping(uint256 => uint256) public roundPricePerShare;

    /// @notice Stores pending user withdrawals
    mapping(address => Kiko.Withdrawal) public withdrawals;

    /// @notice Stores the strike prices of the assets
    mapping(address => uint256) public assetStrikePrices;

    /// @notice Vault's parameters like cap, decimals
    Kiko.VaultParams public vaultParams;

    /// @notice Vault's lifecycle state like round and locked amounts
    Kiko.VaultState public vaultState;

    /// @notice Vault's state of the options sold and the timelocked option
    Kiko.OptionState public optionState;

    /// @notice Fee recipient for the performance and management fees
    address public feeRecipient;

    /// @notice MM that won the auction
    address public borrower;

    /// @notice role in charge of weekly vault operations such as rollToNextOption and burnRemainingOTokens
    // no access to critical vault changes
    address public keeper;

    /// @notice Performance fee charged on premiums earned in rollToNextOption. Only charged when there is no loss.
    uint256 public performanceFee;

    /// @notice Management fee charged on entire AUM in rollToNextOption. Only charged when there is no loss.
    uint256 public managementFee;


    // Gap is left to avoid storage collisions. Though PolysynthVault is not upgradeable, we add this as a safety measure.
    uint256[30] private ____gap;

    // *IMPORTANT* NO NEW STORAGE VARIABLES SHOULD BE ADDED HERE
    // This is to prevent storage collisions. All storage variables should be appended to PolysynthThetaVaultStorage
    // or PolysynthDeltaVaultStorage instead. Read this documentation to learn more:
    // https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#modifying-your-contracts

    /************************************************
     *  IMMUTABLES & CONSTANTS
     ***********************************************/

    address public immutable ORACLE;

    // /// @notice 30 day period between each options sale.
    // uint256 public constant PERIOD = 30 days;

    // Number of weeks per year = 52.142857 weeks * FEE_MULTIPLIER = 52142857
    // Dividing by weeks per year requires doing num.mul(FEE_MULTIPLIER).div(WEEKS_PER_YEAR)
    uint256 private constant DAYS_PER_YEAR = 365000000;



    /************************************************
     *  EVENTS
     ***********************************************/

    event Deposit(address indexed account, uint256 amount, uint256 round);

    event InitiateWithdraw(
        address indexed account,
        uint256 shares,
        uint256 round
    );

    event Redeem(address indexed account, uint256 share, uint256 round);

    event ManagementFeeSet(uint256 managementFee, uint256 newManagementFee);

    event PerformanceFeeSet(uint256 performanceFee, uint256 newPerformanceFee);

    event CapSet(uint256 oldCap, uint256 newCap);

    event Withdraw(address indexed account, uint256 amount, uint256 shares);

    event InstantWithdraw(
        address indexed account,
        uint256 amount,
        uint256 round
    );

    event CollectVaultFees(
        uint256 performanceFee,
        uint256 vaultFee,
        uint256 round,
        address indexed feeRecipient
    );

    event Borrow(address indexed account, uint256 amount, uint256 rate);

    event Settle(
        address indexed account,
        uint256 netReturn,
        uint256 lossAmount,
        uint256 couponAmount
    );

    event Observe(
        uint256 observeTime,
        bool hasKO,
        bool hasKI,
        uint16 activeDays
    );

    /************************************************
     *  CONSTRUCTOR & INITIALIZATION
     ***********************************************/
    // /**
    //  * @notice Initializes the contract with immutable variables
    //  * @param _weth is the Wrapped Ether contract     
    //  */
    constructor(
        address _oracle        
    ) {
        require(_oracle != address(0), "!_oracle");

        ORACLE = _oracle;
        // auctionTime = 13 hours;
    }

    function baseInitialize(
        address _owner,
        address _keeper,
        address _feeRecipent,
        string memory _tokenName,
        string memory _tokenSymbol,
        Kiko.VaultParams calldata _vaultParams
    ) internal initializer {

        __ReentrancyGuard_init();
        __ERC20_init(_tokenName, _tokenSymbol);
        __Ownable_init();
        transferOwnership(_owner);

        keeper = _keeper;
        feeRecipient = _feeRecipent;
        
        vaultParams = _vaultParams;

        uint256 assetBalance =
            IERC20(vaultParams.asset).balanceOf(address(this));
        ShareMathKiko.assertUint104(assetBalance);
        vaultState.lastLockedAmount = uint104(assetBalance);

        vaultState.round = 1;
    }

    /**
     * @dev Throws if called by any account other than the keeper.
     */
    modifier onlyKeeper() {
        require(msg.sender == keeper, "!keeper");
        _;
    }

    /************************************************
     *  SETTERS
     ***********************************************/

    /**
     * @notice Sets the new keeper
     * @param newKeeper is the address of the new keeper
     */
    function setNewKeeper(address newKeeper) external onlyOwner {
        require(newKeeper != address(0), "!newKeeper");
        keeper = newKeeper;
    }

    /**
     * @notice Sets the new fee recipient
     * @param newFeeRecipient is the address of the new fee recipient
     */
    function setFeeRecipient(address newFeeRecipient) external onlyOwner {
        require(newFeeRecipient != address(0), "!newFeeRecipient");
        require(newFeeRecipient != feeRecipient, "Must be new feeRecipient");
        feeRecipient = newFeeRecipient;
    }

        /**
     * @notice Sets the management fee for the vault
     * @param newManagementFee is the management fee (6 decimals). ex: 2 * 10 ** 6 = 2%
     */
    function setManagementFee(uint256 newManagementFee) external onlyOwner {
        require(
            newManagementFee < 100 * Kiko.FEE_MULTIPLIER,
            "Invalid management fee"
        );

        // We are dividing annualized management fee by num weeks in a year
        uint256 tmpManagementFee =
            newManagementFee.mul(Kiko.FEE_MULTIPLIER).div(DAYS_PER_YEAR);

        emit ManagementFeeSet(managementFee, newManagementFee);

        managementFee = tmpManagementFee;
    }

    /**
     * @notice Sets the performance fee for the vault
     * @param newPerformanceFee is the performance fee (6 decimals). ex: 20 * 10 ** 6 = 20%
     */
    function setPerformanceFee(uint256 newPerformanceFee) external onlyOwner {
        require(
            newPerformanceFee < 100 * Kiko.FEE_MULTIPLIER,
            "Invalid performance fee"
        );

        emit PerformanceFeeSet(performanceFee, newPerformanceFee);

        performanceFee = newPerformanceFee;
    }



    /**
     * @notice Sets a new cap for deposits
     * @param newCap is the new cap for deposits
     */
    function setCap(uint256 newCap) external onlyOwner {
        require(newCap > 0, "!newCap");
        ShareMathKiko.assertUint104(newCap);
        emit CapSet(vaultParams.cap, newCap);
        vaultParams.cap = uint104(newCap);
    }

    function setBorrower(address _borrower) external onlyOwner {
        require(_borrower != address(0), "!_borrower");
        borrower = _borrower;
    }

    function setStrikeRatio(uint256 _strikeRatio) external onlyOwner {
        require(_strikeRatio != 0, "!_strikeRatio");
        vaultParams.strikeRatio = uint16(_strikeRatio);
    }

    function updateExpiry(uint256 _expiry) external onlyOwner {
        require(_expiry != 0, "!_expiry");
        optionState.expiry = _expiry;        
    }

    function updateLastOb() external onlyOwner {
        optionState.lastObservation = 0;
    }

    /************************************************
     *  DEPOSIT & WITHDRAWALS
     ***********************************************/

    /**
     * @notice Deposits ETH into the contract and mint vault shares. Reverts if the asset is not WETH.
     */
    // function depositETH() external payable nonReentrant {
    //     require(vaultParams.asset == WETH, "!WETH");
    //     require(msg.value > 0, "!value");

    //     _depositFor(msg.value, msg.sender);

    //     IWETH(WETH).deposit{value: msg.value}();
    // }

    /**
     * @notice Deposits the `asset` from msg.sender.
     * @param amount is the amount of `asset` to deposit
     */
    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "!amount");

        _depositFor(amount, msg.sender);
        
        // An approve() by the msg.sender is required beforehand
        IERC20(vaultParams.asset).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
    }

    /**
     * @notice Withdraws the assets on the vault using the outstanding `DepositReceipt.amount`
     * @param amount is the amount to withdraw
     */
    function withdrawInstantly(uint256 amount) external nonReentrant {
        Kiko.DepositReceipt storage depositReceipt =
            depositReceipts[msg.sender];
        
        uint256 currentRound = vaultState.round;
        require(amount > 0, "!amount");
        require(depositReceipt.round == currentRound, "Invalid round");

        uint256 receiptAmount = depositReceipt.amount;
        require(receiptAmount >= amount, "Exceed amount");        
        
        // Subtraction underflow checks already ensure it is smaller than uint104
        depositReceipt.amount = uint104(receiptAmount.sub(amount));
        vaultState.totalPending = uint128(
            uint256(vaultState.totalPending).sub(amount)
        );

        emit InstantWithdraw(msg.sender, amount, currentRound);

        transferAsset(msg.sender, amount);
    }

    // /**
    //  * @notice Deposits the `asset` from msg.sender added to `creditor`'s deposit.
    //  * @notice Used for vault -> vault deposits on the user's behalf
    //  * @param amount is the amount of `asset` to deposit
    //  * @param creditor is the address that can claim/withdraw deposited amount
    //  */
    // function depositFor(uint256 amount, address creditor)
    //     external
    //     nonReentrant
    // {
    //     require(amount > 0, "!amount");
    //     require(creditor != address(0));

    //     _depositFor(amount, creditor);

    //     // An approve() by the msg.sender is required beforehand
    //     IERC20(vaultParams.asset).safeTransferFrom(
    //         msg.sender,
    //         address(this),
    //         amount
    //     );
    // }

    /************************************************
     *  POOL OPERATIONS
     ***********************************************/

     function _observe() internal {
        require(!optionState.hasKnockedOut, "already knocked out");
        // For the last day, vaultActiveDays is checked so that vault active days can go upto 30 instead of 29
        require(optionState.expiry > optionState.lastObservation, "vault expired");

        uint256 observeHour = (block.timestamp / 1 hours) % 24;
        require(observeHour>=8, "observe after 8AM UTC");

        uint256 observeTime = block.timestamp - (block.timestamp % (1 days)) + (8 hours);
        if (observeTime > optionState.expiry) {
            observeTime = optionState.expiry;
        }

        for (uint8 i = 0; i < vaultParams.basketSize; i++) {
            uint256 assetExpiryPrice = getExpiryPrice(vaultParams.underlyings[i], observeTime);
            require(assetExpiryPrice > 0, "observation price 0");

            uint256 upperLimit = assetStrikePrices[vaultParams.underlyings[i]].mul(vaultParams.koBar).div(Kiko.RATIO_MULTIPLIER);
            if (assetExpiryPrice >= upperLimit) {
                optionState.hasKnockedOut = true;
                optionState.koTime = observeTime;
                continue;
            }

            uint256 lowerLimit = assetStrikePrices[vaultParams.underlyings[i]].mul(vaultParams.kiBar).div(Kiko.RATIO_MULTIPLIER);            
            if (assetExpiryPrice <= lowerLimit) {
                optionState.hasKnockedIn = true;                
            }
        }

        // Employ a way to observe weekly
        // vaultActiveDays will need to be updated
        // according to the number of days passed
        // The following logic will also ensure that
        // even if the observe method is called multiple times
        // throughout the day, it won't increase vaultActiveDays
        uint256 currentActiveDays = (observeTime - optionState.lastObservation) / (1 days);
        if (optionState.lastObservation == 0) {
            currentActiveDays = 1;
        }
        optionState.vaultActiveDays += uint16(currentActiveDays);        
        optionState.lastObservation = observeTime;

        emit Observe(
            observeTime,
            optionState.hasKnockedOut,
            optionState.hasKnockedIn,
            optionState.vaultActiveDays
        );
     }

     function borrow() external nonReentrant {
        require(!optionState.isBorrowed,"already borrowed");
        require(msg.sender == borrower, "unauthorised");        

        uint256 borrowAmount = uint256(vaultState.lockedAmount).mul(optionState.borrowRate).div(Kiko.RATIO_MULTIPLIER);
        if (borrowAmount > 0) {
            transferAsset(msg.sender, borrowAmount);
        } 

        // Event for borrow amount
        emit Borrow(borrower, borrowAmount, optionState.borrowRate);

        optionState.isBorrowed = true;
     }

     function settle() external nonReentrant {
        require(block.timestamp>=optionState.expiry || optionState.hasKnockedOut, "early settle");
        require(!optionState.isSettled,"already settled");
        require(optionState.isBorrowed,"not yet borrowed");
        require(msg.sender == borrower, "unauthorised");

        (uint256 borrowedAmount, uint256 couponAmount, uint256 lossAmount) = _settleAmounts();

        uint256 netReturn = borrowedAmount.add(couponAmount);
        if (netReturn > lossAmount) {
            // An approve() by the msg.sender is required beforehand
            IERC20(vaultParams.asset).safeTransferFrom(
                msg.sender,
                address(this),
                netReturn.sub(lossAmount)
            );
        } else {
            transferAsset(borrower, lossAmount.sub(netReturn));
        }

        optionState.isSettled = true;

        // Event for settle
        emit Settle(borrower, netReturn, lossAmount, couponAmount);
     }

    //Dummy function to get price of asset at 8AM everyday
    function getExpiryPrice(address _asset, uint256 _expiryTimestamp) internal view returns (uint256) {
        ExoticOracleInterface oracle = ExoticOracleInterface(ORACLE);
        (uint256 price, )= oracle.getExpiryPrice(_asset, _expiryTimestamp);

        return price;
    }

    function updateVaultRates(uint256 _cr, uint256 _br) external onlyKeeper{
        require(_cr != 0, "!_cr");
        require(_cr != 0, "!_br");

        optionState.couponRate = _cr;
        optionState.borrowRate = _br;
    }


    /************************************************
     *  INTERNAL OPERATIONS
     ***********************************************/

     function _settleAmounts() internal view returns (uint256, uint256, uint256){
        uint256 borrowedAmount = uint256(vaultState.lockedAmount).mul(optionState.borrowRate).div(Kiko.RATIO_MULTIPLIER);
        uint256 couponAmount = uint256(vaultState.lockedAmount)
                                .mul(optionState.couponRate * optionState.vaultActiveDays)
                                .div(30*Kiko.RATIO_MULTIPLIER);

        uint256 lossAmount;
        uint256 observeTime = optionState.hasKnockedOut ? optionState.koTime : optionState.expiry;
        if (optionState.hasKnockedIn) {
                for (uint8 i = 0; i < vaultParams.basketSize; i++) {
                uint256 assetExpiryPrice = getExpiryPrice(vaultParams.underlyings[i], observeTime);
                uint256 assetStrikePrice = assetStrikePrices[vaultParams.underlyings[i]];

                if (assetExpiryPrice >= assetStrikePrice) {
                    continue;
                }
                
                uint256 lossAmountTemp = assetStrikePrice
                                            .sub(assetExpiryPrice)
                                            .mul(vaultState.lockedAmount)
                                            .div(assetStrikePrice);
                lossAmount = lossAmountTemp > lossAmount ? lossAmountTemp : lossAmount;
            }
        }

        return (borrowedAmount, couponAmount, lossAmount);
     }

    /**
     * @notice Mints the vault shares to the creditor
     * @param amount is the amount of `asset` deposited
     * @param creditor is the address to receieve the deposit
     */
    function _depositFor(uint256 amount, address creditor) private {        
        uint256 currentRound = vaultState.round;
        uint256 totalWithDepositedAmount = totalBalance().add(amount);

        require(totalWithDepositedAmount <= vaultParams.cap, "Exceed cap");
        require(
            totalWithDepositedAmount >= vaultParams.minimumSupply,
            "Insufficient balance"
        );

        emit Deposit(creditor, amount, currentRound);

        Kiko.DepositReceipt memory depositReceipt = depositReceipts[creditor];

        // If we have an unprocessed pending deposit from the previous rounds, we have to process it.
        uint256 unredeemedShares =
            depositReceipt.getSharesFromReceipt(
                currentRound,
                roundPricePerShare[depositReceipt.round],
                vaultParams.decimals
            );

        uint256 depositAmount = amount;

        // If we have a pending deposit in the current round, we add on to the pending deposit
        if (currentRound == depositReceipt.round) {
            uint256 newAmount = uint256(depositReceipt.amount).add(amount);
            depositAmount = newAmount;
        }

        ShareMathKiko.assertUint104(depositAmount);

        depositReceipts[creditor] = Kiko.DepositReceipt({
            round: uint16(currentRound),
            amount: uint104(depositAmount),
            unredeemedShares: uint128(unredeemedShares)
        });

        uint256 newTotalPending = uint256(vaultState.totalPending).add(amount);
        ShareMathKiko.assertUint128(newTotalPending);

        vaultState.totalPending = uint128(newTotalPending);
    }

    /**
     * @notice Initiates a withdrawal that can be processed once the round completes
     * @param numShares is the number of shares to withdraw
     */
    function _initiateWithdraw(uint256 numShares) internal {
        require(numShares > 0, "!numShares");

        // We do a max redeem before initiating a withdrawal
        // But we check if they must first have unredeemed shares
        if (
            depositReceipts[msg.sender].amount > 0 ||
            depositReceipts[msg.sender].unredeemedShares > 0
        ) {
            _redeem(0, true);
        }

        // This caches the `round` variable used in shareBalances
        uint256 currentRound = vaultState.round;
        Kiko.Withdrawal storage withdrawal = withdrawals[msg.sender];

        bool withdrawalIsSameRound = withdrawal.round == currentRound;

        emit InitiateWithdraw(msg.sender, numShares, currentRound);

        uint256 existingShares = uint256(withdrawal.shares);

        uint256 withdrawalShares;
        if (withdrawalIsSameRound) {
            withdrawalShares = existingShares.add(numShares);
        } else {
            require(existingShares == 0, "Existing withdraw");
            withdrawalShares = numShares;
            withdrawals[msg.sender].round = uint16(currentRound);
        }

        ShareMathKiko.assertUint128(withdrawalShares);
        withdrawals[msg.sender].shares = uint128(withdrawalShares);

        _transfer(msg.sender, address(this), numShares);
    }

    /**
     * @notice Completes a scheduled withdrawal from a past round. Uses finalized pps for the round
     * @return withdrawAmount the current withdrawal amount
     */
    function _completeWithdraw() internal returns (uint256) {
     Kiko.Withdrawal storage withdrawal = withdrawals[msg.sender];

        uint256 withdrawalShares = withdrawal.shares;
        uint256 withdrawalRound = withdrawal.round;

        // This checks if there is a withdrawal
        require(withdrawalShares > 0, "Not initiated");

        require(withdrawalRound < vaultState.round, "Round not closed");

        // We leave the round number as non-zero to save on gas for subsequent writes
        withdrawals[msg.sender].shares = 0;
        vaultState.queuedWithdrawShares = uint128(
            uint256(vaultState.queuedWithdrawShares).sub(withdrawalShares)
        );

        uint256 withdrawAmount =
            ShareMathKiko.sharesToAsset(
                withdrawalShares,
                roundPricePerShare[withdrawalRound],
                vaultParams.decimals
            );

        emit Withdraw(msg.sender, withdrawAmount, withdrawalShares);

        _burn(address(this), withdrawalShares);

        require(withdrawAmount > 0, "!withdrawAmount");

        transferAsset(msg.sender, withdrawAmount);

        return withdrawAmount;
    }

    /**
     * @notice Redeems shares that are owed to the account
     * @param numShares is the number of shares to redeem
     */
    function redeem(uint256 numShares) external nonReentrant {
        require(numShares > 0, "!numShares");
        _redeem(numShares, false);
    }

    /**
     * @notice Redeems the entire unredeemedShares balance that is owed to the account
     */
    function maxRedeem() external nonReentrant {
        _redeem(0, true);
    }

    /**
     * @notice Redeems shares that are owed to the account
     * @param numShares is the number of shares to redeem, could be 0 when isMax=true
     * @param isMax is flag for when callers do a max redemption
     */
    function _redeem(uint256 numShares, bool isMax) internal {
        Kiko.DepositReceipt memory depositReceipt =
            depositReceipts[msg.sender];

        // This handles the null case when depositReceipt.round = 0
        // Because we start with round = 1 at `initialize`
        uint256 currentRound = vaultState.round;

        uint256 unredeemedShares =
            depositReceipt.getSharesFromReceipt(
                currentRound,
                roundPricePerShare[depositReceipt.round],
                vaultParams.decimals
            );

        numShares = isMax ? unredeemedShares : numShares;
        if (numShares == 0) {
            return;
        }
        require(numShares <= unredeemedShares, "Exceeds available");

        // If we have a depositReceipt on the same round, BUT we have some unredeemed shares
        // we debit from the unredeemedShares, but leave the amount field intact
        // If the round has past, with no new deposits, we just zero it out for new deposits.
        if (depositReceipt.round < currentRound) {
            depositReceipts[msg.sender].amount = 0;
        }

        ShareMathKiko.assertUint128(numShares);
        depositReceipts[msg.sender].unredeemedShares = uint128(
            unredeemedShares.sub(numShares)
        );

        emit Redeem(msg.sender, numShares, depositReceipt.round);

        _transfer(address(this), msg.sender, numShares);
    }

    /**
     * @notice Calculates the performance and management fee for this week's round
     * @param currentBalance is the balance of funds held on the vault after closing short
     * @param lastLockedAmount is the amount of funds locked from the previous round
     * @param pendingAmount is the pending deposit amount
     * @param performanceFeePercent is the performance fee pct.
     * @param managementFeePercent is the management fee pct.
     * @return performanceFeeInAsset is the performance fee
     * @return managementFeeInAsset is the management fee
     * @return vaultFee is the total fees
     */
    function getVaultFees(
        uint256 currentBalance,
        uint256 lastLockedAmount,
        uint256 pendingAmount,
        uint256 performanceFeePercent,
        uint256 managementFeePercent        
    )
        internal
        view
        returns (
            uint256 performanceFeeInAsset,
            uint256 managementFeeInAsset,
            uint256 vaultFee
        )
    {
        // At the first round, currentBalance=0, pendingAmount>0
        // so we just do not charge anything on the first round
        uint256 lockedBalanceSansPending =
            currentBalance > pendingAmount
                ? currentBalance.sub(pendingAmount)
                : 0;

        uint256 _performanceFeeInAsset;
        uint256 _managementFeeInAsset;
        uint256 _vaultFee;

        // Take performance fee and management fee ONLY if difference between
        // last week and this week's vault deposits, taking into account pending
        // deposits and withdrawals, is positive. If it is negative, last week's
        // option expired ITM past breakeven, and the vault took a loss so we
        // do not collect performance fee for last week
        if (lockedBalanceSansPending > lastLockedAmount) {            
            _performanceFeeInAsset = performanceFeePercent > 0
                ? lockedBalanceSansPending
                    .sub(lastLockedAmount)
                    .mul(performanceFeePercent)
                    .div(100 * Kiko.FEE_MULTIPLIER)
                : 0;
            _managementFeeInAsset = managementFeePercent > 0
                ? lockedBalanceSansPending.mul(managementFeePercent).mul(optionState.vaultActiveDays).div(
                    100 * Kiko.FEE_MULTIPLIER
                )
                : 0;

            _vaultFee = _performanceFeeInAsset.add(_managementFeeInAsset);
        } else {
            _managementFeeInAsset = managementFeePercent > 0
                ? uint256(vaultState.lockedAmount).mul(managementFeePercent).mul(optionState.vaultActiveDays).div(
                    100 * Kiko.FEE_MULTIPLIER
                )
                : 0;

            _vaultFee = _managementFeeInAsset;
        }

        return (_performanceFeeInAsset, _managementFeeInAsset, _vaultFee);
    }

    /**
     * @notice Helper function to make either an ETH transfer or ERC20 transfer
     * @param recipient is the receiving address
     * @param amount is the transfer amount
     */
    function transferAsset(address recipient, uint256 amount) internal {
        address asset = vaultParams.asset;
        IERC20(asset).safeTransfer(recipient, amount);
    }

    /**
     * @notice Getter for returning the account's share balance including unredeemed shares
     * @param account is the account to lookup share balance for
     * @return the share balance
     */
    function shares(address account) public view returns (uint256) {
        (uint256 heldByAccount, uint256 heldByVault) = shareBalances(account);
        return heldByAccount.add(heldByVault);
    }

    /**
     * @notice Getter for returning the account's share balance split between account and vault holdings
     * @param account is the account to lookup share balance for
     * @return heldByAccount is the shares held by account
     * @return heldByVault is the shares held on the vault (unredeemedShares)
     */
    function shareBalances(address account)
        public
        view
        returns (uint256 heldByAccount, uint256 heldByVault)
    {
        Kiko.DepositReceipt memory depositReceipt = depositReceipts[account];

        if (depositReceipt.round < Kiko.PLACEHOLDER_UINT) {
            return (balanceOf(account), 0);
        }

        uint256 unredeemedShares =
            depositReceipt.getSharesFromReceipt(
                vaultState.round,
                roundPricePerShare[depositReceipt.round],
                vaultParams.decimals
            );

        return (balanceOf(account), unredeemedShares);
    }


    /**
     * @notice The price of a unit of share denominated in the `asset`
     */
    function pricePerShare() public view returns (uint256) {
        return
            ShareMathKiko.pricePerShare(
                totalSupply(),
                totalBalance(),
                vaultState.totalPending,
                vaultParams.decimals
            );
    }

    /**
     * @notice Returns the pool's total balance, including the amounts locked into vaults
     * @return total balance of the vault, including the amounts locked in third party protocols
     */
    function totalBalance() public view returns (uint256) {
        // Before calling closeRound, current option is set to none
        // We also commit the lockedAmount but do not deposit into Opyn
        // which results in double counting of asset balance and lockedAmount
        
        // Get the borrowed amount by the MM and add to balance of vault
        return
            optionState.isSettled
                ? IERC20(vaultParams.asset).balanceOf(address(this))
                : uint256(vaultState.lockedAmount).add(vaultState.totalPending);
    }

    function settleAmounts() public view returns (uint256 borrowedAmount, uint256 couponAmount, uint256 lossAmount) {
        return _settleAmounts();
    }


    /**
     * @notice Returns the token decimals
     */
    function decimals() public view override returns (uint8) {
        return vaultParams.decimals;
    }

    function cap() external view returns (uint256) {
        return vaultParams.cap;
    }

    function totalPending() external view returns (uint256) {
        return vaultState.totalPending;
    }
}