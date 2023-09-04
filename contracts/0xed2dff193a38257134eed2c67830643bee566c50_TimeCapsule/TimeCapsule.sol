/**
 *Submitted for verification at Etherscan.io on 2023-07-04
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}
/**
 * @dev copied and condensed from @openzeppelin/contracts/proxy/utils/Initializable.sol
 **/

abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            /* changed from: (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            to: */(isTopLevelCall && _initialized < 1) || ((address(this).code.length == 0) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     * @dev added by TPM
     */
    function isInitialized() public view returns (bool) {
        return _initialized == 1;
    }
}
library Strings {
    
    function toString(uint256 value) internal pure returns (string memory) {
        // from @openzeppelin String.sol
        unchecked {
            ////
            // uint256 length = Math.log10(value) + 1; =>
            // from @openzeppelin Math.sol
            uint256 length = 0;
            if (value >= 10**64) { value /= 10**64; length += 64; }
            if (value >= 10**32) { value /= 10**32; length += 32; }
            if (value >= 10**16) { value /= 10**16; length += 16; }
            if (value >= 10**8) { value /= 10**8; length += 8; }
            if (value >= 10**4) { value /= 10**4; length += 4; }
            if (value >= 10**2) { value /= 10**2; length += 2; }
            if (value >= 10**1) { length += 1; }
            length++;
            ////

            string memory buffer = new string(length);
            uint256 ptr;
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), "0123456789abcdef"))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }
}
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface ITimeCapsuleFactory {

    struct OwnerCapsuleRecord {
        address capsuleAddress;
        bytes32 recoveryAddressHash;
        bool validated;
    }

    function predictedCapsuleAddress(address ownerAddress) external view returns (address predictedAddress);

    function createTimeCapsule() external;

    function createTimeCapsule(bytes32 _recoveryAddressHash) external;

    function capsuleAddressOf(address _owner) external view returns (address capsuleAddress);

    function validateRecoveryAddressHash(
        address _owner,
        bytes32 _recoveryAddressHash,
        bytes memory _signature
    ) external;

    function checkRecoveryAddress(address _owner, bytes32 _addressHash) external view returns (bool confirmed);

    function isRecoveryHashValidated(address _owner) external view returns (bool);

    function getRecoveryRecord(address _owner) external view  returns (OwnerCapsuleRecord memory);

    function recoverOwnership( address _oldOwner, address _newOwner ) external;

}
/// @dev SYNONYMS: vault, capsule, timecapsule

/// @dev _feeSplitter (feeSplitter.sol) is our own, trusted contract (context: reentrance attacks)
interface IFeeSplitter {
    function splitERC20(address tokenAddress) external returns (bool);
}

/**
 * @dev A place for TimeCapsule Constants to live
 */
abstract contract TimeCapsuleContext is Initializable {
    uint256         constant    internal    FEE_DIVISOR = 1000; // 0.1%
    uint64          constant    internal    ONE_HOUR =  60 * 60;
    uint64          constant    internal    ONE_DAY =  24 * 60 * 60;
    uint64          constant    internal    SEVEN_DAYS = 7 * ONE_DAY;
    uint64          constant    internal    ONE_YEAR = 365 * ONE_DAY;
    uint64          constant    internal    MAX_LOCK_SECONDS = 20089 * ONE_DAY; // ~55 years (365.25 days each)
    uint64          constant    internal    TIMELOCK_SECONDS = SEVEN_DAYS;
    uint64          constant    internal    BEHAVIORLOCK_SECONDS = ONE_YEAR;
    address         constant    internal    NATIVE_COIN = address(0);
    address         constant    internal    INVALID_SIGNER_ADDRESS = address(0);
    string          constant    internal    VAULT_RECOVERY_AUTHORIZATION="VAULT RECOVERY AUTHORIZATION";
    string          constant    internal    CONFIRMING_RECOVERY_ADDRESS="CONFIRMING RECOVERY ADDRESS";

    enum VaultStatus {
        NOMINAL,    // all is well
        PANIC,      // 'panic switch' activated (lockout for recovery)
        RECOVERED   // (read-only)
    }

    enum LockState {
        INERT,
        WITHDRAWAL_PENDING
    }

    enum LockType {
        DRIP,
        HARD,
        BEHAVIORAL
    }

    struct Lock {
        LockState state;            // uint8
        bytes32 tag;                // <= 31 character descriptor string
        uint64 lockTime;            // UTC
        uint64 unlockTime;          // UTC
        uint64 releaseTime;         // UTC timestamp when time-locked funds release for sending
        LockType lockType;          // uint8
        bytes6 unlockHash;          // first 6 bytes of keccak256 hash
        // 256 bit boundary
        uint256 lockedAmount;       // in ERC20 token's base units
        uint256 withdrawnToDate;    // in ERC20 token's base units
        uint256 timelockedAmount;   // amount of any pending, time-locked withdrawal
    }
}

