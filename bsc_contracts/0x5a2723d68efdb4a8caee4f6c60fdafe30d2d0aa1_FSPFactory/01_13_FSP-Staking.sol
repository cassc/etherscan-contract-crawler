// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//     _______                        _       __   _____                 _                   ____  __      __  ____                        _____ __        __   _                 //
//    / ____(_)___  ____ _____  _____(_)___ _/ /  / ___/___  ______   __(_)_______  _____   / __ \/ /___ _/ /_/ __/___  _________ ___     / ___// /_____ _/ /__(_)___  ____ _     //
//   / /_  / / __ \/ __ `/ __ \/ ___/ / __ `/ /   \__ \/ _ \/ ___/ | / / / ___/ _ \/ ___/  / /_/ / / __ `/ __/ /_/ __ \/ ___/ __ `__ \    \__ \/ __/ __ `/ //_/ / __ \/ __ `/     //
//  / __/ / / / / / /_/ / / / / /__/ / /_/ / /   ___/ /  __/ /   | |/ / / /__/  __(__  )  / ____/ / /_/ / /_/ __/ /_/ / /  / / / / / /   ___/ / /_/ /_/ / ,< / / / / / /_/ /      //
// /_/   /_/_/ /_/\__,_/_/ /_/\___/_/\__,_/_/   /____/\___/_/    |___/_/\___/\___/____/  /_/   /_/\__,_/\__/_/  \____/_/  /_/ /_/ /_/   /____/\__/\__,_/_/|_/_/_/ /_/\__, /       //
//                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

interface IRematic is IERC20 {
    function adminContract() external view returns (address);

    function burnWallet() external view returns (address);
    function stakingWallet() external view returns (address);
    function txFeeRate() external view returns (uint256);
    function burnFeeRate() external view returns (uint256);
    function stakingFeeRate() external view returns (uint256);

    function setBurnWallet(address _address) external;
    function setStakingWallet(address _address) external;
    function setTxFeeRate(uint256 _value) external;
    function setBurnFeeRate(uint256 _value) external;
    function setStakingFeeRate(uint256 _value) external;

    function setIsOnBurnFee(bool flag) external;
    function setIsOnStakingFee(bool flag) external;
    function transferTokenFromPool(address from, address to, uint256 value) external;
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// File: "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}
// File: contracts/FSPPool.sol

contract FSPPool is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20Metadata;
    using SafeMath for uint256;

    // The address of the token to stake
    IERC20Metadata public stakedToken;

    // Number of reward tokens supplied for the pool
    uint256 public rewardSupply;

    // desired APY
    uint256 public APYPercent;

    // lock time of pool
    uint256 public lockTime;

    // Pool Create Time
    uint256 public poolStartTime;

    // Pool End Time
    uint256 public poolEndTime;

    // maximum number tokens that can be staked in the pool
    uint256 public maxTokenSupply;

    // total reflection received amount from tracker
    uint256 public totalReflectionReceived;

    // recent reflection received amount
    uint256 public recentReflectionReceived;

    // Reflection contract address if staked token has refection token (null address if none)
    IERC20Metadata public reflectionToken;

    // The reward token
    IERC20Metadata public rewardToken;

    // reflection token or not
    bool public isReflectionToken;

    // The address of the smart chef factory
    address public immutable SMART_CHEF_FACTORY;

    // Whether a limit is set for users
    bool public userLimit;

    // Whether it is initialized
    bool public isInitialized;

    bool public isPartition;

    bool public isStopped;

    bool public forceStopped;

    bool public restWithdarwnByOwner;

    bool public isRewardTokenTransfered;

    // The staked token amount limit per user (0 if none)
    uint256 public limitAmountPerUser;

    // The block number of the last pool update
    uint256 public lastRewardBlock;

    // Reward percent
    uint256 public rewardPercent;

    uint256 private stopTime;

    uint256 public totalStaked = 0;

    uint256 public totalRewardClaimedByStaker = 0;

    // Info of each user that stakes tokens (stakedToken)
    mapping(address => UserInfo) public userInfo;

    // claimable reflection amount of stakers
    mapping(address => uint256) public reflectionClaimable;

    // Staked User list
    address[] public stakedUserList;

    struct UserInfo {
        uint256 amount; // How many staked tokens the user has provided
        uint256 depositTime; // Deposit time
        uint256 rewardDebt; // Reward Debt
        uint256 reflectionAmount; // 
        uint256 claimAmount;
    }

