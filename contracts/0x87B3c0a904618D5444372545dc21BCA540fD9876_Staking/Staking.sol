/**
 *Submitted for verification at Etherscan.io on 2023-05-24
*/

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
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
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;


/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;



/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: MemagStaking.sol


pragma solidity 0.8.9;





contract Staking is Initializable, OwnableUpgradeable {
    /// @dev Memag ERC20 token address.
    IERC20Upgradeable public memagToken;

    /// @dev Max stakes user is allowed to create per pool.
    uint256 public maxStakePerPool;

    /// @dev Total pools created till now.
    uint256 public totalPools;

    /// @dev Address from which memag for staking rewards will be sent to users.
    address public stakingReserveAddress;

    /// @dev All users who have ever staked memag in the contract.
    address[] private stakeHolders;

    /// @dev Pool info to be stored onchain.
    struct PoolInfo {
        string name;
        uint256 apyPercent;
        uint256 apyDivisor;
        uint256 minStakeAmount;
        uint256 maxStakeAmount;
        uint256 duration;
        uint256 startTimestamp;
        uint256 endTimestamp;
        bool isActive;
    }
    
    /// @dev Stake info to be stored onchain.
    struct StakeInfo {
        uint256 poolId;
        uint256 startTimestamp;
        uint256 amount;
        bool isWithdrawn;
    }

    /// @dev Stored onchain to keep track of each stake's staker details for a pool.
    struct StakerInfo {
        address staker;
        uint256 stakeId;
    }

    /// @dev Pool info to be sent offchain in response to view functions.
    struct PoolInfoResponse {
        uint256 poolId;
        string name;
        uint256 apyPercent;
        uint256 apyDivisor;
        uint256 minStakeAmount;
        uint256 maxStakeAmount;
        uint256 duration;
        uint256 startTimestamp;
        uint256 endTimestamp;
        bool isActive;
    }

    /// @dev Stake info to be sent offchain in response to view functions.
    struct StakeInfoResponse {
        address staker;
        uint256 poolId;
        uint256 stakeId;
        uint256 apyPercent;
        uint256 apyDivisor;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 amount;
        uint256 rewardAmount;
        bool isWithdrawn;
    }

    /// @dev Mapping pool ids => pool details.
    mapping(uint256 => PoolInfo) public poolDetails;

    /// @dev Mapping user => total amount currently staked in contract.
    mapping(address => uint256) public totalStakedAmount;

    /// @dev Mapping user => pool id => total stakes done in this pool.
    mapping(address => mapping(uint256 => uint256)) public totalStakesInPoolBy;

    /// @dev Mapping user => pool id => stake id => stake details.
    mapping(address => mapping(uint256 => mapping(uint256 => StakeInfo))) public stakeDetails;

    /// @dev Mapping Pool id => Total stakes created in this pool.
    mapping(uint256 => uint256) public totalStakesInPool;

    /// @dev Mapping Pool Id => Stake Num In Pool => Staker Info (Staker Address + Stake Id)
    mapping(uint256 => mapping(uint256 => StakerInfo)) private stakerInfo;

    /// @dev Mapping user => bool(isStakeHolder).
    mapping(address => bool) public isStakeholder;
    
    // Events 
    /// @dev Emitted when a new pool is created.
    event PoolCreated(
        address indexed by,
        uint256 indexed poolId,
        string name,
        uint256 apyPercent,
        uint256 apyDivisor,
        uint256 minStakeAmount,
        uint256 maxStakeAmount,
        uint256 duration,
        uint256 startTimestamp,
        uint256 endTimestamp,
        bool isActive,
        uint256 createdAt
    );

    /// @dev Emitted when an existing pool is updated.
    event PoolUpdated(
        address indexed by,
        uint256 indexed poolId,
        string name,
        uint256 apyPercent,
        uint256 apyDivisor,
        uint256 minStakeAmount,
        uint256 maxStakeAmount,
        uint256 duration,
        uint256 startTimestamp,
        uint256 endTimestamp,
        bool isActive,
        uint256 updatedAt
    );

    /// @dev Emitted when a new stake is created.
    event StakeCreated(
        address indexed by,
        uint256 indexed poolId,
        uint256 indexed stakeId,
        uint256 startTimestamp,
        uint256 endTimestamp,
        uint256 amount
    );

    /// @dev Emitted when user withdraws stake.
    event StakeRemoved(
        address indexed by,
        uint256 indexed poolId,
        uint256 indexed stakeId,
        uint256 amount,
        uint256 removedAt
    );

    /// @dev Emitted when user withdraws stake, and reward is sent. 
    /// (block.timestamp > stake.startTimestamp + pool.duration)
    event RewardWithdrawn(
        address indexed by,
        uint256 indexed poolId,
        uint256 indexed stakeId,
        uint256 amount,
        uint256 withdrawnAt
    );

    /// @dev Emitted when user claims rewards from flexible pools.
    event RewardsClaimed(
        address indexed by,
        uint256 indexed poolId,
        uint256 stakeId,
        uint256 rewardAmount,
        uint256 stakedAmount,
        uint256 stakeDuration,
        uint256 timestamp
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }


    /**
     * @notice Initializes the contract.
     * @dev Verify the contract addresses being passed before deployment.
     * @param _memagAddress Address of memag ERC20 contract, cannot be updated later.
     * @param _stakingReserveAddress Address from which memag staking rewards will be paid, can be updated later.
     * @param _maxStakeLimitPerPool Max stakes user can create in each pool, can be updated later.
     */
    function initialize(
        address _memagAddress,
        address _stakingReserveAddress,
        uint256 _maxStakeLimitPerPool
    ) external initializer {
        __Ownable_init_unchained();
        memagToken = IERC20Upgradeable(_memagAddress);
        maxStakePerPool = _maxStakeLimitPerPool;
        stakingReserveAddress = _stakingReserveAddress;
    }


    /**
     * @notice Function for owner to set new staking reserve address.
     * @param _reserveAddress New staking reserve address.
     */
    function setStakingReserveAddress(address _reserveAddress) external onlyOwner {
        require(
            _reserveAddress != address(0),
            "Error: Address should be valid"
        );
        stakingReserveAddress = _reserveAddress;
    }


    /**
     * @notice Function for owner to set max stake limit per pool.
     * @param _maxStakeLimit New max stake limit per pool.
     */
    function setMaxStakeLimitPerPool(uint256 _maxStakeLimit) external onlyOwner {
        require(
            _maxStakeLimit > 0,
            "Error: The limit should not be 0"
        );
        maxStakePerPool = _maxStakeLimit;
    }

    
    /**
     * @notice Function for owner to create a new staking pool.
     * @dev _duration will be uint256 max for flexible staking pools.
     * @param _name Name of the pool.
     * @param _apyPercent APY Percent Numerator
     * @param _apyDivisor APY Percent Denominator
     * @param _minStakeAmount Minimum amount of memag(inclusive) allowed to be staked in this pool.
     * @param _maxStakeAmount Maximum amount of memag(inclusive) allowed to be staked in this pool.
     * @param _duration Duration(in seconds), for which memag should be staked in pool to get rewards on withdrawal.
     * @param _startTimestamp Time after which staking in this pool would start.
     * @param _endTimestamp Time after which staking in this pool would end.
     * @param _isActive true: Pool is active, false: Pool is inactive.
     */
    function createPool(
        string memory _name,
        uint256 _apyPercent,
        uint256 _apyDivisor,
        uint256 _minStakeAmount,
        uint256 _maxStakeAmount,
        uint256 _duration,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        bool _isActive
    ) external onlyOwner {
        require(
            _apyPercent > 0,
            "Error: APY percent should be greater than 0"
        );
        require(
            _apyDivisor > 0,
            "Error: APY divisor should be greater than 0"
        );
        require(
            _minStakeAmount > 0,
            "Error: Min stake amount should be greater than 0"
        );
        require(
            _maxStakeAmount >= _minStakeAmount,
            "Error: Max stake amount should be greater than min stake amount"
        );
        require(
            _duration > 0,
            "Error: Duration should be greater than 0"
        );
        require(
            _startTimestamp >= block.timestamp,
            "Error: Pool start date should not be in past"
        );
        require(
            _endTimestamp > _startTimestamp,
            "Error: Pool end date should be greater than start date"
        );
        
        /// @dev New pool stored in storage.
        unchecked { 
            poolDetails[++totalPools] = PoolInfo(
                _name,
                _apyPercent,
                _apyDivisor,
                _minStakeAmount,
                _maxStakeAmount,
                _duration,
                _startTimestamp,
                _endTimestamp,
                _isActive
            );
        }

        emit PoolCreated(
            msg.sender,
            totalPools,
            _name,
            _apyPercent,
            _apyDivisor,
            _minStakeAmount,
            _maxStakeAmount,
            _duration,
            _startTimestamp,
            _endTimestamp,
            _isActive,
            block.timestamp
        );
    } 


    /**
     * @notice Function for owner to update an existing pool.
     * @param _poolId Id of the pool to update, should exist already.
     * @param _name Name of the pool.
     * @param _apyPercent APY Percent Numerator
     * @param _apyDivisor APY Percent Denominator
     * @param _minStakeAmount Minimum amount of memag(inclusive) allowed to be staked in this pool.
     * @param _maxStakeAmount Maximum amount of memag(inclusive) allowed to be staked in this pool.
     * @param _duration Duration(in seconds), for which memag should be staked in pool to get rewards on withdrawal.
     * @param _startTimestamp Time after which staking in this pool would start.
     * @param _endTimestamp Time after which staking in this pool would end.
     * @param _isActive true: Pool is active, false: Pool is inactive.
     */
    function updatePool(
        uint256 _poolId,
        string memory _name,
        uint256 _apyPercent,
        uint256 _apyDivisor,
        uint256 _minStakeAmount,
        uint256 _maxStakeAmount,
        uint256 _duration,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        bool _isActive
    ) external onlyOwner {
        PoolInfo storage poolInfo = poolDetails[_poolId];
        require(
            poolInfo.duration != 0,
            "Error: Pool with this id does not exist"
        );
        require(
            _apyPercent > 0,
            "Error: APY percent should be greater than 0"
        );
        require(
            _apyDivisor > 0,
            "Error: APY divisor should be greater than 0"
        );
        require(
            _minStakeAmount > 0,
            "Error: Min stake amount should be greater than 0"
        );
        require(
            _maxStakeAmount >= _minStakeAmount,
            "Error: Max stake amount should be greater than min stake amount"
        );
        require(
            _endTimestamp > _startTimestamp,
            "Error: Pool end date should be greater than start date"
        );
        if (_startTimestamp != poolInfo.startTimestamp) {
            require(
                _startTimestamp >= block.timestamp,
                "Error: Pool start date should not be in past"
            );
        }
        
        if (poolInfo.duration == type(uint256).max) {
            require(
                _duration == type(uint256).max,
                "Error: Cannot convert flexible pool to locked pool."
            );
        } else {
            require(
                _duration > 0,
                "Error: Duration should be greater than 0"
            );
        }
        
        /// @dev Updated pool stored in storage.
        poolDetails[_poolId] = PoolInfo(
            _name,
            _apyPercent,
            _apyDivisor,
            _minStakeAmount,
            _maxStakeAmount,
            _duration,
            _startTimestamp,
            _endTimestamp,
            _isActive
        );

        emit PoolUpdated(
            msg.sender,
            _poolId,
            _name,
            _apyPercent,
            _apyDivisor,
            _minStakeAmount,
            _maxStakeAmount,
            _duration,
            _startTimestamp,
            _endTimestamp,
            _isActive,
            block.timestamp
        );
    } 


    /**
     * @notice Function for users to create a new stake in stake pool.
     * @param _poolId Id of the staking pool in which to create the new stake.
     * @param _amount Amount of memag to stake.
     * @return Stake id of the new stake created in this pool. (User address => Pool id => Stake id)
     */
    function createStake(
        uint256 _poolId,
        uint256 _amount
    ) external returns (uint256) {
        PoolInfo storage poolInfo = poolDetails[_poolId];
        require(
            poolInfo.duration != 0,
            "Error: Pool with this id does not exist"
        );
        require(
            poolInfo.isActive,
            "Error: The pool is inactive"
        );
        require(
            block.timestamp >= poolInfo.startTimestamp,
            "Error: The pool has not started yet"
        );
        require(
            block.timestamp <= poolInfo.endTimestamp,
            "Error: The pool is expired"
        );
        // Amount checks
        require(
            _amount >= poolInfo.minStakeAmount,
            "Error: Amount should not be less than minimum stake amount"
        );
        require(
            memagToken.balanceOf(msg.sender) >= _amount,
            "Error: Insufficient MEMAG balance"
        );
        require(
            memagToken.allowance(msg.sender, address(this)) >= _amount,
            "Error: Insufficient MEMAG allowance"
        );

        if(!isStakeholder[msg.sender]){
            isStakeholder[msg.sender] = true;
            stakeHolders.push(msg.sender);
        }

        /// @dev Increase total staked amount for user.
        unchecked { totalStakedAmount[msg.sender] = totalStakedAmount[msg.sender] + _amount; }

        if (poolInfo.duration == type(uint256).max) {
            /// @dev Stake is being created in a flexible pool.
            flexiblePoolStake(_poolId, _amount, poolInfo.maxStakeAmount);
        } else {
            /// @dev Stake is being created in a locked pool.
            lockedPoolStake(_poolId, _amount, poolInfo.maxStakeAmount, poolInfo.duration);
        }
        
        // Transfer memag tokens from user to this contract.
        memagToken.transferFrom(msg.sender, address(this), _amount);
        return totalStakesInPoolBy[msg.sender][_poolId];
    }


    /**
     * @notice Function for users to unstake stake id in given pool id.
     * @param _poolId Id of the stake pool to withdraw the stake from.
     * @param _stakeId Id of the stake to withdraw from above pool, constant as 1 for flexible pools.
     * @param _amount Amount to withdraw, only used for flexible pools.
     */
    function withdrawStake(
        uint256 _poolId,
        uint256 _stakeId,
        uint256 _amount
    ) external {
        StakeInfo storage stakeInfo = stakeDetails[msg.sender][_poolId][_stakeId];
        PoolInfo storage poolInfo = poolDetails[_poolId];
        require(
            stakeInfo.amount != 0,
            "Error: Stake does not exist"
        );
        require(
            !stakeInfo.isWithdrawn,
            "Error: Already withdrawn"
        );
        require(
            memagToken.balanceOf(address(this)) >= stakeInfo.amount,
            "Error: Insufficient memag funds in contract"
        );

        /// @dev Withdrawal from flexible pool.
        if (poolInfo.duration == type(uint256).max) {
            require(
                _amount <= stakeInfo.amount,
                "Cannot withdraw more than the staked amount!"
            );
            require(
                stakeInfo.amount - _amount == 0 ||
                stakeInfo.amount - _amount >= poolInfo.minStakeAmount,
                "Remaining staked amount less than min amount"
            );
            _amount = flexiblePoolWithdraw(stakeInfo, _poolId, _amount);

        /// @dev Withdrawal from locked pool.
        } else {
            _amount = lockedPoolWithdraw(stakeInfo, _poolId, _stakeId);
        }

        emit StakeRemoved(
            msg.sender,
            _poolId,
            _stakeId,
            _amount,
            block.timestamp
        );
        // Transfer user's staked memag tokens back from this contract.
        memagToken.transfer(msg.sender, _amount);
    }


    /**
     * @notice Function for users to claim rewards from flexible pools.
     * @param _poolId Id of the pool from which to claim rewards.
     */
    function claimRewards(uint256 _poolId) external {
        require(
            poolDetails[_poolId].duration == type(uint256).max,
            "Not a flexible pool"
        );
        StakeInfo storage stake = stakeDetails[msg.sender][_poolId][1];
        require(
            stake.amount > 0,
            "Not staked!"
        );
        uint256 stakedDuration = block.timestamp > poolDetails[_poolId].endTimestamp ?
            poolDetails[_poolId].endTimestamp - stake.startTimestamp :
            block.timestamp - stake.startTimestamp;
     
        uint256 rewardAmount = calculateReward(
            _poolId,
            stake.amount,
            stakedDuration
        );
        stake.startTimestamp = block.timestamp;

        emit RewardsClaimed(
            msg.sender,
            _poolId,
            1,
            rewardAmount,
            stake.amount,
            stakedDuration,
            block.timestamp
        );
        memagToken.transferFrom(stakingReserveAddress, msg.sender, rewardAmount);
    }


    // |==============================================================================================================|
    // |---------------------------------------VIEW FUNCTIONS---------------------------------------------------------|
    // |==============================================================================================================|

    /**
     * @notice Function to calculate the memag amount user would get as reward for a stake in a particular pool.
     * @param _poolId Id of the stake pool for which to calculate reward..
     * @param _amount Memag amount to be staked in this pool.
     * @param _duration Duration for which _amount was staked in pool, used only in flexible pool reward calculation.
     * @return Amount of memag user would get as stake reward for this stake.
     */
    function calculateReward(
        uint256 _poolId,
        uint256 _amount,
        uint256 _duration
    ) public view returns(uint256) {
        PoolInfo storage _poolDetails = poolDetails[_poolId];
        if(_amount == 0) {
            return 0;
        }
        if (_poolDetails.duration != type(uint256).max) {
            _duration = _poolDetails.duration;
        }
        /// @dev Staked Amount * (APY Numerator/ APY Denominator) * (Staked duration in seconds/ Seconds in 1 year)
        return (
            (_amount * _poolDetails.apyPercent * _duration) /
            (_poolDetails.apyDivisor * 365 * 86400)
        );
    }


    /**
     * @notice Function to return list of addresses that have ever staked memag in contract.
     */
    function getStakeholders() external view returns(address[] memory) {
        return stakeHolders;
    }


    // |==============================================================================================================|
    // |------------------------------------FUNCTIONS RETURNING POOL DETAILS------------------------------------------|
    // |==============================================================================================================|

    /**
     * @notice Function to return whether a pool with given id exists or not.
     * @param _poolId Id of the pool whose existence to check.
     */
    function poolExists(uint256 _poolId) public view returns (bool) {
        return poolDetails[_poolId].duration != 0;
    }

    /**
     * @notice Function to return details of multiple pool ids.
     * @param _poolIDs Array of pool ids for which to return details.
     */
    function getPools(uint256[] memory _poolIDs) external view returns(PoolInfoResponse[] memory) {
        PoolInfoResponse[] memory pools = new PoolInfoResponse[](_poolIDs.length);
        for(uint256 i=0; i<_poolIDs.length; ++i) {
            require(poolExists(_poolIDs[i]), "Pool does not exist!");
            pools[i] = createPoolInfoResponse(_poolIDs[i]);
        }
        return pools;
    }


    /**
     * @notice Function to return total flexible pools count and their ids.
     * @dev poolIDs array has extra empty values => loop from index: 0 to flexiblePools-1
     */
    function getFlexiblePoolIDs() public view returns(uint256, uint256[] memory) {
        uint256 flexiblePools = 0;
        uint256[] memory poolIDs = new uint256[](totalPools);
        for(uint256 i=1; i<=totalPools; ++i) {
            if(poolDetails[i].duration == type(uint256).max) {
                poolIDs[flexiblePools++] = i;
            }
        }
        return (flexiblePools, poolIDs);
    }


    /**
     * @notice Function to return total live pools count and their ids.
     * @dev poolIDs array has extra empty values => loop from index: 0 to livePools-1
     */
    function getLivePoolIDs() public view returns(uint256, uint256[] memory) {
        uint256 livePools = 0;
        uint256[] memory poolIDs = new uint256[](totalPools);
        for(uint256 i=1; i<=totalPools; ++i) {
            if(
                block.timestamp >= poolDetails[i].startTimestamp &&
                block.timestamp <= poolDetails[i].endTimestamp
            ) {
                poolIDs[livePools++] = i;
            }
        }
        return (livePools, poolIDs);
    }


    /**
     * @notice Function to return total past pools count and their ids.
     * @dev poolIDs array has extra empty values => loop from index: 0 to pastPools-1
     */
    function getPastPoolIDs() public view returns(uint256, uint256[] memory) {
        uint256 pastPools = 0;
        uint256[] memory poolIDs = new uint256[](totalPools);
        for(uint256 i=1; i<=totalPools; ++i) {
            if(block.timestamp > poolDetails[i].endTimestamp) {
                poolIDs[pastPools++] = i;
            }
        }
        return (pastPools, poolIDs);
    }


    /**
     * @notice Function to return total upcoming pools count and their ids.
     * @dev poolIDs array has extra empty values => loop from index: 0 to upcomingPools-1
     */
    function getUpcomingPoolIDs() public view returns(uint256, uint256[] memory) {
        uint256 upcomingPools = 0;
        uint256[] memory poolIDs = new uint256[](totalPools);
        for(uint256 i=1; i<=totalPools; ++i) {
            if(block.timestamp < poolDetails[i].startTimestamp) {
                poolIDs[upcomingPools++] = i;
            }
        }
        return (upcomingPools, poolIDs);
    }


    /**
     * @notice Function to return total active pools count and their ids.
     * @dev poolIDs array has extra empty values => loop from index: 0 to activePools-1
     */
    function getActivePoolIDs() public view returns(uint256, uint256[] memory) {
        uint256 activePools = 0;
        uint256[] memory poolIDs = new uint256[](totalPools);
        for(uint256 i=1; i<=totalPools; ++i) {
            if(poolDetails[i].isActive) {
                poolIDs[activePools++] = i;
            }
        }
        return (activePools, poolIDs);
    }


    /**
     * @notice Function to return total inactive pools count and their ids.
     * @dev poolIDs array has extra empty values => loop from index: 0 to inactivePools-1
     */
    function getInactivePoolIDs() public view returns(uint256, uint256[] memory) {
        uint256 inactivePools = 0;
        uint256[] memory poolIDs = new uint256[](totalPools);
        for(uint256 i=1; i<=totalPools; ++i) {
            if(!poolDetails[i].isActive) {
                poolIDs[inactivePools++] = i;
            }
        }
        return (inactivePools, poolIDs);
    }


    /**
     * @notice Function to return total active+live pools count and their ids.
     * @dev poolIDs array has extra empty values => loop from index: 0 to activeLivePools-1
     */
    function getActiveLivePoolIDs() public view returns(uint256, uint256[] memory) {
        uint256 activeLivePools = 0;
        uint256[] memory poolIDs = new uint256[](totalPools);
        for(uint256 i=1; i<=totalPools; ++i) {
            if(
                poolDetails[i].isActive &&
                block.timestamp >= poolDetails[i].startTimestamp &&
                block.timestamp <= poolDetails[i].endTimestamp
            ) {
                poolIDs[activeLivePools++] = i;
            }
        }
        return (activeLivePools, poolIDs);
    }


    /**
     * @notice Function to return total inactive+live pools count and their ids.
     * @dev poolIDs array has extra empty values => loop from index: 0 to inactiveLivePools-1
     */
    function getInactiveLivePoolIDs() public view returns(uint256, uint256[] memory) {
        uint256 inactiveLivePools = 0;
        uint256[] memory poolIDs = new uint256[](totalPools);
        for(uint256 i=1; i<=totalPools; ++i) {
            if(
                !poolDetails[i].isActive &&
                block.timestamp >= poolDetails[i].startTimestamp &&
                block.timestamp <= poolDetails[i].endTimestamp
            ) {
                poolIDs[inactiveLivePools++] = i;
            }
        }
        return (inactiveLivePools, poolIDs);
    }


    /**
     * @notice Function to return total active+past pools count and their ids.
     * @dev poolIDs array has extra empty values => loop from index: 0 to activePastPools-1
     */
    function getActivePastPoolIDs() public view returns(uint256, uint256[] memory) {
        uint256 activePastPools = 0;
        uint256[] memory poolIDs = new uint256[](totalPools);
        for(uint256 i=1; i<=totalPools; ++i) {
            if(
                poolDetails[i].isActive &&
                block.timestamp > poolDetails[i].endTimestamp
            ) {
                poolIDs[activePastPools++] = i;
            }
        }
        return (activePastPools, poolIDs);
    }


    /**
     * @notice Function to return total inactive+past pools count and their ids.
     * @dev poolIDs array has extra empty values => loop from index: 0 to inactivePastPools-1
     */
    function getInactivePastPoolIDs() public view returns(uint256, uint256[] memory) {
        uint256 inactivePastPools = 0;
        uint256[] memory poolIDs = new uint256[](totalPools);
        for(uint256 i=1; i<=totalPools; ++i) {
            if(
                !poolDetails[i].isActive &&
                block.timestamp > poolDetails[i].endTimestamp
            ) {
                poolIDs[inactivePastPools++] = i;
            }
        }
        return (inactivePastPools, poolIDs);
    }


    /**
     * @notice Function to return total active+upcoming pools count and their ids.
     * @dev poolIDs array has extra empty values => loop from index: 0 to activeUpcomingPools-1
     */
    function getActiveUpcomingPoolIDs() public view returns(uint256, uint256[] memory) {
        uint256 activeUpcomingPools = 0;
        uint256[] memory poolIDs = new uint256[](totalPools);
        for(uint256 i=1; i<=totalPools; ++i) {
            if(
                poolDetails[i].isActive &&
                block.timestamp < poolDetails[i].startTimestamp
            ) {
                poolIDs[activeUpcomingPools++] = i;
            }
        }
        return (activeUpcomingPools, poolIDs);
    }


    /**
     * @notice Function to return total inactive+upcoming pools count and their ids.
     * @dev poolIDs array has extra empty values => loop from index: 0 to inactiveUpcomingPools-1
     */
    function getInactiveUpcomingPoolIDs() public view returns(uint256, uint256[] memory) {
        uint256 inactiveUpcomingPools = 0;
        uint256[] memory poolIDs = new uint256[](totalPools);
        for(uint256 i=1; i<=totalPools; ++i) {
            if(
                !poolDetails[i].isActive &&
                block.timestamp < poolDetails[i].startTimestamp
            ) {
                poolIDs[inactiveUpcomingPools++] = i;
            }
        }
        return (inactiveUpcomingPools, poolIDs);
    }

    /**
     * @notice Function to return details of multiple pools starting from one pool id.
     * @param _startingPoolId Id of the pool from which to start returning data.
     * @param _numberOfPools No of pools for which to return data.
     */
    function getPoolDetailsFrom(
        uint256 _startingPoolId,
        uint256 _numberOfPools
    ) external view returns(PoolInfoResponse[] memory) {
        require(
            poolExists(_startingPoolId) &&
            poolExists(_startingPoolId+_numberOfPools-1),
            "Pool does not exist!"
        );
        PoolInfoResponse[] memory _poolDetails = new PoolInfoResponse[](_numberOfPools);
        uint256 _index;
        for(uint256 i=_startingPoolId; i<_startingPoolId+_numberOfPools; ++i) {
            _poolDetails[_index++] = createPoolInfoResponse(i);
        }
        return _poolDetails;
    }

    // |==============================================================================================================|
    // |------------------------------------FUNCTIONS RETURNING STAKER DETAILS----------------------------------------|
    // |==============================================================================================================|

    /**
     * @notice Function to return staker info (Address + Stake id) for n'th stake created in a pool.
     * @param _poolId Id of the stake pool.
     * @param _stakeNum Stake number in pool with given id to return the staker info for.
     */
    function getStakerInfo(uint256 _poolId, uint256 _stakeNum) external view returns(StakerInfo memory) {
        return stakerInfo[_poolId][_stakeNum];
    }

    /**
     * @notice Function to return staker details of '_count' stakes in a pool starting from stake no '_startStakeNum'
     * @param _poolId Id of the pool
     * @param _startStakeNum Stake no (ex: 5th) in pool from which to start returning Staker data.
     * @param _count No of stakes for which to return data.
     */
    function getStakerInfoFrom(
        uint256 _poolId,
        uint256 _startStakeNum,
        uint256 _count
    ) external view returns(StakerInfo[] memory) {
        StakerInfo[] memory stakersInfoInPool = new StakerInfo[](_count);
        uint256 _index=0;
        for(uint256 i=_startStakeNum; i<_startStakeNum+_count; ++i) {
            stakersInfoInPool[_index++] = stakerInfo[_poolId][i];
        }
        return stakersInfoInPool;
    }

    // |==============================================================================================================|
    // |------------------------------------FUNCTIONS RETURNING STAKE DETAILS-----------------------------------------|
    // |==============================================================================================================|
    
    /**
     * @notice Function to return whether a stake with given id exists in a pool or not for given address.
     * @param _address Address of user for whom to check the stake existence.
     * @param _poolId Id of the pool in which to look for the stake.
     * @param _stakeId Id of the stake whose existence to check in given pool id for given user address.
     */
    function stakeExists(address _address, uint256 _poolId, uint256 _stakeId) external view returns (bool) {
        return stakeDetails[_address][_poolId][_stakeId].amount != 0;
    }

    
    /**
     * @notice Function to return total stakes done in the contract by an user in all pools collectively.
     * @param _address Address for which to  return the total stakes amount.
     */
    function getTotalStakes(address _address) public view returns(uint256) {
        uint256 totalStakes = 0;
        for(uint256 i=1; i<=totalPools; ++i) {
            totalStakes += totalStakesInPoolBy[_address][i];
        }
        return totalStakes;
    }


    /**
     * @notice Function to return details of all stakes done in one particular pool by an user.
     * @param _address Address for which to return the stake data.
     * @param _poolId Id of the pool, from which stake data to return.
     */
    function getAllStakeDetails(address _address, uint256 _poolId) public view returns(StakeInfoResponse[] memory) {
        uint256 stakesInPool = totalStakesInPoolBy[_address][_poolId];
        StakeInfoResponse[] memory allStakes = new StakeInfoResponse[](stakesInPool);

        for(uint256 i=1; i<=stakesInPool; ++i) {
            allStakes[i-1] = createStakeInfoResponse(_address, _poolId, i);
        }
        return allStakes;
    }


    /**
     * @notice Function to return details of all stakes done in all pools ever by an user.
     * @param _address Address for which to return the stake data from all pools.
     */
    function getAllStakeDetailsFor(address _address) external view returns(StakeInfoResponse[] memory) {
        uint256 totalStakes = getTotalStakes(_address);
        StakeInfoResponse[] memory allStakes = new StakeInfoResponse[](totalStakes);
        uint256 stakeNum = 0;
        for(uint256 i=1; i<=totalPools; ++i) {
            uint256 stakesInPool = totalStakesInPoolBy[_address][i];
            for(uint256 j=1; j<=stakesInPool; ++j) {
                allStakes[stakeNum] = createStakeInfoResponse(_address, i, j);
                stakeNum += 1;
            }
        }
        return allStakes;
    }


    /**
     * @notice Function to return total stakes user has in given pool ids. (Combined + [Individual pool counts])
     * @param _address Address for which to return the stake counts.
     * @param _poolIDs IDs of the pools for which to return the stake counts.
     */
    function getStakeCountInPoolsFor(
        address _address,
        uint256[] memory _poolIDs
    ) public view returns(uint256, uint256[] memory) {
        uint256[] memory _stakeCounts = new uint256[](_poolIDs.length);
        uint256 _totalStakes = 0;
        for(uint256 i=0; i<_poolIDs.length; ++i) {
            _stakeCounts[i] = totalStakesInPoolBy[_address][_poolIDs[i]];
            _totalStakes += _stakeCounts[i];
        }
        return (_totalStakes, _stakeCounts);
    }


    /**
     * @notice Function to return stake details for user in given pool ids.
     * @param _address Address for which to return the stake details.
     * @param _poolIDs IDs of the pools for which to return the stake details of user.
     */
    function getStakeDetailsInPoolsFor(
        address _address,
        uint256[] memory _poolIDs
    ) external view returns(StakeInfoResponse[] memory) {
        (uint256 _totalStakes, uint256[] memory _stakeCounts) = getStakeCountInPoolsFor(_address, _poolIDs);
        StakeInfoResponse[] memory _stakeDetails = new StakeInfoResponse[](_totalStakes);
        uint256 _index = 0;
        for(uint256 i=0; i<_poolIDs.length; ++i) {
            for(uint256 j=1; j<=_stakeCounts[i]; ++j) {
                _stakeDetails[_index++] = createStakeInfoResponse(_address, _poolIDs[i], j);
            }
        }
        return _stakeDetails;
    }

    /**
     * @notice Function to return details of '_count' stakes in a pool starting from stake no '_startStakeNum'
     * @param _poolId Id of the pool
     * @param _startStakeNum Stake no (ex: 5th) in pool from which to start returning Stake data.
     * @param _count No of stakes for which to return data.
     */
    function getStakeDetailsInPoolFrom(
        uint256 _poolId,
        uint256 _startStakeNum,
        uint256 _count
    ) external view returns(StakeInfoResponse[] memory) {
        require(
            poolExists(_poolId),
            "Pool does not exist!"
        );
        require(
            _startStakeNum > 0 &&
            _startStakeNum + _count - 1 <= totalStakesInPool[_poolId],
            "Invalid stake number!"
        );
        uint256 _counter = 0;
        StakeInfoResponse[] memory _stakeDetails = new StakeInfoResponse[](_count);
        for(uint256 i=_startStakeNum; i<_startStakeNum+_count; ++i) {
            StakerInfo memory stake = stakerInfo[_poolId][i];
            _stakeDetails[_counter++] = createStakeInfoResponse(stake.staker, _poolId, stake.stakeId);
        }
        return _stakeDetails;
    }

    // |==============================================================================================================|
    // |---------------------------------------PRIVATE FUNCTIONS------------------------------------------------------|
    // |==============================================================================================================|

    /**
     * @dev Creates and returns pool data in PoolInfoResponse struct format using PoolInfo from storage.
     */
    function createPoolInfoResponse(uint256 _poolId) private view returns (PoolInfoResponse memory) {
        PoolInfo memory poolInfo = poolDetails[_poolId];
        return PoolInfoResponse(
            _poolId,
            poolInfo.name,
            poolInfo.apyPercent,
            poolInfo.apyDivisor,
            poolInfo.minStakeAmount,
            poolInfo.maxStakeAmount,
            poolInfo.duration,
            poolInfo.startTimestamp,
            poolInfo.endTimestamp,
            poolInfo.isActive
        );
    }

    /**
     * @dev Creates and returns stake data in StakeInfoResponse struct format using PoolInfo and StakeInfo from storage
     */
    function createStakeInfoResponse(
        address _address,
        uint256 _poolId,
        uint256 _stakeId
    ) private view returns (StakeInfoResponse memory) {
        StakeInfo memory stakeInfo = stakeDetails[_address][_poolId][_stakeId];
        PoolInfo memory poolInfo = poolDetails[_poolId];
        return StakeInfoResponse(
            _address,
            _poolId,
            _stakeId,
            poolInfo.apyPercent,
            poolInfo.apyDivisor,
            stakeInfo.startTimestamp,
            poolInfo.duration == type(uint256).max ?
                poolInfo.endTimestamp :
                stakeInfo.startTimestamp + poolInfo.duration,
            stakeInfo.amount,
            calculateReward(
                _poolId,
                stakeInfo.amount,
                poolInfo.duration == type(uint256).max ? (
                    block.timestamp > poolInfo.endTimestamp ?
                        poolInfo.endTimestamp - stakeInfo.startTimestamp :
                        block.timestamp - stakeInfo.startTimestamp
                    ) :
                    0
            ),
            stakeInfo.isWithdrawn
        );
    }


    /**
     * @dev Handles stakes created in flexible pools.
     * @param _poolId Id of the pool.
     * @param _amount Amount to be staked.
     * @param _maxStakeAmount Max Stake Amount allowed in the pool.
     */
    function flexiblePoolStake(
        uint256 _poolId,
        uint256 _amount,
        uint256 _maxStakeAmount
    ) private {
        StakeInfo storage stake = stakeDetails[msg.sender][_poolId][1];

        if (stake.amount == 0 || stake.isWithdrawn) {
            require(
                _amount <= _maxStakeAmount,
                "Error: Amount should not be more than maximum stake amount"
            );
        } else {
            require(
                stake.amount + _amount <= _maxStakeAmount,
                "Error: Amount should not be more than maximum stake amount"
            );
        }
        
        /// @dev First stake.
        if (totalStakesInPoolBy[msg.sender][_poolId] == 0) {
            unchecked {
                // Staker Info
                ++totalStakesInPoolBy[msg.sender][_poolId];
                stakerInfo[_poolId][++totalStakesInPool[_poolId]] = StakerInfo(
                    msg.sender,
                    1
                );
            }
            // Stake Data.
            stakeDetails[msg.sender][_poolId][1] = StakeInfo(
                _poolId,
                block.timestamp,
                _amount,
                false
            );
        
        /// @dev Subsequent stakes.
        } else {
            uint256 _rewardAmount;
            if (stake.isWithdrawn) {
                stake.isWithdrawn = false;
                unchecked { stake.amount = _amount; }
            } else {
                _rewardAmount = calculateReward(
                    _poolId,
                    stake.amount,
                    block.timestamp - stake.startTimestamp
                );
                unchecked { stake.amount = stake.amount + _amount; }
            }
            
            stake.startTimestamp = block.timestamp;
            
            /// @dev Send rewards accumulated till now, if _rewardAmount > 0.
            if (_rewardAmount > 0) {
                emit RewardWithdrawn(
                    msg.sender,
                    _poolId,
                    1,
                    _rewardAmount,
                    block.timestamp
                );
                memagToken.transferFrom(stakingReserveAddress, msg.sender, _rewardAmount);
            }
        }
        emit StakeCreated(
            msg.sender,
            _poolId,
            1,
            block.timestamp,
            poolDetails[_poolId].endTimestamp,
            _amount
        );
    }


    /**
     * @dev Handles stakes created in locked pools.
     * @param _poolId Id of the pool.
     * @param _amount Amount to be staked.
     * @param _maxStakeAmount Max Stake Amount allowed in the pool.
     * @param _lockInDuration Lock In duration of this pool.
     */
    function lockedPoolStake(
        uint256 _poolId,
        uint256 _amount,
        uint256 _maxStakeAmount,
        uint256 _lockInDuration
    ) private {
        require(
            _amount <= _maxStakeAmount,
            "Error: Amount should not be more than maximum stake amount"
        );
        uint256 stakesInPool;
        unchecked { stakesInPool = ++totalStakesInPoolBy[msg.sender][_poolId]; }
        require(
            stakesInPool <= maxStakePerPool,
            "Error: Max participation limit for pool reached"
        );
        /// @dev New stake stored in storage.
        stakeDetails[msg.sender][_poolId][stakesInPool] = StakeInfo(
            _poolId,
            block.timestamp,
            _amount,
            false
        );
        unchecked {
            stakerInfo[_poolId][++totalStakesInPool[_poolId]] = StakerInfo(
                msg.sender,
                stakesInPool
            );

            emit StakeCreated(
                msg.sender,
                _poolId,
                totalStakesInPoolBy[msg.sender][_poolId],
                block.timestamp,
                block.timestamp + _lockInDuration,
                _amount
            );
        }
    }


    /**
     * @dev Handles stakes withdrawn from flexible pools.
     * @dev If withdrawal done after pool.endTimestamp, then it will be automatically a complete withdrawal
     * @param _stakeInfo Storage Object of Stake Info.
     * @param _poolId Id of the pool.
     * @param _amount Amount to be withdrawn.
     * @return Total amount withdrawn, can be greater than _amount given, if withdrawal done after pool endTimestamp.
     */
    function flexiblePoolWithdraw(
        StakeInfo storage _stakeInfo,
        uint256 _poolId,
        uint256 _amount
    ) private returns(uint256) {
        uint256 _rewardAmount;

        /// @dev Withdrawal after pool endTimestamp
        if (block.timestamp > poolDetails[_poolId].endTimestamp) {
            _rewardAmount = calculateReward(
                _poolId,
                _stakeInfo.amount,
                poolDetails[_poolId].endTimestamp - _stakeInfo.startTimestamp
            );
            _amount = _stakeInfo.amount;
            _stakeInfo.isWithdrawn = true;
            unchecked { totalStakedAmount[msg.sender] = totalStakedAmount[msg.sender] - _amount; }
        
        /// @dev Withdrawal before pool endTimestamp
        } else {
            _rewardAmount = calculateReward(
                _poolId,
                _stakeInfo.amount,
                block.timestamp - _stakeInfo.startTimestamp
            );

            if (_stakeInfo.amount - _amount == 0) {
                _stakeInfo.isWithdrawn = true;
            } else {
                _stakeInfo.startTimestamp = block.timestamp;
                unchecked { _stakeInfo.amount = _stakeInfo.amount - _amount; }
            }
            
            unchecked { totalStakedAmount[msg.sender] = totalStakedAmount[msg.sender] - _amount; }
        }

        // Send rewards accumulated till now.
        emit RewardWithdrawn(
            msg.sender,
            _poolId,
            1,
            _rewardAmount,
            block.timestamp
        );
        // Transfer memag tokens for staking reward to user from stakingReserveAddress.
        memagToken.transferFrom(stakingReserveAddress, msg.sender, _rewardAmount);
        return _amount;
    }


    /**
     * @dev Handles stakes withdrawn from locked pools.
     * @param _stakeInfo Storage Object of Stake Info.
     * @param _poolId Id of the pool.
     * @param _stakeId Id of the stake to be withdrawn.
     * @return Stake Amount being withdrawn.
     */
    function lockedPoolWithdraw(
        StakeInfo storage _stakeInfo,
        uint256 _poolId,
        uint256 _stakeId
    ) private returns(uint256) {
        _stakeInfo.isWithdrawn = true;
        unchecked { totalStakedAmount[msg.sender] = totalStakedAmount[msg.sender] - _stakeInfo.amount; }

        uint256 endTimestamp;
        unchecked { endTimestamp = _stakeInfo.startTimestamp + poolDetails[_poolId].duration; }

        /// @dev Staking rewards are given only if withdrawal is done after endTimestamp.
        if(block.timestamp >= endTimestamp) {
            uint256 _rewardAmount = calculateReward(_poolId, _stakeInfo.amount, 0);
            if (_rewardAmount > 0) {
                require(
                    memagToken.balanceOf(stakingReserveAddress) >= _rewardAmount,
                    "Error: Insufficient memag funds in staking reserve wallet."
                );

                emit RewardWithdrawn(
                    msg.sender,
                    _poolId,
                    _stakeId,
                    _rewardAmount,
                    block.timestamp
                );
                // Transfer memag tokens for staking reward to user from stakingReserveAddress.
                memagToken.transferFrom(stakingReserveAddress, msg.sender, _rewardAmount);
            }
        }
        return _stakeInfo.amount;
    }
}