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
contract TGE is
    Initializable,
    ReentrancyGuardUpgradeable,
    ITGE
{
    using AddressUpgradeable for address payable;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * @dev Pool's ERC20 token
     */
    IToken public token;

    /**
     * @dev TGE info struct
     */
    TGEInfo public info;

    /**
     * @dev Mapping of user's address to whitelist status
     */
    mapping(address => bool) public isUserWhitelisted;

    /**
     * @dev Block of TGE's creation
     */
    uint256 public createdAt;

    /**
     * @dev Mapping of an address to total amount of tokens purchased during TGE
     */
    mapping(address => uint256) public purchaseOf;

    /// @dev Is vesting TVL reached. Users can claim their tokens only if vesting TVL was reached.
    bool public vestingTVLReached;

    /// @dev Mapping of an address to total amount of tokens vesting
    mapping(address => uint256) public vestedBalanceOf;

    /// @dev Total amount of tokens purchased during TGE
    uint256 private _totalPurchased;

    /// @dev Total amount of tokens vesting
    uint256 private _totalVested;

    /// @dev Protocol token fee is a percentage of tokens sold during TGE. Returns true if fee was claimed by the governing DAO.
    bool public isProtocolTokenFeeClaimed;

    /// @dev Is lockup TVL reached. Users can claim their tokens only if lockup TVL was reached.
    bool public lockupTVLReached;

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

    // CONSTRUCTOR

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Constructor function, can only be called once
     * @param token_ pool's token
     * @param info_ TGE parameters
     */
    function initialize(
        IToken token_,
        TGEInfo calldata info_
    ) external initializer {
        token_.service().dispatcher().validateTGEInfo(
            info_, 
            token_.tokenType(), 
            token_.cap(), 
            token_.totalSupply()
        );

        token = token_;
        info = info_;
        vestingTVLReached = (info_.vestingTVL == 0);
        lockupTVLReached = (info_.lockupTVL == 0);

        for (uint256 i = 0; i < info.userWhitelist.length; i++) {
            isUserWhitelisted[info_.userWhitelist[i]] = true;
        }

        createdAt = block.number;
    }

    // PUBLIC FUNCTIONS

    /**
     * @dev Purchase pool's tokens during TGE
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
        address unitOfAccount = info.unitOfAccount;
        IToken _token = token;
        if (unitOfAccount == address(0)) {
            require(
                msg.value >= (amount * info.price) / 10**18,
                ExceptionsLibrary.INCORRECT_ETH_PASSED
            );
        } else {
            IERC20Upgradeable(unitOfAccount).safeTransferFrom(
                msg.sender,
                address(this),
                (amount * info.price) / 10**18
            );
        }

        require(
            amount >= info.minPurchase,
            ExceptionsLibrary.MIN_PURCHASE_UNDERFLOW
        );
        require(
            amount <= maxPurchaseOf(msg.sender),
            ExceptionsLibrary.MAX_PURCHASE_OVERFLOW
        );
        require(
            _totalPurchased + amount <= info.hardcap,
            ExceptionsLibrary.HARDCAP_OVERFLOW
        );

        _totalPurchased += amount;
        purchaseOf[msg.sender] += amount;
        uint256 vestedAmount = (amount * info.vestingPercent + 99) / 100;
        if (amount - vestedAmount > 0) {
            _token.mint(msg.sender, amount - vestedAmount);
        }
        _token.mint(address(this), vestedAmount);
        vestedBalanceOf[msg.sender] += vestedAmount;
        _totalVested += vestedAmount;

        emit Purchased(msg.sender, amount);
    }

    /**
     * @dev Return purchased tokens and get back tokens paid
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

        uint256 vesting = vestedBalanceOf[msg.sender];

        uint256 refundAmount = 0;

        if (vesting > 0) {
            vestedBalanceOf[msg.sender] = 0;
            purchaseOf[msg.sender] -= vesting;
            _totalVested -= vesting;
            refundAmount += vesting;
            token.burn(address(this), vesting);
        }

        uint256 balanceToRedeem = MathUpgradeable.min(
            token.minUnlockedBalanceOf(msg.sender),
            purchaseOf[msg.sender]
        );
        if (balanceToRedeem > 0) {
            purchaseOf[msg.sender] -= balanceToRedeem;
            refundAmount += balanceToRedeem;
            token.burn(msg.sender, balanceToRedeem);
        }

        require(refundAmount > 0, ExceptionsLibrary.NOTHING_TO_REDEEM);
        uint256 refundValue = (refundAmount * info.price) / 10**18;

        if (info.unitOfAccount == address(0)) {
            payable(msg.sender).sendValue(refundValue);
        } else {
            IERC20Upgradeable(info.unitOfAccount).safeTransfer(msg.sender, refundValue);
        }
    }

    /**
     * @dev Claim vested tokens
     */
    function claim() external whenPoolNotPaused {
        require(claimAvailable(), ExceptionsLibrary.CLAIM_NOT_AVAILABLE);
        require(
            vestedBalanceOf[msg.sender] > 0,
            ExceptionsLibrary.NO_LOCKED_BALANCE
        );

        uint256 balance = vestedBalanceOf[msg.sender];
        vestedBalanceOf[msg.sender] = 0;
        _totalVested -= balance;

        IERC20Upgradeable(address(token)).safeTransfer(msg.sender, balance);
    }

    function setVestingTVLReached() external whenPoolNotPaused onlyManager {
        require(!vestingTVLReached, ExceptionsLibrary.VESTING_TVL_REACHED);
        vestingTVLReached = true;
    }

    function setLockupTVLReached() external whenPoolNotPaused onlyManager {
        require(!lockupTVLReached, ExceptionsLibrary.LOCKUP_TVL_REACHED);
        lockupTVLReached = true;
    }

    // RESTRICTED FUNCTIONS

    /**
     * @dev Transfer proceeds from TGE to pool's treasury. Claim protocol fee.
     */
    function transferFunds()
        external
        onlyState(State.Successful)
        whenPoolNotPaused
    {
        claimProtocolTokenFee();

        address unitOfAccount = info.unitOfAccount;
        address pool = token.pool();

        if (info.price != 0) {
            if (unitOfAccount == address(0)) {
                payable(pool).sendValue(address(this).balance);
            } else {
                IERC20Upgradeable(unitOfAccount).safeTransfer(
                    pool,
                    IERC20Upgradeable(unitOfAccount).balanceOf(address(this))
                );
            }
        }
    }

    /// @dev Transfers protocol token fee in form of pool's governance tokens to protocol treasury
    function claimProtocolTokenFee() private {
        if (isProtocolTokenFeeClaimed) {
            return;
        }
        IToken _token = token;
        if (_token.tokenType() == IToken.TokenType.Preference) {
            return;
        }
        uint256 tokenFee = _token.service().getProtocolTokenFee(_totalPurchased);

        isProtocolTokenFeeClaimed = true;

        _token.mint(
            _token.service().protocolTreasury(),
            tokenFee
        );

        emit ProtocolTokenFeeClaimed(
            address(_token),
            tokenFee
        );
    }

    // VIEW FUNCTIONS

    /**
     * @dev How many tokens an address can purchase.
     * @return Amount of tokens
     */
    function maxPurchaseOf(address account)
        public
        view
        returns (uint256)
    {
        return MathUpgradeable.min(info.maxPurchase - purchaseOf[account], info.hardcap - _totalPurchased);
    }

    /**
     * @dev Returns TGE's state.
     * @return State
     */
    function state() public view returns (State) {
        if (_totalPurchased == info.hardcap) {
            return State.Successful;
        }
        if (block.number < createdAt + info.duration) {
            return State.Active;
        } else if (_totalPurchased >= info.softcap) {
            return State.Successful;
        } else {
            if (address(this) == token.getTGEList()[0])
                return State.Failed;
            else
                return State.Successful;
        }
    }

    /**
     * @dev Is claim available for vested tokens.
     * @return Is claim available
     */
    function claimAvailable() public view returns (bool) {
        return
            vestingTVLReached &&
            block.number >= createdAt + info.vestingDuration &&
            (state()) != State.Failed;
    }

    /**
     * @dev Is transfer available for lockup preference tokens.
     * @return Is transfer available
     */
    function transferUnlocked() public view returns (bool) {
        return
            lockupTVLReached &&
            block.number >= createdAt + info.lockupDuration;
    }

    /**
     * @dev Get total amount of tokens purchased during TGE.
     * @return Total amount of tokens.
     */
    function getTotalPurchased() public view returns (uint256) {
        return _totalPurchased;
    }

    /**
     * @dev Get total amount of tokens that are vesting.
     * @return Total vesting tokens.
     */
    function getTotalVested() public view returns (uint256) {
        return _totalVested;
    }

    /**
     * @dev Get total value of all purchased tokens
     * @return Total value
     */
    function getTotalPurchasedValue() public view returns (uint256) {
        return (_totalPurchased * info.price) / 10**18;
    }

    /**
     * @dev Get total value of all vesting tokens
     * @return Total value
     */
    function getTotalLockedValue() public view returns (uint256) {
        return (_totalVested * info.price) / 10**18;
    }

    /**
     * @dev Get userwhitelist info
     * @return User whitelist
     */
    function getUserWhitelist() external view returns (address[] memory) {
        return info.userWhitelist;
    }

    // function isUserWhitelisted(address user) public view returns (bool) {
    //     address[] memory users = info.userWhitelist;
    //     for (uint256 i = 0; i < users.length; i++) {
    //         if (user == users[i])
    //             return true;
    //     }
    //     return false;
    // }

    // MODIFIER

    modifier onlyState(State state_) {
        require(state() == state_, ExceptionsLibrary.WRONG_STATE);
        _;
    }

    modifier onlyWhitelistedUser() {
        require(
            info.userWhitelist.length == 0 || isUserWhitelisted[msg.sender],
            ExceptionsLibrary.NOT_WHITELISTED
        );
        _;
    }

    modifier onlyManager() {
        require(
            msg.sender == token.service().owner() ||
                token.service().isManagerWhitelisted(msg.sender),
            ExceptionsLibrary.NOT_WHITELISTED
        );
        _;
    }

    modifier whenPoolNotPaused() {
        require(!IPool(token.pool()).paused(), ExceptionsLibrary.SERVICE_PAUSED);
        _;
    }

    function test83212() external pure returns (uint256) {
        return 3;
    }
}