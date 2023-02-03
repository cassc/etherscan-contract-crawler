// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IToken.sol";
import "./interfaces/ITGE.sol";
import "./interfaces/IService.sol";
import "./interfaces/IPool.sol";
import "./libraries/ExceptionsLibrary.sol";

/// @title Token Generation Event
/// @dev A contract whose purpose is to distribute Governance and Preference tokens and ensure their blocking according to the settings. This contract has an active period, after which the sale of tokens stops, but additional rules related to this token - Lockup and Vesting - begin to apply.    Such a contract is considered successful if at least softcap tokens have been sold using it in the allotted time. Dependencies of TGE contracts on each other for one token - 1) before there is at least one successfully completed TGE, each subsequent created TGE is considered primary (including the very first for the token), 2) if there was at least one successful TGE for an existing token before the launch of a new TGE, then the created TGE is called secondary (and does not have a softcap, that is, any purchase makes it successful).

contract TGE is Initializable, ReentrancyGuardUpgradeable, ITGE {
    using AddressUpgradeable for address payable;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // CONSTANTS

    /// @notice Denominator for shares (such as thresholds)
    uint256 private constant DENOM = 100 * 10**4;

    /// @dev Pool's ERC20 token
    IToken public token;

    /// @dev TGE info struct
    TGEInfo public info;

    /// @dev Mapping of user's address to whitelist status
    mapping(address => bool) private _isUserWhitelisted;

    /// @dev Block of TGE's creation
    uint256 public createdAt;

    /// @dev Mapping of an address to total amount of tokens purchased during TGE
    mapping(address => uint256) public purchaseOf;

    /// @dev Total amount of tokens purchased during TGE
    uint256 public totalPurchased;

    /// @dev Is vesting TVL reached. Users can claim their tokens only if vesting TVL was reached.
    bool public vestingTVLReached;

    /// @dev Is lockup TVL reached. Users can claim their tokens only if lockup TVL was reached.
    bool public lockupTVLReached;

    /// @dev Mapping of addresses to total amounts of tokens vested
    mapping(address => uint256) public vestedBalanceOf;

    /// @dev Total amount of tokens vested
    uint256 public totalVested;

    /// @dev Protocol fee
    uint256 public protocolFee;

    /// @dev Protocol token fee is a percentage of tokens sold during TGE. Returns true if fee was claimed by the governing DAO.
    bool public isProtocolTokenFeeClaimed;

    // EVENTS

    /**
     * @dev Event emitted on token purchase.
     * @param buyer buyer
     * @param amount amount of tokens
     */
    event Purchased(address buyer, uint256 amount);

    /**
     * @dev Event emitted on claim of protocol token fee.
     * @param token token
     * @param tokenFee amount of tokens
     */
    event ProtocolTokenFeeClaimed(address token, uint256 tokenFee);

    /**
     * @dev Event emitted on token claim.
     * @param account Redeemer address
     * @param refundValue Refund value
     */
    event Redeemed(address account, uint256 refundValue);

    /**
     * @dev Event emitted on token claim.
     * @param account Claimer address
     * @param amount Amount of claimed tokens
     */
    event Claimed(address account, uint256 amount);

    /**
     * @dev Event emitted on transfer funds to pool.
     * @param amount Amount of transferred tokens/ETH
     */
    event FundsTransferred(uint256 amount);

    // INITIALIZER AND CONSTRUCTOR

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Constructor function, can only be called once. In this method, settings for the TGE event are assigned, such as the contract of the token implemented using TGE, as well as the TGEInfo structure, which includes the parameters of purchase, vesting and lockup. If no lockup or westing conditions were set for the TVL value when creating the TGE, then the TVL achievement flag is set to true from the very beginning.
     * @param _token pool's token
     * @param _info TGE parameters
     */
    function initialize(
        IToken _token,
        TGEInfo calldata _info,
        uint256 protocolFee_
    ) external initializer {
        __ReentrancyGuard_init();
        IService(msg.sender).validateTGEInfo(
            _info,
            _token.cap(),
            _token.totalSupply(),
            _token.tokenType()
        );

        token = _token;
        info = _info;
        protocolFee = protocolFee_;
        vestingTVLReached = (_info.vestingTVL == 0);
        lockupTVLReached = (_info.lockupTVL == 0);

        for (uint256 i = 0; i < _info.userWhitelist.length; i++) {
            _isUserWhitelisted[_info.userWhitelist[i]] = true;
        }

        createdAt = block.number;
    }

    // PUBLIC FUNCTIONS

    /**
     * @dev Purchase pool's tokens during TGE. The method for users from the TGE whitelist (set in TGEInfo when initializing the TGE contract), if the list is not set, then the sale is carried out for any address. The contract, when using this method, exchanges info.unitofaccount tokens available to buyers (if the address of the info.unitofaccount contract is set as zero, then the native ETH is considered unitofaccount) at the info.price rate of info.unitofaccount tokens for one pool token being sold. The buyer specifies the purchase amount in pool tokens, not in Unitofaccount. After receiving the user's funds by the contract, part of the tokens are minted to the buyer's balance, part of the tokens are minted to the address of the TGE contract in vesting. The percentage of vesting is specified in info.vestingPercent, if it is equal to 0, then all tokens are transferred to the buyer's balance.
     * @param amount amount of tokens in wei (10**18 = 1 token)
     */
    function purchase(uint256 amount)
        external
        payable
        onlyWhitelistedUser
        onlyState(State.Active)
        nonReentrant
        whenPoolNotPaused
    {
        // Check purchase price transfer depending on unit of account
        address unitOfAccount = info.unitOfAccount;
        uint256 purchasePrice = (amount * info.price + (1 ether - 1)) / 1 ether;
        if (unitOfAccount == address(0)) {
            require(
                msg.value >= purchasePrice,
                ExceptionsLibrary.INCORRECT_ETH_PASSED
            );
        } else {
            IERC20Upgradeable(unitOfAccount).safeTransferFrom(
                msg.sender,
                address(this),
                purchasePrice
            );
        }

        // Check purchase size
        require(
            amount >= info.minPurchase,
            ExceptionsLibrary.MIN_PURCHASE_UNDERFLOW
        );
        require(
            amount <= maxPurchaseOf(msg.sender),
            ExceptionsLibrary.MAX_PURCHASE_OVERFLOW
        );

        // Accrue TGE stats
        totalPurchased += amount;
        purchaseOf[msg.sender] += amount;

        // Mint tokens directly to user
        uint256 vestedAmount = (amount * info.vestingPercent + (DENOM - 1)) /
            DENOM;
        IToken _token = token;
        if (amount - vestedAmount > 0) {
            _token.mint(msg.sender, amount - vestedAmount);
        }

        // Mint tokens to vesting
        _token.mint(address(this), vestedAmount);
        vestedBalanceOf[msg.sender] += vestedAmount;
        totalVested += vestedAmount;

        // Emit event
        emit Purchased(msg.sender, amount);
    }

    /**
     * @dev Return purchased tokens and get back tokens paid. This method allows buyers of TGE who have not collected softcap and are considered failed to return the funds spent by handing back the purchased tokens. The refund of funds for tokens from vesting, blocked within this TGE, is made first of all. The buyer cannot hand over more tokens than he acquired during this TGE. The tokens returned to the contract are sent for burning.
     */
    function redeem()
        external
        onlyState(State.Failed)
        nonReentrant
        whenPoolNotPaused
    {
        // User can't claim more than he bought in this event (in case somebody else has transferred him tokens)
        require(
            purchaseOf[msg.sender] > 0,
            ExceptionsLibrary.ZERO_PURCHASE_AMOUNT
        );

        uint256 refundAmount = 0;

        // Calculate redeem from vesting
        uint256 vestedBalance = vestedBalanceOf[msg.sender];
        if (vestedBalance > 0) {
            vestedBalanceOf[msg.sender] = 0;
            purchaseOf[msg.sender] -= vestedBalance;
            totalVested -= vestedBalance;
            refundAmount += vestedBalance;
            token.burn(address(this), vestedBalance);
        }

        // Calculate redeemed balance
        uint256 balanceToRedeem = MathUpgradeable.min(
            token.balanceOf(msg.sender),
            purchaseOf[msg.sender]
        );
        if (balanceToRedeem > 0) {
            purchaseOf[msg.sender] -= balanceToRedeem;
            refundAmount += balanceToRedeem;
            token.burn(msg.sender, balanceToRedeem);
        }

        // Check that there is anything to refund
        require(refundAmount > 0, ExceptionsLibrary.NOTHING_TO_REDEEM);

        // Transfer refund value
        uint256 refundValue = (refundAmount * info.price + (1 ether - 1)) /
            1 ether;
        if (info.unitOfAccount == address(0)) {
            payable(msg.sender).sendValue(refundValue);
        } else {
            IERC20Upgradeable(info.unitOfAccount).safeTransfer(
                msg.sender,
                refundValue
            );
        }

        // Emit event
        emit Redeemed(msg.sender, refundValue);
    }

    /**
     * @dev The method allows you to return the tokens in the vesting from the TGE contract to the balance of the user's address, provided that the vesting within a specific TGE has been assigned, and the conditions necessary for its completion have been met. In TGE that ended in failure (softcap was not built), working with the method is impossible.
     */
    function claim() external whenPoolNotPaused {
        // Check that vested tokens can be claim
        require(claimAvailable(), ExceptionsLibrary.CLAIM_NOT_AVAILABLE);

        // Check that there is anything to claim
        uint256 amountToClaim = vestedBalanceOf[msg.sender];
        require(amountToClaim > 0, ExceptionsLibrary.NO_LOCKED_BALANCE);

        // Set vested amount to zero
        vestedBalanceOf[msg.sender] = 0;
        totalVested -= amountToClaim;

        // Transfer vested tokens
        IERC20Upgradeable(address(token)).safeTransfer(
            msg.sender,
            amountToClaim
        );

        // Emit event
        emit Claimed(msg.sender, amountToClaim);
    }

    /// @dev Set the flag that the condition for achieving the pool balance set in the westing settings is met. The action is irreversible.
    function setVestingTVLReached() external whenPoolNotPaused onlyManager {
        // Check that TVL has not been reached yet
        require(!vestingTVLReached, ExceptionsLibrary.VESTING_TVL_REACHED);

        // Mark as reached
        vestingTVLReached = true;
    }

    /// @dev Set the flag that the condition for achieving the pool balance of the value specified in the lockup settings is met. The action is irreversible.
    function setLockupTVLReached() external whenPoolNotPaused onlyManager {
        // Check that TVL has not been reached yet
        require(!lockupTVLReached, ExceptionsLibrary.LOCKUP_TVL_REACHED);

        // Mark as reached
        lockupTVLReached = true;
    }

    // RESTRICTED FUNCTIONS

    /**
     * @dev This method is used to perform the following actions for a successful TGE after its completion: transfer funds collected from buyers in the form of info.unitofaccount tokens or ETH to the address of the pool to which TGE belongs (if info.price is 0, then this action is not performed), as well as for Governance tokens make a minting of the percentage of the amount of all user purchases specified in the Service.sol protocolTokenFee contract and transfer it to the address specified in the Service.sol contract in the protocolTreasury() getter. Can be executed only once. Any address can call the method.
     */
    function transferFunds()
        external
        onlyState(State.Successful)
        whenPoolNotPaused
    {
        // Return if nothing to transfer
        if (totalPurchased == 0) {
            return;
        }

        // Claim protocol fee
        _claimProtocolTokenFee();

        // Transfer remaining funds to pool
        address unitOfAccount = info.unitOfAccount;
        address pool = token.pool();
        uint256 balance = 0;
        if (info.price != 0) {
            if (unitOfAccount == address(0)) {
                balance = address(this).balance;
                payable(pool).sendValue(balance);
            } else {
                balance = IERC20Upgradeable(unitOfAccount).balanceOf(
                    address(this)
                );
                IERC20Upgradeable(unitOfAccount).safeTransfer(pool, balance);
            }
        }

        // Emit event
        emit FundsTransferred(balance);
    }

    /// @dev Transfers protocol token fee in form of pool's governance tokens to protocol treasury
    function _claimProtocolTokenFee() private {
        // Return if already claimed
        if (isProtocolTokenFeeClaimed) {
            return;
        }

        // Retrun for preference token
        IToken _token = token;
        if (_token.tokenType() == IToken.TokenType.Preference) {
            return;
        }

        // Mark fee as claimed
        isProtocolTokenFeeClaimed = true;

        // Mint fee to treasury
        uint256 tokenFee = (totalPurchased * protocolFee + (DENOM - 1)) / DENOM;
        _token.mint(_token.service().protocolTreasury(), tokenFee);

        // Emit event
        emit ProtocolTokenFeeClaimed(address(_token), tokenFee);
    }

    // VIEW FUNCTIONS

    /**
     * @dev Shows the maximum possible number of tokens to be purchased by a specific address, taking into account whether the user is on the white list and 0 what amount of purchases he made within this TGE.
     * @return Amount of tokens
     */
    function maxPurchaseOf(address account) public view returns (uint256) {
        if (!isUserWhitelisted(account)) {
            return 0;
        }
        return
            MathUpgradeable.min(
                info.maxPurchase - purchaseOf[account],
                info.hardcap - totalPurchased
            );
    }

    /**
     * @dev The Getter allows you to find out the status of the current TGE. Usually, the status necessarily changes to 1 - "failure" or 2 - "success" at the end of the TGE validity period, depending on whether the softcap failed or was collected. However, if the buyers purchased 100% of the tokens offered for purchase, the status changes ahead of time to 2 - "success". The active TGE (which has not expired and has not collected hardcap) has the status 0. Changing the status from 0 to 1 or 2 is irreversible.
     * @return State
     */
    function state() public view returns (State) {
        // If hardcap is reached TGE is successfull
        if (totalPurchased == info.hardcap) {
            return State.Successful;
        }

        // If deadline not reached TGE is active
        if (block.number < createdAt + info.duration) {
            return State.Active;
        }

        // If it's not primary TGE it's successfull (if anything is purchased)
        if (address(this) != token.getTGEList()[0] && totalPurchased > 0) {
            return State.Successful;
        }

        // If softcap is reached TGE is successfull
        if (totalPurchased >= info.softcap && totalPurchased > 0) {
            return State.Successful;
        }

        // Otherwise it's failed primary TGE
        return State.Failed;
    }

    /**
     * @dev The given getter shows whether users have the opportunity to withdraw their tokens from vesting. To do this, a flag must be set that the TVL provided for unlocking tokens by vesting has been reached at least once by the pool, and also that the time allotted for blocking tokens within vesting has ended. For TGE without a lead program, this method always returns true.
     * @return Is claim available
     */
    function claimAvailable() public view returns (bool) {
        return
            vestingTVLReached &&
            block.number >= createdAt + info.vestingDuration &&
            (state()) != State.Failed;
    }

    /**
     * @dev The given getter shows whether the transfer method is available for tokens that were distributed using a specific TGE contract. If the lockup period is over or if the lockup was not provided for this TGE, the getter always returns true.
     * @return Is transfer available
     */
    function transferUnlocked() public view returns (bool) {
        return
            lockupTVLReached && block.number >= createdAt + info.lockupDuration;
    }

    /**
     * @dev Shows the number of TGE tokens blocked in this contract. If the lockup is completed or has not been assigned, the method returns 0 (all tokens on the address balance are available for transfer). If the lockup period is still active, then the difference between the tokens purchased by the user and those in the vesting is shown (both parameters are only for this TGE).
     * @param account Account address
     * @return Locked balance
     */
    function lockedBalanceOf(address account) external view returns (uint256) {
        return
            transferUnlocked()
                ? 0
                : (purchaseOf[account] - vestedBalanceOf[account]);
    }

    /**
     * @dev The given getter shows how much info.unitofaccount was collected within this TGE. To do this, the amount of tokens purchased by all buyers is multiplied by info.price.
     * @return Total value
     */
    function getTotalPurchasedValue() public view returns (uint256) {
        return (totalPurchased * info.price) / 10**18;
    }

    /**
     * @dev This getter shows the total value of all tokens that are in the vesting. Tokens that were transferred to user’s wallet addresses upon request for successful TGEs and that were burned as a result of user funds refund for unsuccessful TGEs are not taken into account.
     * @return Total value
     */
    function getTotalVestedValue() public view returns (uint256) {
        return (totalVested * info.price) / 10**18;
    }

    /**
     * @dev Get userwhitelist info
     * @return User whitelist
     */
    function getUserWhitelist() external view returns (address[] memory) {
        return info.userWhitelist;
    }

    /**
     * @dev Checks if user is whitelisted
     * @param account User address
     * @return Flag if user if whitelisted
     */
    function isUserWhitelisted(address account) public view returns (bool) {
        return info.userWhitelist.length == 0 || _isUserWhitelisted[account];
    }

    // MODIFIER

    modifier onlyState(State state_) {
        require(state() == state_, ExceptionsLibrary.WRONG_STATE);
        _;
    }

    modifier onlyWhitelistedUser() {
        require(
            isUserWhitelisted(msg.sender),
            ExceptionsLibrary.NOT_WHITELISTED
        );
        _;
    }

    modifier onlyManager() {
        IService service = token.service();
        require(
            service.hasRole(service.SERVICE_MANAGER_ROLE(), msg.sender),
            ExceptionsLibrary.NOT_WHITELISTED
        );
        _;
    }

    modifier whenPoolNotPaused() {
        require(
            !IPool(token.pool()).paused(),
            ExceptionsLibrary.SERVICE_PAUSED
        );
        _;
    }
}