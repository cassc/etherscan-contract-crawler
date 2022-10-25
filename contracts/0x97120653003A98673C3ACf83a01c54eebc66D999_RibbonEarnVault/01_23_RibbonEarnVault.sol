// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Detailed} from "../../interfaces/IERC20Detailed.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {
    ReentrancyGuardUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {
    OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {
    ERC20Upgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IWETH} from "../../interfaces/IWETH.sol";

import {RibbonEarnVaultStorage} from "../../storage/RibbonEarnVaultStorage.sol";
import {Vault} from "../../libraries/Vault.sol";
import {VaultLifecycleEarn} from "../../libraries/VaultLifecycleEarn.sol";
import {ShareMath} from "../../libraries/ShareMath.sol";
import {ILiquidityGauge} from "../../interfaces/ILiquidityGauge.sol";
import {IVaultPauser} from "../../interfaces/IVaultPauser.sol";
import {IRibbonLend} from "../../interfaces/IRibbonLend.sol";

/**
 * Earn Vault Error Codes
 * R1: loan allocation in USD must be 0
 * R2: option allocation in USD must be 0
 * R3: invalid owner address
 * R4: msg.sender is not keeper
 * R5: msg.sender borrower weight is 0
 * R6: msg.sender is not option seller
 * R7: invalid keeper address
 * R8: invalid fee recipient address
 * R9: invalid option seller
 * R10: time lock still active
 * R11: management fee greater than 100%
 * R12: performance fee greater than 100%
 * R13: deposit cap is zero
 * R14: loan allocation is greater than 100%
 * R15: loan term length is less than a day
 * R16: option purchase frequency is zero
 * R17: option purchase frequency is greater than loan term length
 * R18: cannot use depositETH in non-eth vault
 * R19: cannot use depositETH with msg.value = 0
 * R20: vault asset is not USDC
 * R21: deposit amount is 0
 * R22: deposit amount exceeds vault cap
 * R23: deposit amount less than minimum supply
 * R24: cannot initiate withdraw on 0 shares
 * R25: a withdraw has already been initiated
 * R26: cannot complete withdraw when not initiated
 * R27: cannot complete withdraw when round not closed yet
 * R28: withdraw amount in complete withdraw is zero
 * R29: cannot redeem zero shares
 * R30: cannot redeem more shares than available
 * R31: cannot instantly withdraw zero
 * R32: cannot withdraw in current round
 * R33: exceeding amount withdrawable instantly
 * R34: purchasing option to early since last purchase  * R35: vault asset not recoverable
 * R36: vault share not recoverable
 * R37: recipient cannot be vault
 * R38: transfer failed  * R39: premature roll to next round
 * R40: array length mismatch
 * R41: invalid token name
 * R42: invalid token symbol
 * R43: invalid vault asset
 * R44: invalid vault minimum supply
 * R45: deposit cap must be higher than minimum supply
 * R46: next loan term length must be 0
 * R47: next option purchase frequency must be 0
 * R48: current loan term length must be >= 1 day
 * R49: current option purchase freq must be < loan term length
 * R50: loan pct + option pct == total PCT
 * R51: invalid pending option seller
 */

/**
 * UPGRADEABILITY: Since we use the upgradeable proxy pattern, we must observe
 * the inheritance chain closely.
 * Any changes/appends in storage variable needs to happen in RibbonEarnVaultStorage.
 * RibbonEarnVault should not inherit from any other contract aside from RibbonVault, RibbonEarnVaultStorage
 */
contract RibbonEarnVault is
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    ERC20Upgradeable,
    RibbonEarnVaultStorage
{
    using SafeERC20 for IERC20;
    using ShareMath for Vault.DepositReceipt;

    // *IMPORTANT* NO NEW STORAGE VARIABLES SHOULD BE ADDED HERE
    // This is to prevent storage collisions. All storage variables should be appended to RibbonEarnVaultStorage.
    // Read this documentation to learn more:
    // https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#modifying-your-contracts

    /************************************************
     *  IMMUTABLES & CONSTANTS
     ***********************************************/

    /// @notice USDC 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    uint32 public constant TOTAL_PCT = 1000000; // Equals 100%

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

    event BorrowerBasketUpdated(address[] borrowers, uint128[] borrowerWeights);

    event CommitBorrowerBasket(uint256 totalBorrowerWeight);

    event OptionSellerSet(address oldOptionSeller, address newOptionSeller);

    event NewAllocationSet(
        uint256 oldLoanAllocation,
        uint256 oldOptionAllocation,
        uint256 newLoanAllocation,
        uint256 newOptionAllocation
    );

    event NewLoanTermLength(
        uint256 oldLoanTermLength,
        uint256 newLoanTermLength
    );

    event NewOptionPurchaseFrequency(
        uint256 oldOptionPurchaseFrequency,
        uint256 newOptionPurchaseFrequency
    );

    event Withdraw(address indexed account, uint256 amount, uint256 shares);

    event CollectVaultFees(
        uint256 performanceFee,
        uint256 vaultFee,
        uint256 round,
        address indexed feeRecipient
    );

    event PurchaseOption(uint256 premium, address indexed seller);

    event PayOptionYield(
        uint256 yield,
        uint256 netYield,
        address indexed seller
    );

    event InstantWithdraw(
        address indexed account,
        uint256 amount,
        uint256 round
    );

    /************************************************
     *  STRUCTS
     ***********************************************/

    /**
     * @notice Initialization parameters for the vault.
     * @param _owner is the owner of the vault with critical permissions
     * @param _feeRecipient is the address to recieve vault performance and management fees
     * @param _borrowers is the addresses of the basket of borrowing entities (EX: Wintermute, GSR, Alameda, Genesis)
     * @param _borrowerWeights is the borrow weight of the addresses
     * @param _optionSeller is the address of the entity that we will be buying options from (EX: Orbit)
     * @param _managementFee is the management fee pct.
     * @param _performanceFee is the perfomance fee pct.
     * @param _tokenName is the name of the token
     * @param _tokenSymbol is the symbol of the token
     */
    struct InitParams {
        address _owner;
        address _keeper;
        address[] _borrowers;
        uint128[] _borrowerWeights;
        address _optionSeller;
        address _feeRecipient;
        uint256 _managementFee;
        uint256 _performanceFee;
        string _tokenName;
        string _tokenSymbol;
    }

    /************************************************
     *  CONSTRUCTOR & INITIALIZATION
     ***********************************************/

    /**
     * @notice Initializes the OptionVault contract with storage variables.
     * @param _initParams is the struct with vault initialization parameters
     * @param _vaultParams is the struct with vault general data
     * @param _allocationState is the struct with vault loan/option allocation data
     */
    function initialize(
        InitParams calldata _initParams,
        Vault.VaultParams calldata _vaultParams,
        Vault.AllocationState calldata _allocationState
    ) external initializer {
        require(_initParams._owner != address(0), "R3");

        VaultLifecycleEarn.verifyInitializerParams(
            _initParams._keeper,
            _initParams._feeRecipient,
            _initParams._optionSeller,
            _initParams._managementFee,
            _initParams._performanceFee,
            _initParams._tokenName,
            _initParams._tokenSymbol,
            _vaultParams,
            _allocationState,
            TOTAL_PCT
        );

        __ReentrancyGuard_init();
        __ERC20_init(_initParams._tokenName, _initParams._tokenSymbol);
        __Ownable_init();
        transferOwnership(_initParams._owner);

        keeper = _initParams._keeper;

        feeRecipient = _initParams._feeRecipient;
        optionSeller = _initParams._optionSeller;
        performanceFee = _initParams._performanceFee;
        managementFee =
            (_initParams._managementFee * Vault.FEE_MULTIPLIER) /
            ((365 days * Vault.FEE_MULTIPLIER) /
                _allocationState.currentLoanTermLength);
        vaultParams = _vaultParams;
        allocationState = _allocationState;

        _updateBorrowerBasket(
            _initParams._borrowers,
            _initParams._borrowerWeights
        );

        uint256 assetBalance = totalBalance();
        ShareMath.assertUint104(assetBalance);
        vaultState.lastLockedAmount = uint104(assetBalance);

        vaultState.round = 1;
    }

    /**
     * @dev Throws if called by any account other than the keeper.
     */
    modifier onlyKeeper() {
        require(msg.sender == keeper, "R4");
        _;
    }

    /**
     * @dev Throws if called by any account other than the borrower.
     */
    modifier onlyBorrower() {
        require(borrowerWeights[msg.sender].borrowerWeight > 0, "R5");
        _;
    }

    /**
     * @dev Throws if called by any account other than the option seller.
     */
    modifier onlyOptionSeller() {
        require(msg.sender == optionSeller, "R6");
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
        require(newKeeper != address(0), "R7");
        keeper = newKeeper;
    }

    /**
     * @notice Sets the new fee recipient
     * @param newFeeRecipient is the address of the new fee recipient
     */
    function setFeeRecipient(address newFeeRecipient) external onlyOwner {
        require(newFeeRecipient != address(0), "R8");
        feeRecipient = newFeeRecipient;
    }

    /**
     * @notice Updates the basket of borrowers (this overrides current pending update to basket)
     * @param borrowers is the array of borrowers to update
     * @param borrowerWeights is the array of corresponding borrow weights for the borrower
     */
    function updateBorrowerBasket(
        address[] calldata borrowers,
        uint128[] calldata borrowerWeights
    ) external onlyOwner {
        _updateBorrowerBasket(borrowers, borrowerWeights);
        lastBorrowerBasketChange = block.timestamp;
    }

    /**
     * @notice Sets the new option seller
     * @param newOptionSeller is the address of the new option seller
     */
    function setOptionSeller(address newOptionSeller) external onlyOwner {
        require(newOptionSeller != address(0), "R9");
        emit OptionSellerSet(optionSeller, newOptionSeller);
        pendingOptionSeller = newOptionSeller;
        lastOptionSellerChange = block.timestamp;
    }

    /**
     * @notice Commits the option seller
     */
    function commitOptionSeller() external onlyOwner {
        require(pendingOptionSeller != address(0), "R51");

        optionSeller = pendingOptionSeller;
        pendingOptionSeller = address(0);
    }

    /**
     * @notice Sets the management fee for the vault
     * @param newManagementFee is the management fee (6 decimals). ex: 2 * 10 ** 6 = 2%
     */
    function setManagementFee(uint256 newManagementFee) external onlyOwner {
        require(newManagementFee < 100 * Vault.FEE_MULTIPLIER, "R11");

        // We are dividing annualized management fee by loanTermLength
        uint256 tmpManagementFee =
            (newManagementFee * Vault.FEE_MULTIPLIER) /
                ((365 days * Vault.FEE_MULTIPLIER) /
                    allocationState.currentLoanTermLength);

        emit ManagementFeeSet(managementFee, tmpManagementFee);

        managementFee = tmpManagementFee;
    }

    /**
     * @notice Sets the performance fee for the vault
     * @param newPerformanceFee is the performance fee (6 decimals). ex: 20 * 10 ** 6 = 20%
     */
    function setPerformanceFee(uint256 newPerformanceFee) external onlyOwner {
        require(newPerformanceFee < 100 * Vault.FEE_MULTIPLIER, "R12");

        emit PerformanceFeeSet(performanceFee, newPerformanceFee);

        performanceFee = newPerformanceFee;
    }

    /**
     * @notice Sets a new cap for deposits
     * @param newCap is the new cap for deposits
     */
    function setCap(uint256 newCap) external onlyOwner {
        require(newCap > 0, "R13");
        ShareMath.assertUint104(newCap);
        emit CapSet(vaultParams.cap, newCap);
        vaultParams.cap = uint104(newCap);
    }

    /**
     * @notice Sets new loan and option allocation percentage
     * @dev Can be called by admin
     * @param _loanAllocationPCT new allocation for loan
     * @param _optionAllocationPCT new allocation for option
     */
    function setAllocationPCT(
        uint32 _loanAllocationPCT,
        uint32 _optionAllocationPCT
    ) external onlyOwner {
        require(_loanAllocationPCT + _optionAllocationPCT <= TOTAL_PCT, "R14");

        emit NewAllocationSet(
            uint256(allocationState.loanAllocationPCT),
            uint256(_loanAllocationPCT),
            uint256(allocationState.optionAllocationPCT),
            uint256(_optionAllocationPCT)
        );

        allocationState.loanAllocationPCT = _loanAllocationPCT;
        allocationState.optionAllocationPCT = _optionAllocationPCT;
    }

    /**
     * @notice Sets loan term length
     * @dev Can be called by admin
     * @param _loanTermLength new loan term length
     */
    function setLoanTermLength(uint32 _loanTermLength) external onlyOwner {
        require(_loanTermLength >= 1 days, "R15");

        allocationState.nextLoanTermLength = _loanTermLength;
        emit NewLoanTermLength(
            allocationState.currentLoanTermLength,
            _loanTermLength
        );
    }

    /**
     * @notice Sets option purchase frequency
     * @dev Can be called by admin
     * @param _optionPurchaseFreq new option purchase frequency
     */
    function setOptionPurchaseFrequency(uint32 _optionPurchaseFreq)
        external
        onlyOwner
    {
        require(_optionPurchaseFreq > 0, "R16");

        require(
            (allocationState.nextLoanTermLength == 0 &&
                _optionPurchaseFreq <= allocationState.currentLoanTermLength) ||
                _optionPurchaseFreq <= allocationState.nextLoanTermLength,
            "R17"
        );
        allocationState.nextOptionPurchaseFreq = _optionPurchaseFreq;
        emit NewOptionPurchaseFrequency(
            allocationState.currentOptionPurchaseFreq,
            _optionPurchaseFreq
        );
    }

    /**
     * @notice Sets the new liquidityGauge contract for this vault
     * @param newLiquidityGauge is the address of the new liquidityGauge contract
     */
    function setLiquidityGauge(address newLiquidityGauge) external onlyOwner {
        liquidityGauge = newLiquidityGauge;
    }

    /**
     * @notice Sets the new Vault Pauser contract for this vault
     * @param newVaultPauser is the address of the new vaultPauser contract
     */
    function setVaultPauser(address newVaultPauser) external onlyOwner {
        vaultPauser = newVaultPauser;
    }

    /************************************************
     *  DEPOSIT & WITHDRAWALS
     ***********************************************/

    /**
     * @notice Deposits the `asset` from msg.sender without an approve
     * `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments
     * @param amount is the amount of `asset` to deposit
     * @param deadline must be a timestamp in the future
     * @param v is a valid signature
     * @param r is a valid signature
     * @param s is a valid signature
     */
    function depositWithPermit(
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external nonReentrant {
        require(vaultParams.asset == USDC, "R20");
        require(amount > 0, "R21");

        // Sign for transfer approval
        IERC20Permit(vaultParams.asset).permit(
            msg.sender,
            address(this),
            amount,
            deadline,
            v,
            r,
            s
        );

        _depositFor(amount, msg.sender);

        // An approve() by the msg.sender is required beforehand
        IERC20(vaultParams.asset).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
    }

    /**
     * @notice Deposits the `asset` from msg.sender.
     * @param amount is the amount of `asset` to deposit
     */
    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "R21");

        _depositFor(amount, msg.sender);

        // An approve() by the msg.sender is required beforehand
        IERC20(vaultParams.asset).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
    }

    /**
     * @notice Deposits the `asset` from msg.sender added to `creditor`'s deposit.
     * @notice Used for vault -> vault deposits on the user's behalf
     * @param amount is the amount of `asset` to deposit
     * @param creditor is the address that can claim/withdraw deposited amount
     */
    function depositFor(uint256 amount, address creditor)
        external
        nonReentrant
    {
        require(amount > 0, "R21");
        require(creditor != address(0));

        _depositFor(amount, creditor);

        // An approve() by the msg.sender is required beforehand
        IERC20(vaultParams.asset).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
    }

    /**
     * @notice Mints the vault shares to the creditor
     * @param amount is the amount of `asset` deposited
     * @param creditor is the address to receieve the deposit
     */
    function _depositFor(uint256 amount, address creditor) private {
        uint256 currentRound = vaultState.round;
        uint256 totalWithDepositedAmount = totalBalance() + amount;

        require(totalWithDepositedAmount <= vaultParams.cap, "R22");
        require(totalWithDepositedAmount >= vaultParams.minimumSupply, "R23");

        emit Deposit(creditor, amount, currentRound);

        Vault.DepositReceipt memory depositReceipt = depositReceipts[creditor];

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
            uint256 newAmount = uint256(depositReceipt.amount) + amount;
            depositAmount = newAmount;
        }

        ShareMath.assertUint104(depositAmount);

        depositReceipts[creditor] = Vault.DepositReceipt({
            round: uint16(currentRound),
            amount: uint104(depositAmount),
            unredeemedShares: uint128(unredeemedShares)
        });

        uint256 newTotalPending = uint256(vaultState.totalPending) + amount;
        ShareMath.assertUint128(newTotalPending);

        vaultState.totalPending = uint128(newTotalPending);
    }

    /**
     * @notice Initiates a withdrawal that can be processed once the round completes
     * @param numShares is the number of shares to withdraw
     */
    function _initiateWithdraw(uint256 numShares) internal {
        require(numShares > 0, "R24");

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
        Vault.Withdrawal storage withdrawal = withdrawals[msg.sender];

        bool withdrawalIsSameRound = withdrawal.round == currentRound;

        emit InitiateWithdraw(msg.sender, numShares, currentRound);

        uint256 existingShares = uint256(withdrawal.shares);

        uint256 withdrawalShares;
        if (withdrawalIsSameRound) {
            withdrawalShares = existingShares + numShares;
        } else {
            require(existingShares == 0, "R25");
            withdrawalShares = numShares;
            withdrawal.round = uint16(currentRound);
        }

        ShareMath.assertUint128(withdrawalShares);
        withdrawal.shares = uint128(withdrawalShares);

        _transfer(msg.sender, address(this), numShares);
    }

    /**
     * @notice Completes a scheduled withdrawal from a past round. Uses finalized pps for the round
     * @return withdrawAmount the current withdrawal amount
     */
    function _completeWithdraw() internal returns (uint256) {
        Vault.Withdrawal storage withdrawal = withdrawals[msg.sender];

        uint256 withdrawalShares = withdrawal.shares;
        uint256 withdrawalRound = withdrawal.round;

        // This checks if there is a withdrawal
        require(withdrawalShares > 0, "R26");

        require(withdrawalRound < vaultState.round, "R27");

        // We leave the round number as non-zero to save on gas for subsequent writes
        withdrawal.shares = 0;
        vaultState.queuedWithdrawShares = uint128(
            uint256(vaultState.queuedWithdrawShares) - withdrawalShares
        );

        uint256 withdrawAmount =
            ShareMath.sharesToAsset(
                withdrawalShares,
                roundPricePerShare[withdrawalRound],
                vaultParams.decimals
            );

        emit Withdraw(msg.sender, withdrawAmount, withdrawalShares);

        _burn(address(this), withdrawalShares);

        return withdrawAmount;
    }

    /**
     * @notice Redeems shares that are owed to the account
     * @param numShares is the number of shares to redeem
     */
    function redeem(uint256 numShares) external nonReentrant {
        require(numShares > 0, "R29");
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
        Vault.DepositReceipt memory depositReceipt =
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
        require(numShares <= unredeemedShares, "R30");

        // If we have a depositReceipt on the same round, BUT we have some unredeemed shares
        // we debit from the unredeemedShares, but leave the amount field intact
        // If the round has past, with no new deposits, we just zero it out for new deposits.
        if (depositReceipt.round < currentRound) {
            depositReceipts[msg.sender].amount = 0;
        }

        ShareMath.assertUint128(numShares);
        depositReceipts[msg.sender].unredeemedShares = uint128(
            unredeemedShares - numShares
        );

        emit Redeem(msg.sender, numShares, depositReceipt.round);

        _transfer(address(this), msg.sender, numShares);
    }

    /**
     * @notice Withdraws the assets on the vault using the outstanding `DepositReceipt.amount`
     * @param amount is the amount to withdraw
     */
    function withdrawInstantly(uint256 amount) external nonReentrant {
        Vault.DepositReceipt storage depositReceipt =
            depositReceipts[msg.sender];

        uint256 currentRound = vaultState.round;
        require(amount > 0, "R31");
        require(depositReceipt.round == currentRound, "R32");

        uint256 receiptAmount = depositReceipt.amount;
        require(receiptAmount >= amount, "R33");

        // Subtraction underflow checks already ensure it is smaller than uint104
        depositReceipt.amount = uint104(receiptAmount - amount);
        vaultState.totalPending = uint128(
            uint256(vaultState.totalPending) - amount
        );

        emit InstantWithdraw(msg.sender, amount, currentRound);

        IERC20(vaultParams.asset).safeTransfer(msg.sender, amount);
    }

    /**
     * @notice Initiates a withdrawal that can be processed once the round completes
     * @param numShares is the number of shares to withdraw
     */
    function initiateWithdraw(uint256 numShares) external nonReentrant {
        _initiateWithdraw(numShares);
        currentQueuedWithdrawShares = currentQueuedWithdrawShares + numShares;
    }

    /**
     * @notice Completes a scheduled withdrawal from a past round. Uses finalized pps for the round
     */
    function completeWithdraw() external nonReentrant {
        uint256 withdrawAmount = _completeWithdraw();

        require(withdrawAmount > 0, "R28");
        lastQueuedWithdrawAmount = uint128(
            uint256(lastQueuedWithdrawAmount) - withdrawAmount
        );
        IERC20(vaultParams.asset).safeTransfer(msg.sender, withdrawAmount);
    }

    /************************************************
     *  VAULT OPERATIONS
     ***********************************************/

    /**
     * @notice Stakes a users vault shares
     * @param numShares is the number of shares to stake
     */
    function stake(uint256 numShares) external nonReentrant {
        address _liquidityGauge = liquidityGauge;
        require(_liquidityGauge != address(0)); // Removed revert msgs due to contract size limit
        require(numShares > 0);
        uint256 heldByAccount = balanceOf(msg.sender);
        if (heldByAccount < numShares) {
            _redeem(numShares - heldByAccount, false);
        }
        _transfer(msg.sender, address(this), numShares);
        _approve(address(this), _liquidityGauge, numShares);
        ILiquidityGauge(_liquidityGauge).deposit(numShares, msg.sender, false);
    }

    /**
     * @notice Rolls the vault's funds into a new loan + long option position.
     */
    function rollToNextRound() external onlyKeeper nonReentrant {
        vaultState.lastLockedAmount = uint104(vaultState.lockedAmount);

        (uint256 lockedBalance, uint256 queuedWithdrawAmount) =
            _rollToNextRound();

        lastQueuedWithdrawAmount = queuedWithdrawAmount;

        uint256 newQueuedWithdrawShares =
            uint256(vaultState.queuedWithdrawShares) +
                currentQueuedWithdrawShares;

        ShareMath.assertUint128(newQueuedWithdrawShares);
        vaultState.queuedWithdrawShares = uint128(newQueuedWithdrawShares);

        currentQueuedWithdrawShares = 0;

        ShareMath.assertUint104(lockedBalance);

        vaultState.lockedAmount = uint104(lockedBalance);
        vaultState.optionsBoughtInRound = 0;

        uint256 loanAllocation = allocationState.loanAllocation;

        for (uint256 i = 0; i < borrowers.length; i++) {
            // Amount to lending = total USD loan allocation * weight of current borrower / total weight of all borrowers
            uint256 amtToLendToBorrower =
                (loanAllocation *
                    borrowerWeights[borrowers[i]].borrowerWeight) /
                    totalBorrowerWeight;

            IRibbonLend lendPool = IRibbonLend(borrowers[i]);
            uint256 currLendingPoolBalance = _lendingPoolBalance(lendPool);

            // If we need to decrease loan allocation, exit Ribbon Lend Pool, otherwise allocate to pool
            if (currLendingPoolBalance > amtToLendToBorrower) {
                lendPool.redeemCurrency(
                    currLendingPoolBalance - amtToLendToBorrower
                );
            } else if (amtToLendToBorrower > currLendingPoolBalance) {
                IERC20(vaultParams.asset).safeApprove(
                    borrowers[i],
                    amtToLendToBorrower - currLendingPoolBalance
                );
                lendPool.provide(
                    amtToLendToBorrower - currLendingPoolBalance,
                    address(0)
                );
            }
        }
    }

    /**
     * @notice Buys the option by transferring premiums to option seller
     */
    function buyOption() external onlyKeeper {
        require(
            vaultState.optionsBoughtInRound == 0 ||
                block.timestamp >=
                uint256(vaultState.lastOptionPurchaseTime) +
                    allocationState.currentOptionPurchaseFreq,
            "R34"
        );

        uint256 optionAllocation =
            allocationState.optionAllocation /
                (uint256(allocationState.currentLoanTermLength) /
                    allocationState.currentOptionPurchaseFreq);

        vaultState.optionsBoughtInRound += uint128(optionAllocation);
        vaultState.lastOptionPurchaseTime = uint64(
            block.timestamp - (block.timestamp % (24 hours)) + (8 hours)
        );

        IERC20(vaultParams.asset).safeTransfer(optionSeller, optionAllocation);

        emit PurchaseOption(optionAllocation, optionSeller);
    }

    /**
     * @notice Pays option yield if option is ITM
     * `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments
     * @param amount is the amount of yield to pay
     * @param deadline must be a timestamp in the future
     * @param v is a valid signature
     * @param r is a valid signature
     * @param s is a valid signature
     */
    function payOptionYield(
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external onlyOptionSeller {
        // Sign for transfer approval
        IERC20Permit(vaultParams.asset).permit(
            msg.sender,
            address(this),
            amount,
            deadline,
            v,
            r,
            s
        );

        // Pay option yields to contract
        _payOptionYield(amount);
    }

    /**
     * @notice Pays option yield if option is ITM
     * @param amount is the amount of yield to pay
     */
    function payOptionYield(uint256 amount) external onlyOptionSeller {
        // Pay option yields to contract
        _payOptionYield(amount);
    }

    /**
     * @notice Recovery function that returns an ERC20 token to the recipient
     * @param token is the ERC20 token to recover from the vault
     * @param recipient is the recipient of the recovered tokens
     */
    function recoverTokens(address token, address recipient)
        external
        onlyOwner
    {
        require(token != vaultParams.asset, "R35");
        require(token != address(this), "R36");
        require(recipient != address(this), "R37");

        IERC20(token).safeTransfer(
            recipient,
            IERC20(token).balanceOf(address(this))
        );
    }

    /**
     * @notice pause a user's vault position
     */
    function pausePosition() external {
        address _vaultPauserAddress = vaultPauser;
        require(_vaultPauserAddress != address(0)); // Removed revert msgs due to contract size limit
        _redeem(0, true);
        uint256 heldByAccount = balanceOf(msg.sender);
        _approve(msg.sender, _vaultPauserAddress, heldByAccount);
        IVaultPauser(_vaultPauserAddress).pausePosition(
            msg.sender,
            heldByAccount
        );
    }

    /**
     * @notice Helper function that performs most administrative tasks
     * such as minting new shares, getting vault fees, etc.
     * @return lockedBalance is the new balance used to calculate next option purchase size or collateral size
     * @return queuedWithdrawAmount is the new queued withdraw amount for this round
     */
    function _rollToNextRound()
        internal
        returns (uint256 lockedBalance, uint256 queuedWithdrawAmount)
    {
        require(
            block.timestamp >=
                uint256(vaultState.lastEpochTime) +
                    allocationState.currentLoanTermLength,
            "R39"
        );

        address recipient = feeRecipient;
        uint256 mintShares;
        uint256 performanceFeeInAsset;
        uint256 totalVaultFee;
        {
            uint256 newPricePerShare;
            (
                lockedBalance,
                queuedWithdrawAmount,
                newPricePerShare,
                mintShares,
                performanceFeeInAsset,
                totalVaultFee
            ) = VaultLifecycleEarn.rollover(
                vaultState,
                VaultLifecycleEarn.RolloverParams(
                    vaultParams.decimals,
                    totalBalance(),
                    totalSupply(),
                    lastQueuedWithdrawAmount,
                    performanceFee,
                    managementFee,
                    currentQueuedWithdrawShares
                )
            );

            // Finalize the pricePerShare at the end of the round
            uint256 currentRound = vaultState.round;
            roundPricePerShare[currentRound] = newPricePerShare;

            emit CollectVaultFees(
                performanceFeeInAsset,
                totalVaultFee,
                currentRound,
                recipient
            );

            vaultState.totalPending = 0;
            vaultState.round = uint16(currentRound + 1);
            vaultState.lastEpochTime = uint64(
                block.timestamp - (block.timestamp % (24 hours)) + (8 hours)
            );
        }

        _mint(address(this), mintShares);

        if (totalVaultFee > 0) {
            IERC20(vaultParams.asset).safeTransfer(recipient, totalVaultFee);
        }

        _updateAllocationState(lockedBalance);
        _commitBorrowerBasket();

        return (lockedBalance, queuedWithdrawAmount);
    }

    /**
     * @notice Helper function that transfers funds from option
     * seller
     * @param amount is the amount of yield to pay
     */
    function _payOptionYield(uint256 amount) internal {
        IERC20(vaultParams.asset).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        uint256 optionAllocation =
            allocationState.optionAllocation /
                (uint256(allocationState.currentLoanTermLength) /
                    allocationState.currentOptionPurchaseFreq);

        emit PayOptionYield(
            amount,
            amount > optionAllocation ? amount - optionAllocation : 0,
            msg.sender
        );
    }

    /**
     * @notice Helper function that updates allocation state
     * such as loan term length, option purchase frequency, loan / option
     * allocation split, etc.
     * @param lockedBalance is the locked balance for newest epoch
     */
    function _updateAllocationState(uint256 lockedBalance) internal {
        Vault.AllocationState memory _allocationState = allocationState;

        // Set next loan term length
        if (_allocationState.nextLoanTermLength != 0) {
            uint256 tmpManagementFee = managementFee;
            managementFee =
                (tmpManagementFee * _allocationState.nextLoanTermLength) /
                _allocationState.currentLoanTermLength;

            allocationState.currentLoanTermLength = _allocationState
                .nextLoanTermLength;
            allocationState.nextLoanTermLength = 0;

            emit ManagementFeeSet(tmpManagementFee, managementFee);
        }

        // Set next option purchase frequency
        if (_allocationState.nextOptionPurchaseFreq != 0) {
            allocationState.currentOptionPurchaseFreq = _allocationState
                .nextOptionPurchaseFreq;
            allocationState.nextOptionPurchaseFreq = 0;
        }

        // Set next loan allocation from vault in USD
        allocationState.loanAllocation =
            (uint256(_allocationState.loanAllocationPCT) * lockedBalance) /
            TOTAL_PCT;

        // Set next option allocation from vault per purchase in USD
        allocationState.optionAllocation =
            (uint256(_allocationState.optionAllocationPCT) * lockedBalance) /
            TOTAL_PCT;
    }

    /**
     * @notice Helper function to update basket of borrowers
     * @param pendingBorrowers is the array of borrowers to add
     * @param pendingBorrowWeights is the array of corresponding borrow weights for the borrower
     */
    function _updateBorrowerBasket(
        address[] calldata pendingBorrowers,
        uint128[] calldata pendingBorrowWeights
    ) internal {
        uint256 borrowerArrLen = pendingBorrowers.length;

        require(borrowerArrLen == pendingBorrowWeights.length, "R40");

        // Set current pending changes to basket of borrowers
        for (uint256 i = 0; i < borrowerArrLen; i++) {
            if (pendingBorrowers[i] == address(0)) {
                continue;
            }

            // Borrower does not exist
            if (!borrowerWeights[pendingBorrowers[i]].exists) {
                borrowers.push(pendingBorrowers[i]);
                borrowerWeights[pendingBorrowers[i]].exists = true;
            }

            // Set pending borrower weight
            borrowerWeights[pendingBorrowers[i]]
                .pendingBorrowerWeight = pendingBorrowWeights[i];
        }

        emit BorrowerBasketUpdated(pendingBorrowers, pendingBorrowWeights);
    }

    /**
     * @notice Helper function that commits borrower basket
     */
    function _commitBorrowerBasket() internal {
        require(block.timestamp >= (lastBorrowerBasketChange + 3 days), "R10");

        // Set current pending changes to basket of borrowers
        for (uint256 i = 0; i < borrowers.length; i++) {
            uint128 borrowWeight = borrowerWeights[borrowers[i]].borrowerWeight;
            uint128 pendingBorrowWeight =
                borrowerWeights[borrowers[i]].pendingBorrowerWeight;
            // Set borrower weight to pending borrower weight
            if (borrowWeight != pendingBorrowWeight) {
                borrowerWeights[borrowers[i]]
                    .borrowerWeight = pendingBorrowWeight;
                // Update total borrowing weight
                totalBorrowerWeight += pendingBorrowWeight;
                totalBorrowerWeight -= borrowWeight;
            }
        }

        emit CommitBorrowerBasket(totalBorrowerWeight);
    }

    /************************************************
     *  GETTERS
     ***********************************************/

    /**
     * @notice Returns the Ribbon Earn vault balance in a Ribbon Lend Pool
     * @param lendPool is the Ribbon Lend pool
     * @return the amount of `asset` deposited into the lend pool
     */
    function _lendingPoolBalance(IRibbonLend lendPool)
        internal
        view
        returns (uint256)
    {
        // Current exchange rate is 18-digits decimal
        return
            (lendPool.balanceOf(address(this)) *
                lendPool.getCurrentExchangeRate()) / 10**18;
    }

    /**
     * @notice Returns the asset balance held on the vault for the account
     * @param account is the address to lookup balance for
     * @return the amount of `asset` custodied by the vault for the user
     */
    function accountVaultBalance(address account)
        external
        view
        returns (uint256)
    {
        uint256 _decimals = vaultParams.decimals;
        uint256 assetPerShare =
            ShareMath.pricePerShare(
                totalSupply(),
                totalBalance(),
                vaultState.totalPending,
                _decimals
            );
        return
            ShareMath.sharesToAsset(shares(account), assetPerShare, _decimals);
    }

    /**
     * @notice Getter for returning the account's share balance including unredeemed shares
     * @param account is the account to lookup share balance for
     * @return the share balance
     */
    function shares(address account) public view returns (uint256) {
        (uint256 heldByAccount, uint256 heldByVault) = shareBalances(account);
        return heldByAccount + heldByVault;
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
        Vault.DepositReceipt memory depositReceipt = depositReceipts[account];

        if (depositReceipt.round < ShareMath.PLACEHOLDER_UINT) {
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
    function pricePerShare() external view returns (uint256) {
        return
            ShareMath.pricePerShare(
                totalSupply(),
                totalBalance(),
                vaultState.totalPending,
                vaultParams.decimals
            );
    }

    /**
     * @notice Returns the vault's total balance, including the amounts lent out
     * @return total balance of the vault, including the amounts locked in third party protocols
     */
    function totalBalance() public view returns (uint256) {
        // Does not include funds allocated for options purchases
        // Includes funds set aside in vault that guarantee base yield

        uint256 totalBalance =
            IERC20(vaultParams.asset).balanceOf(address(this));

        for (uint256 i = 0; i < borrowers.length; i++) {
            totalBalance += _lendingPoolBalance(IRibbonLend(borrowers[i]));
        }

        return totalBalance;
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