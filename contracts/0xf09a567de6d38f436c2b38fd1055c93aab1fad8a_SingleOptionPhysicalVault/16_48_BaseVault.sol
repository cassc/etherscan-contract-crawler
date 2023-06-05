// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {ERC1155TokenReceiver} from "solmate/tokens/ERC1155.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";

import {UUPSUpgradeable} from "openzeppelin/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "openzeppelin-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import {VaultLib} from "../../libraries/VaultLib.sol";
import {FeeLib} from "../../libraries/FeeLib.sol";

import {IPositionPauser} from "../../interfaces/IPositionPauser.sol";
import {IVaultShare} from "../../interfaces/IVaultShare.sol";
import {IWhitelistManager} from "../../interfaces/IWhitelistManager.sol";

import "../../config/constants.sol";
import "../../config/enums.sol";
import "../../config/errors.sol";
import "../../config/types.sol";

contract BaseVault is ERC1155TokenReceiver, OwnableUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable {
    using SafeERC20 for IERC20;

    /*///////////////////////////////////////////////////////////////
                        Non Upgradeable Storage
    //////////////////////////////////////////////////////////////*/

    // the erc1155 contract that issues vault shares
    IVaultShare public immutable share;

    /// @notice Stores the user's pending deposit for the round
    mapping(address => DepositReceipt) public depositReceipts;

    /// @notice On every round's close, the pricePerShare value of an hnVault token is stored
    /// This is used to determine the number of shares to be given to a user with
    /// their DepositReceipt.depositAmount
    mapping(uint256 => uint256) public roundPricePerShare;

    /// @notice deposit asset amounts; round => collateralBalances[]
    /// @dev    used in determining deposit ratios and NAV calculations
    ///         should not be used as a reference to collateral used in the round
    ///         because it does not account for assets that were queued for withdrawal
    mapping(uint256 => uint256[]) public roundStartingBalances;

    /// @notice deposit asset prices; round => CollateralPrices[]
    mapping(uint256 => uint256[]) public roundCollateralPrices;

    /// @notice expiry of each round
    mapping(uint256 => uint256) public roundExpiry;

    /// @notice Assets deposited into vault
    //          collaterals[0] is the primary asset, other assets are relative to the primary
    //          collaterals[0] is the premium / bidding token
    Collateral[] public collaterals;

    /// @notice Vault's round state
    VaultState public vaultState;

    /// @notice Vault's round configuration
    RoundConfig public roundConfig;

    // Oracle address to calculate Net Asset Value (for round share price)
    address public oracle;

    /// @notice Vault Pauser Contract for the vault
    address public pauser;

    /// @notice Whitelist contract, checks permissions and sanctions
    address public whitelist;

    /// @notice Fee recipient for the management and performance fees
    address public feeRecipient;

    /// @notice Role in charge of round operations
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

    event Redeem(address indexed account, uint256 share, uint256 round);

    event AddressSet(AddressType _type, address origAddress, address newAddress);

    event FeesSet(uint256 managementFee, uint256 newManagementFee, uint256 performanceFee, uint256 newPerformanceFee);

    event RoundConfigSet(
        uint32 duration, uint8 dayOfWeek, uint8 hourOfDay, uint32 newDuration, uint8 newDayOfWeek, uint8 newHourOfDay
    );

    event CollectedFees(uint256[] vaultFee, uint256 round, address indexed feeRecipient);

    /*///////////////////////////////////////////////////////////////
                        Constructor & Initializer
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the contract with immutable variables
     */
    constructor(address _share) {
        if (_share == address(0)) revert BadAddress();

        share = IVaultShare(_share);
    }

    /**
     * @notice Initializes the Vault contract with storage variables.
     * @param _initParams is the struct with vault initialization parameters
     */
    function __BaseVault_init(InitParams calldata _initParams) internal onlyInitializing {
        VaultLib.verifyInitializerParams(_initParams);

        _transferOwnership(_initParams._owner);
        __ReentrancyGuard_init_unchained();

        manager = _initParams._manager;

        oracle = _initParams._oracle;
        whitelist = _initParams._whitelist;
        feeRecipient = _initParams._feeRecipient;
        performanceFee = _initParams._performanceFee;
        managementFee = _initParams._managementFee;
        pauser = _initParams._pauser;
        roundConfig = _initParams._roundConfig;

        if (_initParams._collateralRatios.length > 0) {
            // set the initial ratios on the first round
            roundStartingBalances[1] = _initParams._collateralRatios;
            // set init price per share and expiry to placeholder values (1)
            roundPricePerShare[1] = PLACEHOLDER_UINT;
            roundExpiry[1] = PLACEHOLDER_UINT;
        }

        for (uint256 i; i < _initParams._collaterals.length;) {
            collaterals.push(_initParams._collaterals[i]);

            unchecked {
                ++i;
            }
        }

        vaultState.round = 1;
    }

    /*///////////////////////////////////////////////////////////////
                    Override Upgrade Permission
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Upgradable by the owner.
     *
     */
    function _authorizeUpgrade(address /*newImplementation*/ ) internal view override {
        _onlyOwner();
    }

    /*///////////////////////////////////////////////////////////////
                    State changing functions to override
    //////////////////////////////////////////////////////////////*/
    function _beforeCloseRound() internal virtual {}
    function _afterCloseRound() internal virtual {}

    /*///////////////////////////////////////////////////////////////
                            Setters
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets addresses for different settings
     * @param _type of address:
     *              0 - Manager
     *              1 - FeeRecipient
     *              2 - Pauser
     *              3 - Whitelist
     * @param _address is the new address
     */
    function setAddresses(AddressType _type, address _address) external {
        _onlyOwner();

        if (_address == address(0)) revert BadAddress();

        if (AddressType.Manager == _type) {
            emit AddressSet(AddressType.Manager, manager, _address);
            manager = _address;
        } else if (AddressType.FeeRecipient == _type) {
            emit AddressSet(AddressType.FeeRecipient, feeRecipient, _address);
            feeRecipient = _address;
        } else if (AddressType.Pauser == _type) {
            emit AddressSet(AddressType.Pauser, pauser, _address);
            pauser = _address;
        } else if (AddressType.Whitelist == _type) {
            emit AddressSet(AddressType.Whitelist, whitelist, _address);
            whitelist = _address;
        }
    }

    /**
     * @notice Sets fees for the vault
     * @param _managementFee is the management fee (18 decimals). ex: 2 * 10 ** 18 = 2%
     * @param _performanceFee is the performance fee (18 decimals). ex: 20 * 10 ** 18 = 20%
     */
    function setFees(uint256 _managementFee, uint256 _performanceFee) external {
        _onlyOwner();

        if (_managementFee > 100 * PERCENT_MULTIPLIER) revert BV_BadFee();
        if (_performanceFee > 100 * PERCENT_MULTIPLIER) revert BV_BadFee();

        emit FeesSet(managementFee, _managementFee, performanceFee, _performanceFee);

        managementFee = _managementFee;
        performanceFee = _performanceFee;
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

        if (_duration == 0 || _dayOfWeek > 8 || _hourOfDay > 23) revert BV_BadRoundConfig();

        emit RoundConfigSet(roundConfig.duration, roundConfig.dayOfWeek, roundConfig.hourOfDay, _duration, _dayOfWeek, _hourOfDay);

        roundConfig = RoundConfig(_duration, _dayOfWeek, _hourOfDay);
    }

    /*///////////////////////////////////////////////////////////////
                            Deposit & Withdraws
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deposits the `asset` from msg.sender added to `creditor`'s deposit
     * @param _amount is the amount of primary asset to deposit
     * @param _creditor is the address that can claim/withdraw deposited amount
     */
    function depositFor(uint256 _amount, address _creditor) external nonReentrant {
        if (_creditor == address(0)) _creditor = msg.sender;

        uint256 currentRound = _depositFor(_amount, _creditor);

        // pulling all collaterals from msg.sender
        // An approve() by the msg.sender is required for all collaterals beforehand
        uint256[] memory amounts = _transferAssets(_amount, address(this), currentRound);

        emit Deposited(_creditor, amounts, currentRound);
    }

    /**
     * @notice Withdraws the assets of the vault using the outstanding `DepositReceipt.amount`
     * @dev only pending funds can be withdrawn using this method
     * @param _amount is the pending amount of primary asset to be withdrawn
     */
    function quickWithdraw(uint256 _amount) external nonReentrant {
        if (_amount == 0) revert BV_BadAmount();

        _validateWhitelisted(msg.sender);

        DepositReceipt storage depositReceipt = depositReceipts[msg.sender];

        uint256 currentRound = vaultState.round;

        if (depositReceipt.round != currentRound) revert BV_BadRound();

        uint96 receiptAmount = depositReceipt.amount;

        if (receiptAmount < _amount) revert BV_BadAmount();

        // amount is within uin96 based on above less-than check
        depositReceipt.amount = receiptAmount - uint96(_amount);

        // amount is within uin96 because it was added to totalPending in _depositFor
        vaultState.totalPending -= uint96(_amount);

        // array of asset amounts transferred back from account
        uint256[] memory amounts = _transferAssets(_amount, msg.sender, currentRound);

        emit QuickWithdrew(msg.sender, amounts, currentRound);
    }

    /**
     * @notice requests a withdraw that can be processed once the round closes
     * @param _numShares is the number of shares to withdraw
     */
    function requestWithdraw(uint256 _numShares) external virtual {
        _requestWithdraw(_numShares);
    }

    /**
     * @notice Redeems shares that are owed to the account
     * @param _depositor is the address of the depositor
     * @param _numShares is the number of shares to redeem, could be 0 when isMax=true
     * @param _isMax is flag for when callers do a max redemption
     */
    function redeemFor(address _depositor, uint256 _numShares, bool _isMax) external virtual {
        if (_depositor != msg.sender) revert Unauthorized();

        _redeem(_depositor, _numShares, _isMax);
    }

    /*///////////////////////////////////////////////////////////////
                            Vault Operations
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Performs most administrative tasks associated with a round closing
     */
    function closeRound() external nonReentrant {
        _onlyManager();

        _beforeCloseRound();

        uint32 currentRound = vaultState.round;
        uint256 currentExpiry = roundExpiry[currentRound];
        bool expirationExceeded = currentExpiry < block.timestamp;
        uint256[] memory balances = _getCurrentBalances();

        // only take fees after expiration exceeded, returns balances san fees
        if (expirationExceeded && currentRound > 1) balances = _processFees(balances, currentRound);

        // sets new pricePerShare, shares to mint, and asset prices for new funds being added
        _rollInFunds(balances, currentRound, currentExpiry);

        uint32 nextRound = currentRound + 1;

        // setting the balances at the start of the new round
        roundStartingBalances[nextRound] = balances;

        // including all pending deposits into vault
        vaultState.lastLockedAmount = vaultState.lockedAmount;
        vaultState.totalPending = 0;
        vaultState.round = nextRound;

        uint256 lockedAmount = balances[0];

        // only withdraw, otherwise
        if (expirationExceeded && currentRound > 1) lockedAmount -= _completeWithdraw();

        vaultState.lockedAmount = _toUint96(lockedAmount);

        _afterCloseRound();
    }

    /**
     * @notice Helper function to save gas for writing values into storage maps.
     *         Writing 1's into maps makes subsequent writes warm, reducing the gas significantly.
     * @param _numRounds is the number of rounds to initialize in the maps
     * @param _startFromRound is the round number from which to start initializing the maps
     */
    function initRounds(uint256 _numRounds, uint32 _startFromRound) external {
        unchecked {
            uint256 i;
            uint256[] memory placeholderArray = new uint256[](collaterals.length);

            for (i; i < collaterals.length; ++i) {
                placeholderArray[i] = PLACEHOLDER_UINT;
            }

            for (i = 0; i < _numRounds; ++i) {
                uint256 index = _startFromRound;

                index += i;

                if (roundPricePerShare[index] > 0) revert BV_BadPPS();
                if (roundExpiry[index] > 0) revert BV_BadExpiry();
                if (roundStartingBalances[index].length > 0) revert BV_BadSB();
                if (roundCollateralPrices[index].length > 0) revert BV_BadCP();

                roundPricePerShare[index] = PLACEHOLDER_UINT;
                roundExpiry[index] = PLACEHOLDER_UINT;

                roundStartingBalances[index] = placeholderArray;
                roundCollateralPrices[index] = placeholderArray;
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                                Getters
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Getter for returning the account's share balance split between account and vault holdings
     * @param _account is the account to lookup share balance for
     * @return heldByAccount is the shares held by account
     * @return heldByVault is the shares held on the vault (unredeemedShares)
     */
    function shareBalances(address _account) external view returns (uint256 heldByAccount, uint256 heldByVault) {
        DepositReceipt memory depositReceipt = depositReceipts[_account];

        if (depositReceipt.round < PLACEHOLDER_UINT) {
            return (share.getBalanceOf(_account, address(this)), 0);
        }

        heldByVault = FeeLib.getSharesFromReceipt(
            depositReceipt,
            vaultState.round,
            roundPricePerShare[depositReceipt.round],
            _relativeNAVInRound(depositReceipt.round, depositReceipt.amount)
        );

        heldByAccount = share.getBalanceOf(_account, address(this));
    }

    function getCollaterals() external view returns (Collateral[] memory) {
        return collaterals;
    }

    /*///////////////////////////////////////////////////////////////
                            Internal Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deposits the `asset` from msg.sender added to `creditor`'s deposit
     * @param _amount is the amount of primary asset to deposit
     * @param _creditor is the address that can claim/withdraw deposited amount
     */
    function _depositFor(uint256 _amount, address _creditor) internal virtual returns (uint256 currentRound) {
        if (_amount == 0) revert BV_BadDepositAmount();

        _validateWhitelisted(msg.sender);

        if (_creditor != msg.sender) _validateWhitelisted(_creditor);

        currentRound = vaultState.round;

        uint256 depositAmount = _amount;

        DepositReceipt memory depositReceipt = depositReceipts[_creditor];
        uint256 unredeemedShares = depositReceipt.unredeemedShares;

        if (currentRound > depositReceipt.round) {
            // if we have an unprocessed pending deposit from the previous rounds, we first process it.
            if (depositReceipt.amount > 0) {
                unredeemedShares = FeeLib.getSharesFromReceipt(
                    depositReceipt,
                    currentRound,
                    roundPricePerShare[depositReceipt.round],
                    _relativeNAVInRound(depositReceipt.round, depositReceipt.amount)
                );
            }
        } else {
            // if we have a pending deposit in the current round, we add on to the pending deposit
            depositAmount += depositReceipt.amount;
        }

        depositReceipts[_creditor] = DepositReceipt({
            round: uint32(currentRound),
            amount: _toUint96(depositAmount),
            unredeemedShares: _toUint128(unredeemedShares)
        });

        // keeping track of total pending primary asset
        vaultState.totalPending += _toUint96(_amount);
    }

    /**
     * @notice Redeems shares that are owed to the account
     * @param _depositor receipts
     * @param _numShares is the number of shares to redeem, could be 0 when isMax=true
     * @param _isMax is flag for when callers do a max redemption
     */
    function _redeem(address _depositor, uint256 _numShares, bool _isMax) internal nonReentrant {
        if (!_isMax && _numShares == 0) revert BV_BadNumShares();

        uint256 currentRound = vaultState.round;

        DepositReceipt storage depositReceipt = depositReceipts[_depositor];

        uint256 depositInRound = depositReceipt.round;
        uint256 unredeemedShares = depositReceipt.unredeemedShares;

        if (currentRound > depositInRound) {
            unredeemedShares = FeeLib.getSharesFromReceipt(
                depositReceipt,
                currentRound,
                roundPricePerShare[depositInRound],
                _relativeNAVInRound(depositInRound, depositReceipt.amount)
            );
        }

        if (_isMax) _numShares = unredeemedShares;

        if (_numShares == 0) return;

        if (unredeemedShares < _numShares) revert BV_ExceedsAvailable();

        // if we have a depositReceipt on the same round, BUT we have unredeemed shares
        // we debit from the unredeemedShares, leaving the amount field intact
        depositReceipt.unredeemedShares = _toUint128(unredeemedShares - _numShares);

        // if the round has past we zero amount for new deposits.
        if (depositInRound < currentRound) depositReceipt.amount = 0;

        emit Redeem(_depositor, _numShares, depositInRound);

        // account shares minted at closeRound to vault, we transfer to account from vault
        share.transferVaultOnly(address(this), _depositor, _numShares, "");
    }

    function _requestWithdraw(uint256 _numShares) internal {
        if (_numShares == 0) revert BV_BadNumShares();

        DepositReceipt memory depositReceipt = depositReceipts[msg.sender];

        // if unredeemed shares exist, do a max redeem before initiating a withdraw
        if (depositReceipt.amount > 0 || depositReceipt.unredeemedShares > 0) _redeem(msg.sender, 0, true);

        // keeping track of total shares requested to withdraw at the end of round
        vaultState.queuedWithdrawShares += _toUint128(_numShares);

        // transferring vault tokens (shares) back to vault, to be burned when round closes
        share.transferVaultOnly(msg.sender, address(this), _numShares, "");

        // storing shares in pauser for future asset(s) withdraw
        IPositionPauser(pauser).pausePosition(msg.sender, _numShares);

        emit RequestedWithdraw(msg.sender, _numShares, vaultState.round);
    }

    function _processFees(uint256[] memory _balances, uint256 _currentRound)
        internal
        virtual
        returns (uint256[] memory balances)
    {
        uint256[] memory totalFees;

        VaultDetails memory vaultDetails =
            VaultDetails(collaterals, roundStartingBalances[_currentRound], _balances, vaultState.totalPending);

        (totalFees, balances) = FeeLib.processFees(vaultDetails, managementFee, performanceFee);

        for (uint256 i; i < totalFees.length;) {
            if (totalFees[i] > 0) {
                IERC20(collaterals[i].addr).safeTransfer(feeRecipient, totalFees[i]);
            }

            unchecked {
                ++i;
            }
        }

        emit CollectedFees(totalFees, _currentRound, feeRecipient);
    }

    function _rollInFunds(uint256[] memory _balances, uint256 _currentRound, uint256 _expiry) internal virtual {
        NAVDetails memory navDetails =
            NAVDetails(collaterals, roundStartingBalances[_currentRound], _balances, oracle, _expiry, vaultState.totalPending);

        (uint256 totalNAV, uint256 pendingNAV, uint256[] memory prices) = FeeLib.calculateNAVs(navDetails);

        uint256 pricePerShare = FeeLib.pricePerShare(share.totalSupply(address(this)), totalNAV, pendingNAV);

        uint256 mintShares = FeeLib.navToShares(pendingNAV, pricePerShare);

        // mints shares for all deposits, accounts can redeem at any time
        share.mint(address(this), mintShares);

        // Finalize the pricePerShare at the end of the round
        roundPricePerShare[_currentRound] = pricePerShare;

        // Prices at expiry, if before expiry then spot
        roundCollateralPrices[_currentRound] = prices;
    }

    /**
     * @notice Completes withdraws from a past round
     * @dev transfers assets to pauser to exclude from vault balances
     */
    function _completeWithdraw() internal virtual returns (uint256) {
        uint256 withdrawShares = uint256(vaultState.queuedWithdrawShares);

        uint256[] memory withdrawAmounts = new uint256[](1);

        if (withdrawShares != 0) {
            vaultState.queuedWithdrawShares = 0;

            // total assets transferred to pauser
            withdrawAmounts = VaultLib.withdrawWithShares(collaterals, share.totalSupply(address(this)), withdrawShares, pauser);
            // recording deposits with pauser for past round
            IPositionPauser(pauser).processVaultWithdraw(withdrawAmounts);

            // burns shares that were transferred to vault during requestWithdraw
            share.burn(address(this), withdrawShares);

            emit Withdrew(msg.sender, withdrawAmounts, withdrawShares);
        }

        return withdrawAmounts[0];
    }

    /**
     * @notice Queries total balance(s) of collateral
     * @dev used in processFees
     */
    function _getCurrentBalances() internal view virtual returns (uint256[] memory balances) {
        balances = new uint256[](collaterals.length);

        for (uint256 i; i < collaterals.length;) {
            balances[i] = IERC20(collaterals[i].addr).balanceOf(address(this));

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Transfers assets between account holder and vault
     * @dev only called from depositFor and quickWithdraw
     */
    function _transferAssets(uint256 _amount, address _recipient, uint256 _round) internal returns (uint256[] memory) {
        return VaultLib.transferAssets(_amount, collaterals, roundStartingBalances[_round], _recipient);
    }

    /**
     * @notice gets whitelist status of an account
     * @param _account address
     */
    function _validateWhitelisted(address _account) internal view {
        if (whitelist != address(0) && !IWhitelistManager(whitelist).isCustomer(_account)) revert Unauthorized();
    }

    /**
     * @notice helper function to calculate an account's Net Asset Value relative to the rounds starting balances
     */
    function _relativeNAVInRound(uint256 _round, uint256 _amount) internal view returns (uint256) {
        return FeeLib.calculateRelativeNAV(collaterals, roundStartingBalances[_round], roundCollateralPrices[_round], _amount);
    }

    function _onlyManager() internal view {
        if (msg.sender != manager) revert Unauthorized();
    }

    function _onlyOwner() internal view {
        if (msg.sender != owner()) revert Unauthorized();
    }

    function _onlyPauser() internal view {
        if (msg.sender != pauser) revert Unauthorized();
    }

    function _toUint96(uint256 _num) internal pure returns (uint96) {
        if (_num > type(uint96).max) revert Overflow();
        return uint96(_num);
    }

    function _toUint128(uint256 _num) internal pure returns (uint128) {
        if (_num > type(uint128).max) revert Overflow();
        return uint128(_num);
    }
}