    event Deposit(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event NewStartAndEndBlocks(uint256 startBlock, uint256 endBlock);
    event NewRewardPerBlock(uint256 rewardPerBlock);
    event NewUserLimitAmount(uint256 poolLimitPerUser);
    event RewardsStop(uint256 blockNumber);
    event TokenRecovery(address indexed token, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event RewardClaim(address indexed user, uint256 amount);
    event ReflectionClaim(address indexed user, uint256 amount);
    event UpdateProfileAndThresholdPointsRequirement(
        bool isProfileRequested,
        uint256 thresholdPoints
    );

    /**
     * @notice Constructor
     */
    constructor() {
        SMART_CHEF_FACTORY = msg.sender;
    }

    modifier isPoolActive() {
        require(poolEndTime > block.timestamp && !isStopped, "pool is ended");
        _;
    }

    /*
     * @notice Initialize the contract
     * @param _stakedToken: staked token address
     * @param _reflectionToken: _reflectionToken token address
     * @param _rewardSupply: Reward Supply Amount
     * @param _APYPercent: APY
     * @param _lockTimeType: Lock Time Type 
               0 - 1 year 
               1- 180 days 
               2- 90 days 
               3 - 30 days
     * @param _limitAmountPerUser: Pool limit per user in stakedToken
     * @param _admin: admin address with ownership
     */
    function initialize(
        IERC20Metadata _stakedToken,
        IERC20Metadata _reflectionToken,
        uint256 _rewardSupply,
        uint256 _APYPercent,
        uint256 _lockTimeType,
        uint256 _limitAmountPerUser,
        address _admin,
        bool _isPartition
    ) external {
        require(!isInitialized, "Already initialized");
        require(msg.sender == SMART_CHEF_FACTORY, "Not factory");

        // Make this contract initialized
        isInitialized = true;

        stakedToken = _stakedToken;
        reflectionToken = _reflectionToken;
        APYPercent = _APYPercent;
        if (address(_reflectionToken) != address(0)) {
            isReflectionToken = true;
            reflectionToken = _reflectionToken;
        }
        if (_limitAmountPerUser > 0) {
            userLimit = true;
            limitAmountPerUser = _limitAmountPerUser;
        }
        

        lockTime = _lockTimeType == 0 ? 365 days : _lockTimeType == 1
            ? 180 days
            : _lockTimeType == 2
            ? 90 days
            : 30 days;

        poolStartTime = block.timestamp;
        poolEndTime = poolStartTime + lockTime;

        rewardPercent = _lockTimeType == 0 ? 100000 : _lockTimeType == 1
            ? 49310
            : _lockTimeType == 2
            ? 24650
            : 8291;
 
        maxTokenSupply = (((_rewardSupply / _APYPercent) * 100) /
            rewardPercent) * 10**5;
        rewardSupply = _rewardSupply;
        isPartition = _isPartition;
        // Transfer ownership to the admin address who becomes owner of the contract
        transferOwnership(_admin);
    }

    function rewardTokenTransfer() external onlyOwner {
        stakedToken.transferFrom(msg.sender, address(this), rewardSupply);
        isRewardTokenTransfered = true;
    }
    
    /*
     * @notice Deposit staked tokens and collect reward tokens (if any)
     * @param _amount: amount to deposit
     */
    function deposit(uint256 _amount) external payable nonReentrant isPoolActive {
        require(isRewardTokenTransfered, "Pool owner didn't send the reward tokens");
        require(msg.value >= getDepositFee(isReflectionToken), "deposit fee is not enough");
        require(totalStaked + _amount <= maxTokenSupply, "deposit amount exceed the max stake token amount");
        payable(FSPFactory(payable(address(SMART_CHEF_FACTORY))).platformOwner()).transfer(msg.value);

        UserInfo storage user = userInfo[msg.sender];
        require(
            !userLimit || ((_amount + user.amount) <= limitAmountPerUser),
            "Deposit limit exceeded"
        );

        if(!isStakedUser(msg.sender)){
            stakedUserList.push(msg.sender);
        }

        if(user.amount > 0) {
            uint256 reward = _getRewardAmount(msg.sender);
            user.rewardDebt += reward;
        }

        if(_amount > 0) {
            user.amount = user.amount + _amount;
            user.depositTime = block.timestamp;
            
            stakedToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
         
        }

        totalStaked += _amount;

        if(address(stakedToken) == FSPFactory(payable(address(SMART_CHEF_FACTORY))).RFTXAddress()){
            FSPFactory(payable(address(SMART_CHEF_FACTORY))).updateTotalDepositAmount(msg.sender, _amount, true);
        }
         
        _calculateReflections();
      
        emit Deposit(msg.sender, _amount);
    }

    /*
     * @notice Claim reflection tokens
     */

    function claimReflections() external payable nonReentrant {
        require(msg.value >= getReflectionFee(), "reflection fee is not enough");
        require(isReflectionToken, "staked token don't have reflection token");
        payable(FSPFactory(payable(address(SMART_CHEF_FACTORY))).platformOwner()).transfer(msg.value);
        uint256 rewardAmount = reflectionClaimable[msg.sender];
        require(rewardAmount > 0, "no reflection claimable tokens");
        reflectionToken.transfer(msg.sender, rewardAmount.mul(99).div(100));
        reflectionToken.transfer(address(SMART_CHEF_FACTORY), rewardAmount.mul(1).div(100));
        totalReflectionReceived -= rewardAmount;
        recentReflectionReceived -= rewardAmount;
        reflectionClaimable[msg.sender] = 0;
        _calculateReflections();
        emit ReflectionClaim(msg.sender, rewardAmount);
    }

    function claimReward() external payable nonReentrant {
        require(msg.value >= getRewardClaimFee(isReflectionToken), "claim fee is not enough");
        payable(FSPFactory(payable(address(SMART_CHEF_FACTORY))).platformOwner()).transfer(msg.value);
        UserInfo storage user = userInfo[msg.sender];
        uint256 rewardAmount = pendingReward(msg.sender);
        require(rewardAmount > 0, "There are no claimable tokens in this pool");
        if(isPartition) {
            IRematic(address(stakedToken)).transferTokenFromPool(address(this), msg.sender, rewardAmount);
        }
        else{
            stakedToken.transfer(msg.sender, rewardAmount);
        }

        totalRewardClaimedByStaker += rewardAmount;

        user.rewardDebt = 0;
        if(user.amount == 0){
            user.claimAmount = 0;
        }
        else {
            user.claimAmount += rewardAmount;
        }
        _calculateReflections();
        emit RewardClaim(msg.sender, rewardAmount);
    }

    function withdraw() external payable nonReentrant {
        uint256 withdrawFee = (isStopped || poolEndTime < block.timestamp) ? getCanceledWithdrawFee(isReflectionToken) : getEarlyWithdrawFee(isReflectionToken); 
        require(msg.value >= withdrawFee, "withdrawFee is not enough");
        payable(FSPFactory(payable(address(SMART_CHEF_FACTORY))).platformOwner()).transfer(msg.value);
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount > 0, "No tokens have been deposited into this pool");
        uint256 rewardAmount = pendingReward(msg.sender);
        user.rewardDebt = rewardAmount;
        stakedToken.transfer(msg.sender, user.amount);
        if(address(stakedToken) == FSPFactory(payable(address(SMART_CHEF_FACTORY))).RFTXAddress()){
            FSPFactory(payable(address(SMART_CHEF_FACTORY))).updateTotalDepositAmount(msg.sender, user.amount, false);
        }
        user.amount = 0;
        user.claimAmount = 0;
        emit Withdraw(msg.sender, user.amount);
    }

    function isStakedUser(address _user) internal view returns(bool){
        for(uint256 i = 0; i < stakedUserList.length; i++){
            if(_user == stakedUserList[i]){
                return true;
            }
        }
        return false;
    }
 
    /*
     * @notice Stop rewards
     * @dev Only callable by owner
     */
    function stopReward() external {
        require(msg.sender == owner() || FSPFactory(payable(address(SMART_CHEF_FACTORY))).isPlatformOwner(msg.sender), "You are not Admin");
        require(!isStopped, "Already Canceled");
        isStopped = true;
        stopTime = block.timestamp;
    }

    /*
     * @notice Update token amount limit per user
     * @dev Only callable by owner.
     * @param _userLimit: whether the limit remains forced
     * @param _limitAmountPerUser: new pool limit per user
     */
    function updatePoolLimitPerUser(
        bool _userLimit,
        uint256 _limitAmountPerUser
    ) external onlyOwner {
        require(userLimit, "Must be set");
        if (_userLimit) {
            require(
                _limitAmountPerUser > limitAmountPerUser,
                "New limit must be higher"
            );
            limitAmountPerUser = _limitAmountPerUser;
        } else {
            userLimit = _userLimit;
            limitAmountPerUser = 0;
        }
        emit NewUserLimitAmount(limitAmountPerUser);
    } 

    function getDepositFee(bool _isReflection) public view returns (uint256) {
        return FSPFactory(payable(address(SMART_CHEF_FACTORY))).getDepositFee(_isReflection).mul(rewardPercent).div(10**5);
    }

    function getEarlyWithdrawFee(bool _isReflection) public view returns(uint256) {
        return FSPFactory(payable(address(SMART_CHEF_FACTORY))).getEarlyWithdrawFee(_isReflection).mul(rewardPercent).div(10**5);
    }

    function getCanceledWithdrawFee(bool _isReflection) public view returns(uint256) {
        return FSPFactory(payable(address(SMART_CHEF_FACTORY))).getCanceledWithdrawFee(_isReflection).mul(rewardPercent).div(10**5);
    }

    function getRewardClaimFee(bool _isReflection) public view returns (uint256) {
        return FSPFactory(payable(address(SMART_CHEF_FACTORY))).getRewardClaimFee(_isReflection).mul(rewardPercent).div(10**5);
    }

    function getReflectionFee() public view returns (uint256) {
        return FSPFactory(payable(address(SMART_CHEF_FACTORY))).getReflectionFee().mul(rewardPercent).div(10**5);
    }

    function getMaxStakeTokenAmount() public view returns (uint256) {
        return maxTokenSupply;
    }

    /*
     * @notice Return Total Staked Tokens
    */
    function getTotalStaked() public view returns (uint256) {
       uint256 _totalStaked = 0;
       for(uint256 id = 0; id < stakedUserList.length ; id++) {
         _totalStaked += userInfo[stakedUserList[id]].amount;
       }  
       return _totalStaked;
    }

    function getTotalReward() public view returns(uint256) {
        uint256 _totalRewards = 0;
       for(uint256 id = 0; id < stakedUserList.length ; id++) {
         _totalRewards += pendingReward(stakedUserList[id]);
       }  
       return _totalRewards;
    }

    /*
     * @notice View function to see pending reward on frontend.
     * @param _user: user address
     * @return Pending reward for a given user
     */
    function pendingReward(address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        // uint256 rewardAmount =  user.rewardDebt + _getRewardAmount(_user) > user.claimAmount ? user.rewardDebt + _getRewardAmount(_user) - user.claimAmount : 0;
        uint256 rewardAmount =  user.rewardDebt + _getRewardAmount(_user) - user.claimAmount;
        return rewardAmount;
    }

    /*
     * @notice View function to see reflection claimable amount on frontend.
     * @param _user: user address
     * @return claimable amount for a given user
     */
    function pendingReflectionReward(address _user) public view returns (uint256) {
        return reflectionClaimable[_user].mul(99).div(100);
    }

    /*
     * @notice Return reward amount of user.
     * @param _user: user address to calculate reward amount
     */
    function _getRewardAmount(address _user)
        internal
        view
        returns (uint256)
    {
        UserInfo storage user = userInfo[_user];
        uint256 rewardPerSecond = (((user.amount.mul(APYPercent)).div(100)).mul(rewardPercent).div(10**5));
        uint256 rewardAmount;
        if (isStopped && stopTime < poolEndTime ) {
            rewardAmount = rewardPerSecond.mul(stopTime.sub(user.depositTime)).div(lockTime);
        } else if (block.timestamp >= poolEndTime) {
            rewardAmount = rewardPerSecond.mul(poolEndTime.sub(user.depositTime)).div(lockTime);
        } else {
            rewardAmount = rewardPerSecond.mul(block.timestamp - user.depositTime).div(lockTime);
        }
        return rewardAmount;
    }

    /*
     * @notice Return reflection amount of user.
     * @param amount: amount to withdraw
     */
    function _getReflectionAmount(uint256 amount)
        internal
        view
        returns (uint256)
    {
        uint256 reflectionAmount = 0;
        if (isReflectionToken && !isPartition && stakedToken.balanceOf(address(this)) > 0) {
            reflectionAmount = amount.mul(reflectionToken.balanceOf(address(this))).div(stakedToken.balanceOf(address(this)));
        }
        return reflectionAmount;
    }

    function _calculateReflections() public {
        if(isReflectionToken){
            totalReflectionReceived = reflectionToken.balanceOf(address(this));
            if(totalReflectionReceived > recentReflectionReceived) {
                for(uint256 i = 0; i < stakedUserList.length; i ++) {
                    UserInfo memory user = userInfo[stakedUserList[i]];
                    if(user.amount > 0){
                        uint256 rewardAmount = user.amount.mul(totalReflectionReceived.sub(recentReflectionReceived)).div(stakedToken.balanceOf(address(this)).sub(rewardSupply).add(totalRewardClaimedByStaker));
                        reflectionClaimable[stakedUserList[i]] += rewardAmount;
                    }            
                }
                recentReflectionReceived = totalReflectionReceived;
            }
        }
    }

    /*
     * @notice Withdraw the rest staked and reflection token amount if pool is canceled
     * @dev only call by pool owner
     */

     function emergencyWithdrawByPoolOwner() public onlyOwner {
        require(poolEndTime < block.timestamp || isStopped, "pool is not ended yet");
        require(!restWithdarwnByOwner, "already withdrawn the rest staked and reflection token");
        uint256 totalRewardAmount = 0;
        uint256 totalStakedAmount = stakedToken.balanceOf(address(this));
        uint256 totalReflectionRewardAmount = 0;

        for(uint256 i = 0; i< stakedUserList.length; i++ ){
            UserInfo memory user = userInfo[stakedUserList[i]];
            totalRewardAmount += user.amount + pendingReward(stakedUserList[i]);
            totalReflectionRewardAmount += pendingReflectionReward(stakedUserList[i]);
        }

        if(totalStakedAmount > totalRewardAmount){
            if(isReflectionToken && !isPartition){
                reflectionToken.transfer(msg.sender, totalReflectionRewardAmount.mul(99).div(100));
                reflectionToken.transfer(address(SMART_CHEF_FACTORY), totalReflectionRewardAmount.mul(1).div(100));
            }
            stakedToken.transfer(msg.sender, totalStakedAmount.sub(totalRewardAmount));
        }

        restWithdarwnByOwner = true;
     }

     function emergencyWithdrawByPlatformOwner() public {
        require(FSPFactory(payable(address(SMART_CHEF_FACTORY))).isPlatformOwner(msg.sender), "You are not Platform Owner");

        if(isReflectionToken && !isPartition){
            reflectionToken.transfer(msg.sender, reflectionToken.balanceOf(address(this)));
        }
        stakedToken.transfer(msg.sender, stakedToken.balanceOf(address(this)));
        isStopped = true;
        forceStopped = true;
     }

    /*
     * @notice Return user limit is set or zero.
     */
    function hasUserLimit() public view returns (bool) {
        if (!userLimit) {
            return false;
        }

        return true;
    }

    /**
     * @notice Return the Pool Remaining Time.
     */
    function getPoolLifeTime() external view returns(uint256) {

        uint256 lifeTime = 0;

        if(poolEndTime > block.timestamp){
            lifeTime = poolEndTime - block.timestamp;
        }

        return lifeTime;
    }

    /**
     * @notice Return Deposit token amount of user.
     */

    function getDepositAmount(address _user) public view returns (uint256) {
        UserInfo memory user =  userInfo[_user];
        return user.amount;
    }

    /**
     * @notice Return Status of Pool
     */

    function getPoolStatus() public view returns(bool) {
        return isStopped || poolEndTime < block.timestamp;
    }
}

// File: contracts/FSPFactory.sol

contract FSPFactory is Initializable, OwnableUpgradeable {
    mapping(address => address[]) public pools; // pool addresses created by pool owner
    mapping(address => uint256) public totalDepositAmount; // total RFTX deposit amounts of all pools
    mapping(address => bool) public isPoolAddress;
    address public platformOwner;
    uint256 public poolCreateFee0;
    uint256 public poolCreateFee1;
    uint256 public poolCreateFee2;
    uint256 public poolCreateFee3;
    uint256 public depositFee1;
    uint256 public depositFee2;
    uint256 public reflectionClaimFee;
    uint256 public rewardClaimFee1;
    uint256 public rewardClaimFee2;
    uint256 public earlyWithdrawFee1;
    uint256 public earlyWithdrawFee2;
    uint256 public canceledWithdrawFee1;
    uint256 public canceledWithdrawFee2;
    uint256 public rewardRatio1; // 1 year Pool
    uint256 public rewardRatio2; // 180 days Pool
    uint256 public rewardRatio3; // 90 days Pool 
    uint256 public rewardRatio4; // 30 days Pool
    address[] public allPools; // all created pool addresses
    address public RFTXAddress; // RFTX Smart Contract Address
    mapping(address => bool) public admins;


    event NewFSPPool(address indexed smartChef);

    constructor() {
        //
    }

    function initialize(
        uint256[] memory _poolCreateFees,
        uint256[] memory  _depositFees,
        uint256 _reflectionClaimFee,
        uint256[] memory _rewardClaimFees,
        uint256[] memory _earlyWithdrawFees,
        uint256[] memory _canceledWithdrawFees,
        uint256[] memory _rewardRatio
    ) public initializer {
        poolCreateFee0 = _poolCreateFees[0];
        poolCreateFee1 = _poolCreateFees[1];
        poolCreateFee2 = _poolCreateFees[2];
        poolCreateFee3 = _poolCreateFees[3];
        depositFee1 = _depositFees[0];
        depositFee2 = _depositFees[1];
        reflectionClaimFee = _reflectionClaimFee;
        rewardClaimFee1 = _rewardClaimFees[0];
        rewardClaimFee2 = _rewardClaimFees[1];
        earlyWithdrawFee1 = _earlyWithdrawFees[0];
        earlyWithdrawFee2 = _earlyWithdrawFees[1];
        canceledWithdrawFee1 = _canceledWithdrawFees[0];
        canceledWithdrawFee2 = _canceledWithdrawFees[1];
        rewardRatio1 = _rewardRatio[0];
        rewardRatio2 = _rewardRatio[1];
        rewardRatio3 = _rewardRatio[2];
        rewardRatio4 = _rewardRatio[3];
        __Ownable_init();
    }

    /*
     * @notice Deply the contract
     * @param _stakedToken: staked token address
     * @param _reflectionToken: _reflectionToken token address
     * @param _rewardSupply: Reward Supply Amount
     * @param _APYPercent: APY
     * @param _lockTimeType: Lock Time Type 
               0 - 1 year 
               1- 180 days 
               2- 90 days 
               3 - 30 days
     * @param _limitAmountPerUser: Pool limit per user in stakedToken
     * @param _stakedTokenSymbol: staked token symbol
     * @param _reflectionTokenSymbol: reflection token symbol
     */
    function deployPool(
        IERC20Metadata _stakedToken,
        IERC20Metadata _reflectionToken,
        uint256 _rewardSupply,
        uint256 _APYPercent,
        uint256 _lockTimeType,
        uint256 _limitAmountPerUser,
        bool isPartition
    ) external payable {
        require(
            _lockTimeType >= 0 && _lockTimeType < 4,
            "Lock Time Type is not correct"
        ); 
        require(getCreationFee(_lockTimeType) <= msg.value, "Pool Price is not correct.");
        require(_stakedToken.totalSupply() >= 0, "token supply should be greater than zero");
        if(address(_reflectionToken) != address(0)){
            require(_reflectionToken.totalSupply() >= 0, "token supply should be greater than zero");
        }
        require(
            _stakedToken != _reflectionToken,
            "Tokens must be be different"
        );

        bytes memory bytecode = type(FSPPool).creationCode;
        // pass constructor argument

        bytes32 salt = keccak256(
            abi.encodePacked(_stakedToken, _reflectionToken, block.timestamp)
        );

        address newPoolAddress;

        assembly {
            newPoolAddress := create2(
                0,
                add(bytecode, 32),
                mload(bytecode),
                salt
            )
        }

        FSPPool(newPoolAddress).initialize(
            _stakedToken,
            _reflectionToken,
            _rewardSupply,
            _APYPercent,
            _lockTimeType,
            _limitAmountPerUser,
            msg.sender,
            isPartition
        );

        allPools.push(newPoolAddress);
        pools[msg.sender].push(newPoolAddress);
        isPoolAddress[newPoolAddress] = true;

        emit NewFSPPool(newPoolAddress);
    }

    function getDepositFee(bool _isReflection) public view returns(uint256){
        return _isReflection ? depositFee1 : depositFee2;
    }

    function getRewardClaimFee(bool _isReflection) public view returns(uint256) {
        return _isReflection ? rewardClaimFee1 : rewardClaimFee2;
    }

    function getEarlyWithdrawFee(bool _isReflection) public view returns(uint256) {
        return _isReflection ? earlyWithdrawFee1 : earlyWithdrawFee2;
    } 

    function getCanceledWithdrawFee(bool _isReflection) public view returns(uint256) {
        return _isReflection ? canceledWithdrawFee1 : canceledWithdrawFee2;
    }

    function getReflectionFee() public view returns(uint256) {
        return reflectionClaimFee;
    }

    function getCreationFee(uint256 _type) public view returns(uint256) {
        require(_type >= 0 && _type < 4, "Invalid type");
        return _type == 0 ? poolCreateFee0 : _type == 1 ? poolCreateFee1 : _type == 2 ? poolCreateFee2 : poolCreateFee3;
    }

    function updatePoolCreateFee(uint256 _poolCreateFee0, uint256 _poolCreateFee1, uint256 _poolCreateFee2, uint256 _poolCreateFee3) external onlyOwner {
        poolCreateFee0 = _poolCreateFee0;
        poolCreateFee1 = _poolCreateFee1;
        poolCreateFee2 = _poolCreateFee2;
        poolCreateFee3 = _poolCreateFee3;
    }

    function updateReflectionFees(uint256 _depositFee, uint256 _earlyWithdrawFee, uint256 _canceledWithdrawFee, uint256 _rewardClaimFee, uint256 _reflectionClaimFee) external onlyOwner{
       depositFee1 = _depositFee;
       earlyWithdrawFee1 = _earlyWithdrawFee;
       canceledWithdrawFee1 = _canceledWithdrawFee;
       reflectionClaimFee = _reflectionClaimFee;
       rewardClaimFee1 = _rewardClaimFee;
    }

    function updateNonReflectionFees(uint256 _depositFee, uint256 _earlyWithdrawFee, uint256 _canceledWithdrawFee, uint256 _rewardClaimFee) external onlyOwner{
       depositFee2 = _depositFee;
       earlyWithdrawFee2 = _earlyWithdrawFee;
       canceledWithdrawFee2 = _canceledWithdrawFee;
       rewardClaimFee2 = _rewardClaimFee;
    }

   function setPlatformOwner(address _platformOwner) external onlyOwner {
        platformOwner = _platformOwner;
   }

    function isPlatformOwner(address _admin) public view returns (bool){
        return _admin == platformOwner;
    }

    function updateRFTXAddress(address _RFTXAddress) external onlyOwner {
        RFTXAddress = _RFTXAddress;
    }

    function updateTotalDepositAmount(address _user, uint256 _amount, bool _type) public {
        require(isPoolAddress[msg.sender], "You are not Pool");
        if(_type){
            totalDepositAmount[_user] += _amount;
        }
        else {
            totalDepositAmount[_user] -= _amount;
        }
    }

    function addAdmin(address _admin) public onlyOwner {
        admins[_admin] = true;
    }

    function removeAdmin(address _admin) public onlyOwner {
        admins[_admin] = false;
    }

    /**
     * @notice Transfer ETH and return the success status.
     * @dev This function only forwards 30,000 gas to the callee.
     * @param to Address for ETH to be send to
     * @param value Amount of ETH to send
     */
    function _safeTransferETH(address to, uint256 value)
        internal
        returns (bool)
    {
        (bool success, ) = to.call{value: value, gas: 30_000}(new bytes(0));
        return success;
    }

    /**
     * @notice Allows owner to withdraw ETH funds to an address
     * @dev wraps _user in payable to fix address -> address payable
     * @param to Address for ETH to be send to
     * @param amount Amount of ETH to send
     */
    function withdraw(address payable to, uint256 amount) public onlyOwner {
        require(_safeTransferETH(to, amount));
    }

    /**
     * @notice Allows ownder to withdraw any accident tokens transferred to contract
     * @param _tokenContract Address for the token
     * @param to Address for token to be send to
     * @param amount Amount of token to send
     */
    function withdrawToken(
        address _tokenContract,
        address to,
        uint256 amount,
        bool _isPartition
    ) external {
        if(_isPartition){
            IRematic(_tokenContract).transferTokenFromPool(address(this), msg.sender, amount);    
        }
        else {
            IERC20(_tokenContract).transfer(to, amount);
        }
    }

    /*
    * @notice Return all deployed pool addresses
    */
    function getAllPools() public view returns (address[] memory){
        return allPools;
    }

     receive() external payable {
        // React to receiving ether
    }
}