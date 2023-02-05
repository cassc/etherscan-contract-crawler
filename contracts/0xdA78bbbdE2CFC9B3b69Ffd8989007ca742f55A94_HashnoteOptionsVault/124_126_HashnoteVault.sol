// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { ERC1155TokenReceiver } from "../../../../lib/solmate/src/tokens/ERC1155.sol";
import { IERC20 } from "../../../../lib/openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "../../../../lib/openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { FixedPointMathLib } from "../../../../lib/solmate/src/utils/FixedPointMathLib.sol";

import { OwnableUpgradeable } from "../../../../lib/openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from
    "../../../../lib/openzeppelin-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";

import { Vault } from "../../../libraries/Vault.sol";
import { VaultUtil } from "../../../libraries/VaultUtil.sol";
import { FeeUtil } from "../../../libraries/FeeUtil.sol";

import { IVaultShare } from "../../../interfaces/IVaultShare.sol";
import { IVaultPauser } from "../../../interfaces/IVaultPauser.sol";
import { IWhitelist } from "../../../interfaces/IWhitelist.sol";

import "../../../libraries/Errors.sol";

contract HashnoteVault is ERC1155TokenReceiver, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;

    /*///////////////////////////////////////////////////////////////
                        Non Upgradeable Storage
    //////////////////////////////////////////////////////////////*/

    // the erc1155 contract that issues vault shares
    IVaultShare public immutable share;

    /// @notice Stores the user's pending deposit for the round
    mapping(address => Vault.DepositReceipt) public depositReceipts;

    /// @notice On every round's close, the pricePerShare value of an hnVault token is stored
    /// This is used to determine the number of shares to be given to a user with
    /// their DepositReceipt.depositAmount
    mapping(uint256 => uint256) public roundPricePerShare;

    /// @notice deposit asset amounts round => collateralBalances[]
    mapping(uint256 => uint256[]) public roundStartingBalances;

    /// @notice expiry of each round
    mapping(uint256 => uint256) public roundExpiry;

    /// @notice Vault's parameters
    Vault.VaultParams public vaultParams;

    /// Linear combination of options
    Vault.Instrument[] public instruments;

    /// Assets deposited into vault
    // collaterals[0] is the primary asset, other assets are relative to the primary
    Vault.Collateral[] public collaterals;

    /// @notice Vault's round state
    Vault.VaultState public vaultState;

    /// @notice Vault's option state
    Vault.OptionState public optionState;

    /// @notice Vault's round configuration
    Vault.RoundConfig public roundConfig;

    // Oracle addres to caculcate Net Asset Value (for round shareprice)
    address public oracle;

    /// @notice Vault Pauser Contract for the vault
    address public pauser;

    /// @notice Whitelist contract, checks permissions and sanctions
    address public whitelist;

    /// @notice Fee recipient for the management and performance fees
    address public feeRecipient;

    /// @notice role in charge of round operations such as stageStructure, startAuction and closeRound
    address public manager;

    /// @notice Management fee charged on entire AUM at closeRound.
    uint256 public managementFee;

    /// @notice Performance fee charged on premiums earned in closeRound. Only charged when round takes a profit.
    uint256 public performanceFee;

    // *IMPORTANT* NO NEW STORAGE VARIABLES SHOULD BE ADDED HERE

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    event Deposited(address indexed account, uint256[] amounts, uint256 round);

    event QuickWithdrew(address indexed account, uint256[] amounts, uint256 round);

    event RequestedWithdraw(address indexed account, uint256 shares, uint256 round);

    event Withdrew(address indexed account, uint256[] amounts, uint256 shares);

    event CollectedFees(uint256[] vaultFee, uint256[] performanceFee, uint256 round, address indexed feeRecipient);

    event Redeem(address indexed account, uint256 share, uint256 round);

    event ManagerSet(address manager, address newManager);

    event FeeRecipientSet(address feeRecipient, address newFeeRecipient);

    event ManagementFeeSet(uint256 managementFee, uint256 newManagementFee);

    event PerformanceFeeSet(uint256 performanceFee, uint256 newPerformanceFee);

    event WhitelistSet(address whitelist, address newWhitelist);

    event PauserSet(address pauser, address newPauser);

    event CapSet(uint256 cap, uint256 newCap);

    event RoundConfigSet(
        uint32 duration, uint8 dayOfWeek, uint8 hourOfDay, uint32 newDuration, uint8 newDayOfWeek, uint8 newHourOfDay
    );

    /*///////////////////////////////////////////////////////////////
                        Constructor & Initializer
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the contract with immutable variables
     */
    constructor(address _share) {
        if (_share == address(0)) revert HV_BadAddress();

        share = IVaultShare(_share);
    }

    /**
     * @notice Initializes the Vault contract with storage variables.
     */
    function baseInitialize(Vault.InitParams calldata _initParams, Vault.VaultParams calldata _vaultParams)
        internal
        onlyInitializing
    {
        VaultUtil.verifyInitializerParams(_initParams, _vaultParams);

        __ReentrancyGuard_init_unchained();
        __Ownable_init();
        transferOwnership(_initParams._owner);

        manager = _initParams._manager;

        oracle = _initParams._oracle;
        feeRecipient = _initParams._feeRecipient;
        performanceFee = _initParams._performanceFee;
        managementFee = _initParams._managementFee;
        pauser = _initParams._pauser;
        vaultParams = _vaultParams;
        roundConfig = _initParams._roundConfig;

        uint256 i;
        for (i; i < _initParams._instruments.length;) {
            instruments.push(_initParams._instruments[i]);

            unchecked {
                ++i;
            }
        }

        for (i = 0; i < _initParams._collaterals.length;) {
            collaterals.push(_initParams._collaterals[i]);

            unchecked {
                ++i;
            }
        }

        uint256 collateralBalance = IERC20(collaterals[0].addr).balanceOf(address(this));
        _assertUint104(collateralBalance);
        vaultState.lastLockedAmount = uint104(collateralBalance);

        vaultState.round = 1;
    }

    /*///////////////////////////////////////////////////////////////
                            Setters
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets the new keeper
     * @param _manager is the address of the new keeper
     */
    function setManager(address _manager) external {
        _onlyOwner();

        if (_manager == address(0)) revert HV_BadAddress();

        emit ManagerSet(manager, _manager);

        manager = _manager;
    }

    /**
     * @notice Sets the new fee recipient
     * @param _feeRecipient is the address of the new fee recipient
     */
    function setFeeRecipient(address _feeRecipient) external {
        _onlyOwner();

        if (_feeRecipient == address(0) || _feeRecipient == feeRecipient) {
            revert HV_BadAddress();
        }

        emit FeeRecipientSet(feeRecipient, _feeRecipient);

        feeRecipient = _feeRecipient;
    }

    /**
     * @notice Sets the management fee for the vault
     * @param _managementFee is the management fee (18 decimals). ex: 2 * 10 ** 18 = 2%
     */
    function setManagementFee(uint256 _managementFee) external {
        _onlyOwner();

        if (_managementFee > 100 * Vault.FEE_MULTIPLIER) revert HV_BadFee();

        emit ManagementFeeSet(managementFee, _managementFee);

        managementFee = _managementFee;
    }

    /**
     * @notice Sets the performance fee for the vault
     * @param _performanceFee is the performance fee (18 decimals). ex: 20 * 10 ** 18 = 20%
     */
    function setPerformanceFee(uint256 _performanceFee) external {
        _onlyOwner();

        if (_performanceFee > 100 * Vault.FEE_MULTIPLIER) revert HV_BadFee();

        emit PerformanceFeeSet(performanceFee, _performanceFee);

        performanceFee = _performanceFee;
    }

    /**
     * @notice Sets a new cap for deposits
     * @param _cap is the new cap for deposits
     */
    function setCap(uint256 _cap) external {
        _onlyOwner();

        if (_cap == 0) revert HV_BadCap();

        _assertUint104(_cap);

        emit CapSet(vaultParams.cap, _cap);

        vaultParams.cap = uint104(_cap);
    }

    /**
     * @notice Sets the new Vault Pauser contract for this vault
     * @dev this is where all asset withdraws are custodied
     * @param _pauser is the address of the new pauser contract
     */
    function setPauser(address _pauser) external {
        _onlyOwner();

        if (_pauser == address(0)) revert HV_BadAddress();

        emit PauserSet(pauser, _pauser);

        pauser = _pauser;
    }

    /**
     * @notice Sets the whitelist contract
     * @dev this contract checks permissioning and sanctions
     * @param _whitelist is the address of the new whitelist
     */
    function setWhitelist(address _whitelist) external {
        _onlyOwner();

        emit WhitelistSet(whitelist, _whitelist);

        whitelist = _whitelist;
    }

    /**
     * @notice Sets new round Config
     * @dev this changes the expiry of options
     * @param _duration  the duration of the option
     * @param _dayOfWeek day of the week the option should expire. 0-8, 0 is sunday, 7 is sunday, 8 is wild
     * @param _hourOfDay hour of the day the option should expire. 0 is midnight
     */
    function setRoundConfig(uint32 _duration, uint8 _dayOfWeek, uint8 _hourOfDay) external {
        _onlyOwner();

        if (_duration == 0 || _dayOfWeek > 8 || _hourOfDay > 23) revert HV_BadRoundConfig();

        emit RoundConfigSet(roundConfig.duration, roundConfig.dayOfWeek, roundConfig.hourOfDay, _duration, _dayOfWeek, _hourOfDay);

        roundConfig = Vault.RoundConfig(_duration, _dayOfWeek, _hourOfDay);
    }

    /*///////////////////////////////////////////////////////////////
                            Deposit & Withdraws
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deposits the `asset` from msg.sender added to `creditor`'s deposit
     * @param amount is the amount of primary asset to deposit
     * @param creditor is the address that can claim/withdraw deposited amount
     */
    function depositFor(uint256 amount, address creditor) external nonReentrant {
        if (amount == 0) revert HV_BadDepositAmount();

        if (creditor == address(0)) creditor = msg.sender;

        _validateWhitelisted(msg.sender);

        if (creditor != msg.sender) _validateWhitelisted(creditor);

        uint256 currentRound = vaultState.round;

        uint256 totalDepositedAmount = vaultState.lockedAmount + amount;

        if (totalDepositedAmount > vaultParams.cap) revert HV_ExceedsCap();

        if (totalDepositedAmount < vaultParams.minimumSupply) revert HV_InsufficientFunds();

        uint256 unredeemedShares;

        Vault.DepositReceipt memory depositReceipt = depositReceipts[creditor];

        // if we have an unprocessed pending deposit from the previous rounds, we first process it.
        if (depositReceipt.amount > 0) {
            unredeemedShares = FeeUtil.getSharesFromReceipt(
                depositReceipt,
                currentRound,
                roundPricePerShare[depositReceipt.round],
                _relativeNAVInRound(depositReceipt.round, depositReceipt.amount)
            );
        }

        uint256 depositAmount = amount;

        // if we have a pending deposit in the current round, we add on to the pending deposit
        if (currentRound == depositReceipt.round) depositAmount = uint256(depositReceipt.amount) + amount;

        _assertUint104(depositAmount);

        depositReceipts[creditor] = Vault.DepositReceipt({
            round: uint16(currentRound),
            amount: uint104(depositAmount),
            unredeemedShares: uint128(unredeemedShares)
        });

        // keeping track of total pending primary asset
        uint256 newTotalPending = uint256(vaultState.totalPending) + amount;

        _assertUint128(newTotalPending);

        vaultState.totalPending = uint128(newTotalPending);

        // pulling all collaterals from msg.sender
        // An approve() by the msg.sender is required for all collaterals beforehand
        uint256[] memory amounts = _transferAssets(amount, address(this), currentRound);

        emit Deposited(creditor, amounts, currentRound);
    }

    /**
     * @notice Withdraws the assets of the vault using the outstanding `DepositReceipt.amount`
     * @dev only pending funds can be withdrawn using this method
     * @param amount is the pending amount of primary asset to be withdrawn
     */
    function quickWithdraw(uint256 amount) external nonReentrant {
        if (amount == 0) revert HV_BadAmount();

        _validateWhitelisted(msg.sender);

        Vault.DepositReceipt storage depositReceipt = depositReceipts[msg.sender];

        uint256 currentRound = vaultState.round;

        if (depositReceipt.round != currentRound) revert HV_BadRound();

        uint256 receiptAmount = depositReceipt.amount;

        if (receiptAmount < amount) revert HV_BadAmount();

        // subtraction underflow checks already ensure it is smaller than uint104
        depositReceipt.amount = uint104(receiptAmount - amount);

        vaultState.totalPending = uint128(uint256(vaultState.totalPending) - amount);

        // array of asset amounts transfered back from account
        uint256[] memory amounts = _transferAssets(amount, msg.sender, currentRound);

        emit QuickWithdrew(msg.sender, amounts, currentRound);
    }

    /**
     * @notice requests a withdraw that can be processed once the round closes
     * @param numShares is the number of shares to withdraw
     */
    function requestWithdraw(uint256 numShares) external {
        if (numShares == 0) revert HV_BadNumShares();

        _assertUint128(numShares);

        Vault.DepositReceipt storage depositReceipt = depositReceipts[msg.sender];

        // if unredeemed shares exist, do a max redeem before initiating a withdraw
        if (depositReceipt.amount > 0 || depositReceipt.unredeemedShares > 0) redeem(0, true);

        // keeping track of total shares requested to withdraw at the end of round
        uint256 queuedWithdrawShares = vaultState.queuedWithdrawShares + numShares;

        _assertUint128(queuedWithdrawShares);

        vaultState.queuedWithdrawShares = uint128(queuedWithdrawShares);

        // transfering vault tokens (shares) back to vault, to be burned when round closes
        share.transferFrom(msg.sender, address(this), address(this), numShares, "");

        // storing shares in pauser for future asset(s) withdraw
        IVaultPauser(pauser).pausePosition(msg.sender, numShares);

        emit RequestedWithdraw(msg.sender, numShares, vaultState.round);
    }

    /**
     * @notice Redeems shares that are owed to the account
     * @param numShares is the number of shares to redeem, could be 0 when isMax=true
     * @param isMax is flag for when callers do a max redemption
     */
    function redeem(uint256 numShares, bool isMax) public nonReentrant {
        if (!isMax && numShares == 0) revert HV_BadNumShares();

        Vault.DepositReceipt storage depositReceipt = depositReceipts[msg.sender];

        uint256 depositInRound = depositReceipt.round;

        uint256 currentRound = vaultState.round;

        uint256 unredeemedShares = FeeUtil.getSharesFromReceipt(
            depositReceipt,
            currentRound,
            roundPricePerShare[depositInRound],
            _relativeNAVInRound(depositInRound, depositReceipt.amount)
        );

        if (isMax) numShares = unredeemedShares;

        if (numShares == 0) return;

        if (numShares > unredeemedShares) revert HV_ExceedsAvailable();

        _assertUint128(numShares);

        // if we have a depositReceipt on the same round, BUT we have unredeemed shares
        // we debit from the unredeemedShares, leaving the amount field intact
        depositReceipt.unredeemedShares = uint128(unredeemedShares - numShares);

        // if the round has past we zero amount for new deposits.
        if (depositInRound < currentRound) depositReceipt.amount = 0;

        emit Redeem(msg.sender, numShares, depositInRound);

        // account shares minted at closeRound to vault, we transfer to account from vault
        share.transferFrom(address(this), msg.sender, address(this), numShares, "");
    }

    /*///////////////////////////////////////////////////////////////
                            Vault Operations
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Helper function to save gas for writing values into storage maps.
     *         Writing 1's into maps makes subsequent writes warm, reducing the gas significantly.
     * @param numRounds is the number of rounds to initialize in the maps
     */
    function initRounds(uint256 numRounds) external {
        uint256 i;
        uint256 _round = vaultState.round;

        uint256[] memory placeholderBalances = new uint256[](collaterals.length);
        for (i; i < placeholderBalances.length;) {
            placeholderBalances[i] = Vault.PLACEHOLDER_UINT;

            unchecked {
                ++i;
            }
        }

        for (i = 0; i < numRounds;) {
            uint256 index = _round;

            unchecked {
                index += i;
            }

            if (roundPricePerShare[index] > 0) revert HV_BadPPS();
            if (roundExpiry[index] > 0) revert HV_BadExpiry();
            if (roundStartingBalances[index].length > 0) revert HV_BadSB();

            roundPricePerShare[index] = Vault.PLACEHOLDER_UINT;
            roundExpiry[index] = Vault.PLACEHOLDER_UINT;
            roundStartingBalances[index] = placeholderBalances;

            ++i;
        }
    }

    function _onlyManager() internal view {
        if (msg.sender != manager) revert HV_Unauthorized();
    }

    function _onlyOwner() internal view {
        if (msg.sender != owner()) revert HV_Unauthorized();
    }

    function _onlyPauser() internal view {
        if (msg.sender != pauser) revert HV_Unauthorized();
    }

    /**
     * @notice Performs most administrative tasks associated with a round closing
     */
    function _closeRound() internal {
        uint256 currentRound;
        uint256 mintShares;
        uint256[] memory totalFees;
        uint256[] memory perforamceFees;
        {
            currentRound = vaultState.round;

            FeeUtil.CloseParams memory params;
            params.currentShareSupply = share.totalSupply(address(this));
            params.queuedWithdrawShares = vaultState.queuedWithdrawShares;
            params.managementFee = managementFee;
            params.performanceFee = performanceFee;
            params.feeRecipient = feeRecipient;
            params.oracleAddr = oracle;
            params.collaterals = collaterals;
            params.roundStartingBalances = roundStartingBalances[currentRound];
            params.expiry = roundExpiry[currentRound];

            uint256[] memory collateralBalances;
            uint256 newPricePerShare;

            (collateralBalances, newPricePerShare, mintShares, totalFees, perforamceFees) = FeeUtil.closeRound(vaultState, params);

            uint256 nextRound = currentRound + 1;

            // Finalize the pricePerShare at the end of the round
            roundPricePerShare[currentRound] = newPricePerShare;

            // setting the balances at the start of the new round
            roundStartingBalances[nextRound] = collateralBalances;

            // including all pending deposits into vault
            vaultState.totalPending = 0;

            vaultState.round = uint32(nextRound);
        }

        // mints shares for all deposits, accounts can redeem at any time
        share.mint(address(this), address(this), mintShares);

        emit CollectedFees(totalFees, perforamceFees, currentRound, feeRecipient);
    }

    /**
     * @notice Completes withdraws from a past round
     * @dev transfers assets to pauser to exclude from vault balances
     */
    function _completeWithdraw() internal {
        uint256 withdrawShares = uint256(vaultState.queuedWithdrawShares);

        if (withdrawShares != 0) {
            vaultState.queuedWithdrawShares = 0;

            // total assets transfered to pauser
            uint256[] memory withdrawAmounts =
                VaultUtil.withdrawWithShares(pauser, withdrawShares, share.totalSupply(address(this)), collaterals);

            // recording deposits with pauser for past round
            IVaultPauser(pauser).processVaultWithdraw(withdrawAmounts);

            // burns shares that were transfered to vault during requestWithdraw
            share.burn(address(this), address(this), withdrawShares);

            emit Withdrew(msg.sender, withdrawAmounts, withdrawShares);
        }

        // Get remaining primary asset balance
        uint256 currentBalance = IERC20(collaterals[0].addr).balanceOf(address(this));

        _assertUint104(currentBalance);

        vaultState.lockedAmount = uint104(currentBalance);
    }

    /**
     * @notice Transfers assets between account holder and vault
     * @dev only called from depositFor and quickWithdraw
     */
    function _transferAssets(uint256 amount, address recipient, uint256 round) internal returns (uint256[] memory amounts) {
        return VaultUtil.transferAssets(amount, collaterals, roundStartingBalances[round], recipient);
    }

    /**
     * @notice gets whitelist status of an account
     * @param account address
     */
    function _validateWhitelisted(address account) internal view {
        if (whitelist != address(0) && !IWhitelist(whitelist).isCustomer(account)) revert HV_CustomerNotPermissioned();
    }

    /*///////////////////////////////////////////////////////////////
                                Getters
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Getter for returning the account's share balance split between account and vault holdings
     * @param account is the account to lookup share balance for
     * @return heldByAccount is the shares held by account
     * @return heldByVault is the shares held on the vault (unredeemedShares)
     */
    function shareBalances(address account) public view returns (uint256 heldByAccount, uint256 heldByVault) {
        Vault.DepositReceipt memory depositReceipt = depositReceipts[account];

        if (depositReceipt.round < Vault.PLACEHOLDER_UINT) {
            return (share.getBalanceOf(account, address(this)), 0);
        }

        heldByVault = FeeUtil.getSharesFromReceipt(
            depositReceipt,
            vaultState.round,
            roundPricePerShare[depositReceipt.round],
            _relativeNAVInRound(depositReceipt.round, depositReceipt.amount)
        );

        heldByAccount = share.getBalanceOf(account, address(this));
    }

    function currentOptions() external view returns (uint256[] memory) {
        return optionState.currentOptions;
    }

    function nextOptions() external view returns (uint256[] memory) {
        return optionState.nextOptions;
    }

    function getCollaterals() external view returns (Vault.Collateral[] memory) {
        return collaterals;
    }

    /*///////////////////////////////////////////////////////////////
                            Internal Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice helper function to calculate an account's Net Asset Value relative to the rounds startng balances
     */
    function _relativeNAVInRound(uint256 round, uint256 amount) internal view returns (uint256) {
        return FeeUtil.calculateRelativeNAV(oracle, collaterals, roundStartingBalances[round], amount, roundExpiry[round]);
    }

    function _assertUint104(uint256 num) internal pure {
        if (num > type(uint104).max) revert Overflow();
    }

    function _assertUint128(uint256 num) internal pure {
        if (num > type(uint128).max) revert Overflow();
    }
}