/**
 * @title TimeCapsule
 */
contract TimeCapsule is TimeCapsuleContext{

    address public owner;
    ITimeCapsuleFactory private _capsuleFactory;

    mapping(address => Lock[])  private _locks; // address is 'rc20 token contract address or address(0)
    mapping(address => uint256) private _totalLockedAmount;

    uint64 private _deadmanTime;

    VaultStatus private _vaultStatus;

    IFeeSplitter private _feeSplitter;

    constructor() {
        // Contructor not used by factory. We use it here only to prevent master copy hijacks
        // the factory will call this.initialize() for one-off setup tasks.
        _disableInitializers();
    }

    /**
     * @dev Because this contract is a proxied clone (oppenzep'Clone.sol)
     *      functions herein get called **twice**. The first call has `msg.sender`
     *      set as the address of the caller, as usual. The second _proxy_ call
     *      has `msg.sender` set to this contract's own address. Hence, we roll
     *      our own 'Ownable' (minus transferability) and with a different name
     *      than 'onlyOwner' to avoid confusion.
     */
    modifier _onlyCapsuleOwner() {
        if (address(this) != msg.sender) {
            require(owner == msg.sender, "Not owner");
            _;
        }
    }

    /**
     * @dev This modifier blocks calls to functions when the vault is in the 'panic' state.
     */
    modifier _notPanicState() {
        if (address(this) != msg.sender) {
            require(_vaultStatus != VaultStatus.PANIC, "Forbidden");
            _;
        }
    }

    /**
     * Called once by factory directly after cloning to initialize vault.
     * @param _newOwner the vaults's owner address
     * @param _factoryAddress used to manage recovery from panic state aka "undo a hack"
     * @param _feeSplitterContract the [contract] address to send fees
     */
    function initialize(
        address _newOwner,
        address _factoryAddress,
        IFeeSplitter _feeSplitterContract
    )
        initializer
        public
    {
        owner = _newOwner;
        _capsuleFactory = ITimeCapsuleFactory(_factoryAddress);
        _deadmanTime = (uint64)(block.timestamp);
        _vaultStatus = VaultStatus.NOMINAL;
        _feeSplitter = _feeSplitterContract;
    }

    /**
     * When native coin is sent directly to this vault (as if it were a standard wallet)
     * the funds are auto-locked for seven days (and the fee is paid accordingly.) This is
     * intended as a safety feature and not to be advertized as good practice.
     */
    receive() external payable { }

    event Locked(
        bytes32 tag,
        address tokenAddress,
        uint256 lockIndex,
        uint256 amount,
        uint256 fee,
        uint256 lockTime,
        uint256 unlockTime,
        LockType lockType
    );

    event WithdrawalInitiated(
        address tokenAddress,
        uint256 lockIndex,
        uint256 amount
    );

    event WithdrawalCancelled(
        address tokenAddress,
        uint256 lockIndex
    );

    event Withdrawal(
        address tokenAddress,
        uint256 lockIndex,
        uint256 amount
    );

    event LockReleased(
        address tokenAddress,
        uint256 lockIndex
    );

    event RecoveryInitiated();

    event Recovered();

    error HardLocked(
        uint64 unlockTime
    );

    error InsufficientFunds(
        uint256 grossBalance,
        uint256 alreadyLocked,
        uint256 availableToLock
    );

    /**
     * Transfers nativer coin from the vault to a recipient.
     * @notice Do not use simple trasfer(<maxgas: 2300!>) — Gnosis safe (for example) infamously incompatible
     * @param _to recipient address
     * @param _value base unit amount to transfer
     */
    function _transferNative(
        address _to,
        uint256 _value
    )
        internal
        returns (bool success)
    {
        (success, ) = _to.call{ value: _value }("");
    }

    /**
     * Transfers 'RC20 tokens from the vault to a recipient.
     * @notice internal function
     * @param _tokenAddress 'RC20 token contract address
     * @param _to recipient address
     * @param _value base unit amount to transfer
     * @return bool
     */
    function _transferToken(
        address _tokenAddress,
        address _to,
        uint256 _value
    )
        internal
        returns (bool)
    {
        return IERC20(_tokenAddress).transfer(
            _to,
            _value
        );
    }

    /**
     * Returns the current "state" of the vault. See `enum VaultStatus {...}`
     * @return status enum VaultStatus.<NOMINAL|PANIC|RECOVERED>
     */
    function vaultStatus()
        public
        view
        returns (VaultStatus status)
    {
        status = _vaultStatus;
    }

    /**
     * Validates recovery address. Validation is required as a separate step to account for possibily
     * of mistake or bad actor using the same recovery address as an attempt to 'block' geniune use.
     * @param _recoveryAddressHash keccak256 (sha3) hash of recovery address (so as not to 'dox' the address)
     * @param _signature personal_sign of the string: "CONFIRMING RECOVERY ADDRESS"
     */
    function validateRecoveryAddressHash(
        bytes32 _recoveryAddressHash,
        bytes memory _signature
    )
        public
        _onlyCapsuleOwner
        _notPanicState
    {
        _capsuleFactory.validateRecoveryAddressHash(
            owner,
            _recoveryAddressHash,
            _signature
        );
    }

    /**
     * Used to test if a given recovery address hash is valid for (matches) the hash stored for this vault.
     * @param _recoveryAddressHash keccak256 hash of the recovery address / public key
     * @return confirmed bool
     */
    function checkRecoveryAddress(bytes32 _recoveryAddressHash)
        public
        view
        returns (bool confirmed)
    {
        confirmed = _capsuleFactory.checkRecoveryAddress(owner, _recoveryAddressHash);
    }

    /**
     * Returns true if tha vault's recovery address hash has been validated — see validateRecoveryAddressHash(...).
     * @return validated bool
     */
    function isRecoveryHashValidated()
        public view
        returns (bool validated)
    {
        return _capsuleFactory.isRecoveryHashValidated(owner);
    }

    /**
     * Returns the number of active locks for a given token contract address (or address(0) for
     * native coin.) Used in conjunction with lockData() to retrieve list of locks for a spcific token.
     * @param _tokenAddress 'RC2- contract address
     * @return count number of active locks for the specified token
     */
    function lockCount(address _tokenAddress)
        public
        view
        returns (uint256 count)
    {
        count = _locks[_tokenAddress].length;
    }

    /**
     * Returns Lock record for an existing lock.
     * @param _tokenAddress 'RC20 token contract address
     * @param _index lock index
     * @return lock Lock record
     */
    function lockData(
        address _tokenAddress,
        uint256 _index
    )
        public
        view
        returns (Lock memory lock)
    {
        Lock[] memory locks = _locks[_tokenAddress];
        require(locks.length > 0,
            "No locks for given token address"
        );
        require(locks.length > _index,
            "Invalid lock index"
        );

        lock = locks[_index];
    }

    /**
     * Returns available/lockable balance (owned by this vault and not tied up in locks)
     * @param _tokenAddress token contract address or address(0) for native coin
     */
    function availableBalance(
        address _tokenAddress   // use address(0) for native coin
    )
        public
        view
        returns (uint256 available)
    {
        available = 0;
        uint256 _grossBalance;
        if (_tokenAddress == NATIVE_COIN) {
            _grossBalance = address(this).balance;
        } else {
            require(
                _tokenAddress.code.length > 0,
                "not a token"
            );
            _grossBalance = IERC20(_tokenAddress).balanceOf(address(this));
        }
        if (_grossBalance > _totalLockedAmount[_tokenAddress]) {
            available = _grossBalance - _totalLockedAmount[_tokenAddress];
        }
    }

    /**
     * @notice internal function
     * @param _tag bytes32String: up to 31 characters of user input as a label for the lock
     * @param _tokenAddress token contract address or address(0) for native coin
     * @param _lockAmount unit value of amount to be locked
     * @param _lockTime UTC unix timestamp (seconds)
     * @param _unlockTime UTC unix timestamp (seconds)
     * @param _lockType enum LockType.<DRIP|HARD|BEHAVIORAL>
     * @return lockIndex array index of created lock
     */
    function _storeNewLock(
        bytes32 _tag,
        address _tokenAddress,
        uint256 _lockAmount,
        uint64 _lockTime,
        uint64 _unlockTime,
        LockType _lockType
    )
        internal
        returns (uint256 lockIndex)
    {
        Lock[] storage locksRef = _locks[_tokenAddress];
        Lock memory lock = Lock({
            state: LockState.INERT,
            tag: _tag,
            lockTime: _lockTime,
            unlockTime: _unlockTime,
            lockType: _lockType,
            unlockHash: 0,
            lockedAmount: _lockAmount,
            withdrawnToDate: 0,
            timelockedAmount: 0,
            releaseTime: 0
        });
        locksRef.push(lock);
        lockIndex = locksRef.length - 1;
    }

    /**
     * @notice internal function
     * @param _tag bytes32String: up to 31 characters of user input as a label for the lock (may be "")
     * @param _tokenAddress token contract address or address(0) for native coin
     * @param _lockAmount unit value of amount to be locked
     * @param _lockTime UTC unix timestamp (seconds)
     * @param _unlockTime UTC unix timestamp (seconds)
     * @param _lockType LockType.<DRIP|HARD|BEHAVIORAL>
     * @return lockIndex array index of created lock
     */
    function _createLock(
        bytes32 _tag,
        address _tokenAddress,
        uint256 _lockAmount,
        uint256 _fee,
        uint64 _lockTime,   // UTC unix timestamp (seconds)
        uint64 _unlockTime, // UTC unix timestamp (seconds)
        LockType _lockType
    )
        internal
        returns (uint256 lockIndex)
    {
        require(_lockTime >= (uint64)(block.timestamp) - (6 * ONE_HOUR),
            "Lock time must not be more than six hours in the past"
        );
        require(_unlockTime > _lockTime,
            "Unlock time must be greater than lock time"
        );
        require((_unlockTime - _lockTime) < MAX_LOCK_SECONDS, // built-in "safe math" solidity@>0.8.0
            "Unlock time must be within 55 years of lock time"
        );

        unchecked { // division underflow acceptable (decimal truncation)
            uint256 _feeCheck = _lockAmount / FEE_DIVISOR;
            require(_feeCheck == _fee,
                "Fee calc audit failed"
            );
        }

        if (_tokenAddress == NATIVE_COIN) { // native coin

            uint256 _availableToLock = availableBalance(_tokenAddress); // any msg.value is already included in balance

            if (_availableToLock < (_lockAmount + _fee)) {
                revert InsufficientFunds(
                    address(this).balance - msg.value, // grossBalance (before msg.value, being 'refunded' by this revert)
                    _totalLockedAmount[_tokenAddress], // alreadyLocked
                    _availableToLock                   // availableToLock (includes any incoming msg.value (now being reverted))
                );
            }

            if (_fee > 0) {
                (bool feeTransferred, ) = address(_feeSplitter).call{value: _fee}("");
                require(
                    feeTransferred,
                    "Fee transfer rejected by external contract"
                );
            }

        } else { // 'RC20

            IERC20 tokenContract = IERC20(_tokenAddress);

            uint256 _availableToLock = availableBalance(_tokenAddress);

            if (_availableToLock < (_lockAmount + _fee)) {
                uint256 _tokenBalance = IERC20(tokenContract).balanceOf(address(this));
                revert InsufficientFunds(
                    _tokenBalance,                      // grossBalance
                    _totalLockedAmount[_tokenAddress],  // alreadyLocked
                    _availableToLock                    // availableToLock)
                );
            }

            if (_fee > 0) {
                bool feeTransferred = IERC20(tokenContract).transfer(
                    address(_feeSplitter),
                    _fee
                );
                require(
                    feeTransferred,
                    "Fee transfer rejected by external contract"
                );
                require(
                    // @dev splitERC20 splits and sends on the _feeSplitter's entire current balance
                    _feeSplitter.splitERC20(address(tokenContract)),
                    "Fee split callout failed"
                );
            }
        }

        lockIndex = _storeNewLock(
            _tag,
            _tokenAddress,
            _lockAmount,
            _lockTime,
            _unlockTime,
            _lockType
        );

        _totalLockedAmount[_tokenAddress] += _lockAmount;

        // update 'watchdog' deadman timer
        if (_deadmanTime < _unlockTime) _deadmanTime = _unlockTime;

        emit Locked(
            _tag,
            _tokenAddress,
            lockIndex,
            _lockAmount,
            _fee,
            _lockTime,
            _unlockTime,
            _lockType
        );
    }

    /**
     * Creates a new standard (LockType.DRIP) time lock.
     * @param _tag bytes32String: up to 31 characters of user input as a label for the lock (may be "")
     * @param _tokenAddress token contract address or address(0) for native coin
     * @param _lockAmount unit value of amount to be locked
     * @param _lockTime UTC unix timestamp (seconds)
     * @param _unlockTime UTC unix timestamp (seconds)
     * @return lockIndex array index of created lock
     */
    function createLock(
        bytes32 _tag,
        address _tokenAddress,
        uint256 _lockAmount,
        uint256 _fee,
        uint64 _lockTime,
        uint64 _unlockTime
    )
        public
        payable
        _onlyCapsuleOwner
        _notPanicState
        returns (uint256 lockIndex)
    {
        lockIndex = _createLock(
            _tag,
            _tokenAddress,
            _lockAmount,
            _fee,
            _lockTime,
            _unlockTime,
            LockType.DRIP
        );
    }

    /**
     * Creates a new hard lock (LockType.HARD) — a lock that does not drip and must complete full term before withdrawal.
     * @param _tag bytes32String: up to 31 characters of user input as a label for the lock (may be "")
     * @param _tokenAddress token contract address or address(0) for native coin
     * @param _lockAmount unit value of amount to be locked
     * @param _lockTime UTC unix timestamp (seconds)
     * @param _unlockTime UTC unix timestamp (seconds)
     * @return lockIndex array index of created lock
     */
    function createHardLock(
        bytes32 _tag,
        address _tokenAddress,
        uint256 _lockAmount,
        uint256 _fee,
        uint64 _lockTime,
        uint64 _unlockTime
    )
        public
        payable
        _onlyCapsuleOwner
        _notPanicState
        returns (uint256 lockIndex)
    {
        lockIndex = _createLock(
            _tag,
            _tokenAddress,
            _lockAmount,
            _fee,
            _lockTime,
            _unlockTime,
            LockType.HARD
        );
    }

    /**
     * Creates a behavioral lock (LockType.BAHVIORAL) which lasts up to a maximum of ONE YEAR from _lockStart
     * or immediately released when the correct unlock code is passed to releaseBehaviorLock().
     * @notice UI implementations should limit the unlock code to a simple six digit number.
     * @param _tag bytes32String: up to 31 characters of user input as a label for the lock (may be "")
     * @param _tokenAddress token contract address or address(0) for native coin
     * @param _lockAmount unit value of amount to be locked
     * @param _lockTime UTC unix timestamp (seconds)
     * @param _unlockHash first six bytes of a keccak256 (sha3) of a 'secret' unlock text (ideally UI limited to simple 6 digits)
     * @return lockIndex array index of created lock
     */
    /// @dev we consider it unsafe to trust a miner's clock for lock/unlock times
    function createBehaviorLock(
        bytes32 _tag,
        address _tokenAddress,
        uint256 _lockAmount,
        uint256 _fee,
        uint64  _lockTime,
        bytes6 _unlockHash
    )
        public
        payable
        _onlyCapsuleOwner
        _notPanicState
        returns (uint256 lockIndex)
    {
        lockIndex = _createLock(
            _tag,
            _tokenAddress,
            _lockAmount,
            _fee,
            _lockTime,
            _lockTime + BEHAVIORLOCK_SECONDS,
            LockType.BEHAVIORAL
        );
        _locks[_tokenAddress][lockIndex].unlockHash = _unlockHash;
    }

    /**
     * Intended for a bahioral lock 'friend' to check that the code they have is valid for a given lock.
     * @notice Behavioral locks are only minimally secure *intentionally*. The user who created
     * the lock may 'cheat' or 'fail to achieve their goal'. Thus for example, potential use
     * of this function to brute force the inlock code, while discouraged, is an acceptable
     * trade-off. After all, it is the vault owner's money and only their own self worth at stake.
     * @param _tokenAddress token contract address or address(0) for native coin
     * @param _lockIndex lock index
     * @param _unlockCode clear text unlock code
     * @return correct bool
     */
    function checkBehaviorLockCode(
        address _tokenAddress,
        uint256 _lockIndex,
        string memory _unlockCode
    )
        public
        view
        returns (bool correct)
    {
        bytes32 hashedUnlockCode = keccak256(abi.encodePacked(_unlockCode));
        correct = bytes6(hashedUnlockCode) == _locks[_tokenAddress][_lockIndex].unlockHash;
    }

    /**
     * Releases funds from a behavior lock if; a) given correct code OR b) a year has passed since the lock was cretaed.
     * @notice Funds are return to the vault's lockable balance. Withdrawal from the vault requires a new lock be created
     * @param _tokenAddress token contract address or address(0) for native coin
     * @param _lockIndex lock index (for this token)
     * @param _unlockCode clear text 'secret' unlock code (cAse senstitve)
     */
    function claimBehaviorLock(
        address _tokenAddress,
        uint256 _lockIndex,
        string memory _unlockCode
    )
        public
        payable
        _onlyCapsuleOwner
        _notPanicState
    {
        if (_locks[_tokenAddress][_lockIndex].lockTime > uint64(block.timestamp) - BEHAVIORLOCK_SECONDS) {
            require(
                checkBehaviorLockCode(_tokenAddress, _lockIndex, _unlockCode) == true,
                "Invalid code"
            );
        }
        _totalLockedAmount[_tokenAddress] -= _locks[_tokenAddress][_lockIndex].lockedAmount;
        _locks[_tokenAddress][_lockIndex].unlockTime = uint64(block.timestamp);
        releaseLock(_tokenAddress, _lockIndex);
    }

    /**
     * Returns value of token or coin realeasable NOW — aka the current DRIP amount.
     * @notice The actual value released by initiateWithdrawal() may differ — slightly higher.
     * However, making this a public function allows users to get an idea of current drip
     * amounts.
     * @param _tokenAddress token contract address or address(0) for native coin
     * @param _index lock index
     * @return withdrawalAllowance currently available withdrawable balance (drip amount)
     */
    function calculateAllowance(
        address _tokenAddress,
        uint256 _index
    )
        public
        view
        returns (uint256 withdrawalAllowance)
    {
        Lock memory lock = lockData(_tokenAddress, _index);

        if (lock.withdrawnToDate >= lock.lockedAmount) {
            withdrawalAllowance = 0;
        } else if (block.timestamp < (lock.lockTime - ONE_HOUR) || block.timestamp >= lock.unlockTime) {
            if (lock.withdrawnToDate >= lock.lockedAmount) {
                withdrawalAllowance = 0;
            } else {
                withdrawalAllowance = lock.lockedAmount - lock.withdrawnToDate;
            }
        } else {
            uint256 lockTerm = lock.unlockTime - lock.lockTime;
            uint256 termServed = ((block.timestamp - lock.lockTime) * 10000 ) / lockTerm ; // 10000 => 100.00% of term

            uint256 totalPortionFromStart = lock.lockedAmount * termServed;
            unchecked { // division undeflow acceptable (discard remainer)
                totalPortionFromStart /= 10000;
            }

            if (lock.withdrawnToDate >= totalPortionFromStart) withdrawalAllowance = 0;
            else withdrawalAllowance = totalPortionFromStart - lock.withdrawnToDate;

            // Web UI uses this function to display currently available "drip" amounts. So, we
            // account for a pending withdrawal by not including that amount in the returned allowance.
            if (lock.timelockedAmount >= withdrawalAllowance) withdrawalAllowance = 0;
            else withdrawalAllowance -= lock.timelockedAmount;
        }
    }

    /**
     * Releases any remaining balance in a lock without need of withdrawal.
     * Reverts if unlock time not yet reached.
     * @param _tokenAddress token contract address or address(0) for native coin
     * @param _lockIndex lock index (for this token)
     * @custom:emits LockReleased(tokenAddress, lockIndex)
     */
    function releaseLock(
        address _tokenAddress,
        uint256 _lockIndex
    )
        internal
    {
        Lock[] storage locksRef = _locks[_tokenAddress];
        Lock storage lock = locksRef[_lockIndex];

        require (
            block.timestamp >= lock.unlockTime,
            "Before unlock time"
        );

        // gas efficient removal of array element
        uint256 lastIndex = locksRef.length - 1;
        if (_lockIndex != lastIndex) locksRef[_lockIndex] = locksRef[lastIndex];
        locksRef.pop();

        emit LockReleased(
            _tokenAddress,
            _lockIndex
        );
    }

    /**
     * Initiates a seven day withdrawal timelock, after which sendWithdrawal() can be
     * called to retrieve the funds.
     * @notice Only ONE withdrawl may be active at a time for each token lock. (See `cancelWithdrawal()`, bellow.)
     * @param _tokenAddress token contract address or address(0) for native coin
     * @param _lockIndex lock index (for this token)
     * @custom:emits WithdrawalInitiated(tokenAddress, lockIndex, withdrawalAllowance)
     */
    function initiateWithdrawal(
        address _tokenAddress,
        uint256 _lockIndex
    )
        public
        _onlyCapsuleOwner
        _notPanicState
        returns (uint256 amount)
    {
        Lock[] storage locksRef = _locks[_tokenAddress];

        require(locksRef.length > 0,
            "Lock not found"
        );
        require(locksRef.length > _lockIndex,
            "Invalid lock index"
        );
        require(locksRef[_lockIndex].state != LockState.WITHDRAWAL_PENDING,
            "Withdrawal already pending"
        );

        Lock storage lock = locksRef[_lockIndex];

        require(
            lock.lockType != LockType.BEHAVIORAL,
            "Behavioral lock"
        );

        if (lock.lockType == LockType.HARD && uint64(block.timestamp) < lock.unlockTime) {
            revert HardLocked({
                unlockTime: lock.unlockTime
            });
        }

        uint256 withdrawalAllowance = calculateAllowance(
            _tokenAddress,
            _lockIndex
        );
        require(withdrawalAllowance > 0,
            "None available"
        );

        lock.state = LockState.WITHDRAWAL_PENDING;
        lock.timelockedAmount = withdrawalAllowance;
        lock.releaseTime = uint64(block.timestamp) + TIMELOCK_SECONDS;

        emit WithdrawalInitiated(
            _tokenAddress,
            _lockIndex,
            withdrawalAllowance
        );

        amount = withdrawalAllowance;
    }

    /**
     * Cancels a pending withdrawal
     * @param _tokenAddress token contract address or address(0) for native coin
     * @param _lockIndex lock index (for this token)
     * @custom:emits WithdrawalCancelled(tokenAddress, lockIndex)
     */
    function cancelWithdrawal(
        address _tokenAddress,
        uint256 _lockIndex
    )
        public
        _onlyCapsuleOwner
    {
        Lock[] storage locks = _locks[_tokenAddress];
        require(locks.length > 0,
            "No matching lock found"
        );
        require(locks.length > _lockIndex,
            "Invalid lock index"
        );
        Lock storage lock = locks[_lockIndex];
        require(lock.state == LockState.WITHDRAWAL_PENDING,
            "No withdrawal pending"
        );
        lock.timelockedAmount = 0;
        lock.state = LockState.INERT;

        emit WithdrawalCancelled(
            _tokenAddress,
            _lockIndex
        );
    }

    /**
     * Sends a pending seven day timelocked withdrawal to the vault's owner (reverts if not yet time)
     * @param _tokenAddress token contract address or address(0) for native coin
     * @param _lockIndex lock index (for this token)
     * @custom:emits Withdrawal(tokenAddress, lockIndex, withdrawalAmount)
     */
    function sendWithdrawal(
        address _tokenAddress,
        uint256 _lockIndex
    )
        public
        _onlyCapsuleOwner
        _notPanicState
    {
        Lock[] storage locksRef = _locks[_tokenAddress];
        Lock storage lock = locksRef[_lockIndex];

        require(
            lock.state == LockState.WITHDRAWAL_PENDING,
            "No withdrawal pending"
        );
        require(
            lock.timelockedAmount > 0,
            "No withdrawal pending"
        );

        require(
            block.timestamp >= lock.releaseTime,
            "Timelocked"
        );

        /**
         * @dev !IMPORTANT!: Clear the balance owed BEFORE calling sender's
         * potential contract address to avoid ye olde DAO dance (reentrance hack)
         */
        uint256 withdrawalAmount = lock.timelockedAmount;
        lock.timelockedAmount = 0;

        lock.withdrawnToDate += withdrawalAmount;

        bool withdrawalTransferred = (_tokenAddress == NATIVE_COIN)
            ?  _transferNative( owner, withdrawalAmount )
            :  _transferToken( _tokenAddress, owner, withdrawalAmount )
        ;
        require (
            withdrawalTransferred,
            "Withdrawal transfer failed"
        );

        _totalLockedAmount[_tokenAddress] -= withdrawalAmount;

        // check for last (emptying) withdrawal
        if (lock.withdrawnToDate >= lock.lockedAmount) {
            releaseLock(_tokenAddress, _lockIndex);
        } else {
            lock.releaseTime = 0; // gas discount
            lock.state = LockState.INERT;
        }

        emit Withdrawal(
            _tokenAddress,
            _lockIndex,
            withdrawalAmount
        );
    }

    /**
     * Splits a 65 byte (130 nibble) 'raw' signature into R, S, V components
     * @param _signature 65 byte (130 nibble) 'raw' signature
     * @return r signature R component
     * @return s signature S component
     * @return v signature V component
     */
    function _splitSignature(bytes memory _signature) private pure returns (bytes32 r, bytes32 s, uint8 v) {
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
    }

    /**
     * Recovers the address of the signer of a message hash
     * @param _messageHash keccak256 (sha3) hash of the message signed
     * @param _signature  65 byte (130 nibble) signature
     */
    function __recoverSignerAddress(
        bytes32 _messageHash,
        bytes memory _signature
    )
        private
        pure
        returns (address signerAddress)
    {
        (bytes32 r,bytes32 s, uint8 v) = _splitSignature(_signature);
        signerAddress = ecrecover(_messageHash, v, r, s);
    }

    /**
     * Recovers the address of the signer of a arbitrary length message
     * @param _message the signed message
     * @param _signature signature
     */
    function _recoverSignerAddress(
        string memory _message,
        bytes memory _signature
    )
        private
        pure
        returns (address signerAddress)
    {
        if (_signature.length != 65) return INVALID_SIGNER_ADDRESS;

        bytes32 _messageHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n",
                Strings.toString(bytes(_message).length),
                bytes(_message)
            )
        );

        signerAddress = __recoverSignerAddress(_messageHash, _signature);
    }

    /**
     * @notice internal function
     */
    function _panic() internal {
        require(
            _vaultStatus == VaultStatus.NOMINAL,
            "Panic is once only. Good luck!"
        );
        require(
            _capsuleFactory.isRecoveryHashValidated(owner) == true,
            "No recovery address"
        );

        _vaultStatus = VaultStatus.PANIC;

        emit RecoveryInitiated();
    }

    /**
     * Places the vault into PANIC state. NON-REVERSIBLE — vault must be recovered to.
     * NON-REVERSIBLE — vault must be "recovered" to regain functional access — see recoverVault()
     * @notice Two versions — see also panic(bytes memory _signature)
     */
    function panic() public _onlyCapsuleOwner {
         _panic();
    }

    /**
     * Allows anyone with an off-chain signed message from the original owner to place
     * the vault into PANIC state. NON-REVERSIBLE — vault must be "recovered" to regain
     * functional access — see recoverVault()
     * @notice Two versions — see also panic()
     */
    function panic(
        bytes memory _signature
    )
        public
    {
        address signerAddress = _recoverSignerAddress(VAULT_RECOVERY_AUTHORIZATION, _signature);
        require(signerAddress == owner, "Invalid signature");
        _panic();
    }

    /**
     * Recovers a vault from PANIC state — see panic() & panic(bytes memory _signature. (Also known as "undo a hack".)
     * Recovery can only be executed by the recovery address, which will become the vault's effective new owner.
     * The PANIC / RECOVERY process can only be executed ONCE. Don't get hacked again!
     * @notice internal function
     * @param _originalOwner address of original owner
     */
    function _recoverVault(
        address _originalOwner
    )
        internal
    {
        address _newOwner = msg.sender; // set local owner variable to new owner

        // update the factory contract's recovery and owner address mappings
        // reverts if vault's recoveryAddressHash does not match keccak256(_newOwner)
        _capsuleFactory.recoverOwnership(
            _originalOwner,
            _newOwner
        );
        owner = _newOwner;

        _vaultStatus = VaultStatus.RECOVERED;
        emit Recovered();
    }

    /**
     * Recovers an EXPIRED vault — one that has not had any lock/unlock activity for
     * a full year after the latest (most future) lock end time ever created.
     * @notice Only the recovery account can do this.
     * @param _originalOwner original owner's address
     */
    function recoverExpiredVault(
        address _originalOwner
    )
        public
    {
        uint64 deadmanRecoveryTime = _deadmanTime + ONE_YEAR;  // latest ever unlockTime plus one year
        uint64 blockTime = (uint64)(block.timestamp);
        require(blockTime >= deadmanRecoveryTime, "Vault not expired");
         _recoverVault(_originalOwner);
    }

    /**
     * Recovers a vault from PANIC state, passing ownership to the caller.
     * The vault must be in PANIC state and caller must be the recovery address
     * itself (according to stored recoveryAddressHash.)
     **/
    function recoverVault(
        address _originalOwner
    )
        public
    {
        require(_vaultStatus == VaultStatus.PANIC, "Forbidden");
        _recoverVault(_originalOwner);
    }
}