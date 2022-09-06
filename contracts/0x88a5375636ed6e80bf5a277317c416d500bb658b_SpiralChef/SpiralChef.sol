/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//Address (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol)

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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
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
// Context (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol) 
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// Ownable (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol)

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0xdead));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0xdead), "Ownable: new owner is the zero address");
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
}



// ReentrancyGuard (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
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
     * by making the `nonReentrant` function external, and making it call a
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
								//
// IERC20 (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol)
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}


// SafeERC20 (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/SafeERC20.sol)
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
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
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
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}



// Staking contract (this is forked, rewritten for 0.8.x, gas optimized and functionally modified from GooseDefi's MasterchefV2, codebase is battle tested countless times and is totally safe).
// You're free to publish, distribute and modify a copy of this contract as you want. Please mention where it's from though. 
// Have fun reading it :) ( Original contract : https://github.com/goosedefi/goose-contracts/blob/master/contracts/MasterChefV2.sol). 
// RWT is a placeholder name for the upcoming reward token
contract SpiralChef is Ownable, ReentrancyGuard{
    using SafeERC20 for IERC20;
	
    // Info of each user.
    struct UserInfo {
        uint256 amount;             // How many LP tokens the user has provided.    //
        uint256[] rewardDebt;		    // Reward debt. See explanation below.            
        uint256[] claimableRWT;
        
    }
    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;             // Address of LP token contract.
        uint64 allocPoint;          // How many allocation points assigned to this pool. 
        uint64 lastRewardBlock;     // Last block number that rewards distribution occurs.
        uint256[] accRwtPerShare;     // Accumulated RWTs per share, times 1e30.   
    }

  
    IERC20 public spiral;
	// The reward tokens 
	IERC20[] public rwt;
    address public router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
	uint256[] public perBurn;
    uint256[] public maxBurn;
    uint256[] public rwtPerBlock;
    mapping(address => mapping(uint256 => uint256)) public userBurnt;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;
    // The block number when the farm starts mining starts.
    uint256 public startBlock;
    uint256 public lockUntil;
	bool public isEmergency;
	event RewardTokenSet(IERC20 indexed spiralddress, uint256 indexed rwtPerBlock, uint256 timestamp);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event UpdateEmissionRate(address indexed user, uint256 rwtPerBlock);
    event Burn(address indexed user, uint256 burnAmount);
	event Emergency(uint256 timestamp, bool ifEmergency);
    mapping(IERC20 => bool) public poolExistence;
    mapping(IERC20 => bool) public rwtExistence;

    modifier nonDuplicated(IERC20 _lpToken) {
        require(poolExistence[_lpToken] == false, "nonDuplicated: duplicated");
        _;
    }

    modifier nonDuplicatedRWT(IERC20 _rwtToken) {
        require(rwtExistence[_rwtToken] == false, "nonDuplicated: duplicated");
        _;
    }
    
    modifier onlyEmergency {
        require(isEmergency == true, "onlyEmergency: Emergency use only!");
        _;
    }
    mapping(address => bool) public authorized;
    modifier onlyAuthorized {
        require(authorized[msg.sender] == true, "onlyAuthorized: address not authorized");
        _;
    }
    constructor(IERC20 _spiral) {
        spiral = _spiral;
		startBlock = type(uint256).max;
        add(1, _spiral, false);
    }

//--------------------------------------------------------VIEW FUNCTIONS --------------------------------------------------------
    // Return number of pools
	function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }
    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return (_to - _from);
    }

    // View function to see pending rewards on frontend.
    function pendingRewards(uint256 _pid, address _user) external view returns (uint256[] memory) {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        uint256 amount = user.amount;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        uint256[] memory accRwtPerShare = pool.accRwtPerShare;
        uint256[] memory PendingRWT = new uint256[](rwt.length);
        if (amount != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            for (uint i=0; i < rwt.length; i++) {
                uint256 rwtReward = multiplier * rwtPerBlock[i] * pool.allocPoint / totalAllocPoint;
                accRwtPerShare[i] = accRwtPerShare[i] + rwtReward * 1e30 / lpSupply;
                if (i < user.rewardDebt.length){
                    PendingRWT[i] = (amount * accRwtPerShare[i] / 1e30) - user.rewardDebt[i] + user.claimableRWT[i];
                }
                else {
                    PendingRWT[i] = (amount * accRwtPerShare[i] / 1e30);
                }
            }
        }
        return(PendingRWT);
    }

    function poolAccRew(uint256 _pid) external view returns (uint256[] memory) {
        uint256[] memory _poolAccRew = poolInfo[_pid].accRwtPerShare;
        return(_poolAccRew);
    }

    function userRewDebt(uint256 _pid, address _user) external view returns (uint256[] memory) {
        uint256[] memory _userRewDebt = userInfo[_pid][_user].rewardDebt;
        return(_userRewDebt);
    }

    function userClaimable(uint256 _pid, address _user) external view returns (uint256[] memory) {
        uint256[] memory _userClaimable = userInfo[_pid][_user].claimableRWT;
        return(_userClaimable);
    }

    function userBurntForNum(uint256 burnNum, address user) external view returns (uint256) {
        return(userBurnt[user][burnNum]);
    } 

    function userAmount(uint256 _pid, address user) external view returns (uint256) {
        return(userInfo[_pid][user].amount);
    }

//--------------------------------------------------------PUBLIC FUNCTIONS --------------------------------------------------------
    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; pid++) {
            updatePool(pid);
        }
    }
    
    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = uint64(block.number);
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        if(rwt.length > 0) {
            uint256[] memory _rwtPerBlock = rwtPerBlock;
            PoolInfo memory _pool = pool;
            for (uint i=0; i < rwt.length; i++) {
                uint256 rwtReward = multiplier * _rwtPerBlock[i] * _pool.allocPoint / totalAllocPoint;
                pool.accRwtPerShare[i] = _pool.accRwtPerShare[i] + rwtReward * 1e30 / lpSupply;
            }
        }
        pool.lastRewardBlock = uint64(block.number);
    }

    function burnFromWallet(uint256 burnAmount, uint256 burnNum) public nonReentrant {
        require(burnAmount > 0);
        uint256 burnspiralmount = burnAmount * perBurn[burnNum];
        userBurnt[msg.sender][burnNum] += burnAmount;
        require(userBurnt[msg.sender][burnNum] <= maxBurn[burnNum]);
        spiral.safeTransferFrom(msg.sender, address(0xdead), burnspiralmount);
        emit Burn(msg.sender, burnspiralmount);
    }

    function burnFromStake(uint256 burnAmount, uint256 burnNum) public nonReentrant {
        uint256 burnspiralmount = burnAmount * perBurn[burnNum];
        uint256 postAmount = userInfo[0][msg.sender].amount - burnspiralmount;
        require(postAmount >= 0 && burnspiralmount > 0);
        updatePool(0);
        _addToClaimable(0, msg.sender);
        userInfo[0][msg.sender].amount = postAmount;
        if (rwt.length != 0) {
            uint256[] memory _poolAccRew = poolInfo[0].accRwtPerShare;
            for (uint i = 0; i < rwt.length; i++) {
                userInfo[0][msg.sender].rewardDebt[i] = postAmount * _poolAccRew[i] / 1e30;
            }
        }
        userBurnt[msg.sender][burnNum] += burnAmount;
        require(userBurnt[msg.sender][burnNum] <= maxBurn[burnNum]);
        spiral.safeTransfer(address(0xdead), burnspiralmount);
        emit Burn(msg.sender, burnspiralmount);
    }

    // Deposit tokens for rewards.
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
        _deposit(msg.sender, _pid, _amount);
    }

    function claimRWT(uint256 _pid, uint256 _tokenID) public nonReentrant {
        require(_tokenID < rwt.length);
        updatePool(_pid);
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256[] memory _poolAccRew = poolInfo[_pid].accRwtPerShare;
        uint256 pending;
        if(user.rewardDebt.length <= _tokenID) {
            pending = (user.amount * _poolAccRew[_tokenID] / 1e30);
            uint diff = _tokenID-user.rewardDebt.length;
            if (diff > 0) {
                for (uint i = 0; i<diff; i++){
                    user.claimableRWT.push();
                    user.rewardDebt.push();
                }
            }
            user.claimableRWT.push();
            user.rewardDebt.push(pending);
        }
        else {
            pending = (user.amount * _poolAccRew[_tokenID] / 1e30) + user.claimableRWT[_tokenID] - user.rewardDebt[_tokenID];
            user.claimableRWT[_tokenID] = 0;
            user.rewardDebt[_tokenID] = user.amount * _poolAccRew[_tokenID] / 1e30;
        }
        require(pending > 0); 
        safeRWTTransfer(_tokenID, msg.sender, pending);

    }

    function claimAllRWT(uint256 _pid) public nonReentrant {
        updatePool(_pid);
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256[] memory _poolAccRew = poolInfo[_pid].accRwtPerShare;
        UserInfo memory _user = user;
        if(rwt.length != 0) {
           for (uint i=0; i < _user.rewardDebt.length; i++){
                uint256 pending = (_user.amount * _poolAccRew[i] / 1e30) - _user.rewardDebt[i] + _user.claimableRWT[i];
                if (pending > 0) {
                    user.claimableRWT[i] = 0;
                    user.rewardDebt[i] = _user.amount * _poolAccRew[i] / 1e30;
                    safeRWTTransfer(i, msg.sender, pending);
                }
            }
            if (_user.rewardDebt.length != rwt.length) {
                for (uint i = _user.rewardDebt.length; i < rwt.length; i++) {
                    uint256 pending = (_user.amount * _poolAccRew[i] / 1e30);
                    user.claimableRWT.push();
                    user.rewardDebt.push(_user.amount * _poolAccRew[i] / 1e30);
                    if(pending > 0) {
                        safeRWTTransfer(i, msg.sender, pending);
                    }
                }
            }
        }
    }
    // Withdraw unlocked tokens.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        require(block.timestamp > lockUntil);
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 postAmount = user.amount - _amount;
        require(postAmount >= 0 && _amount > 0, "withdraw: not good");
        updatePool(_pid);
        if (rwt.length > 0) {
                _addToClaimable(_pid, msg.sender);
                uint256[] memory _poolAccRew = poolInfo[_pid].accRwtPerShare;
                for (uint i=0; i < rwt.length; i++){
                    if (user.claimableRWT[i] > 0) {
                        safeRWTTransfer(i, msg.sender, user.claimableRWT[i]);
                        user.claimableRWT[i] = 0;
                        user.rewardDebt[i] = postAmount * _poolAccRew[i] / 1e30;
                    }
                }
        }
        user.amount = postAmount;
        poolInfo[_pid].lpToken.safeTransfer(address(msg.sender), _amount);
        
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function reinvestRewards(uint256 _tokenID, uint256 amountOutMin) public nonReentrant {
            UserInfo storage user = userInfo[0][msg.sender];
            updatePool(0);
            require(user.amount > 0, "reinvestRewards: No tokens staked");
            _addToClaimable(0, msg.sender);
            uint256 claimableAmount = user.claimableRWT[_tokenID];
            user.claimableRWT[_tokenID] = 0;
            address[] memory path = new address[](2);
            path[0] = address(rwt[_tokenID]);
            path[1] = address(spiral);
            if (claimableAmount > 0) { 
                rwt[_tokenID].approve(router, claimableAmount);
                uint256 balanceBefore = spiral.balanceOf(address(this));
                IUniswapV2Router02(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                claimableAmount,    
                amountOutMin,
                path,
                address(this),
                block.timestamp
                );
                uint256 amountSwapped = spiral.balanceOf(address(this)) - balanceBefore;
                user.amount += amountSwapped;
                uint256 postAmount = user.amount;
                uint256[] memory _poolAccRew = poolInfo[0].accRwtPerShare;
                for (uint i = 0; i < rwt.length; i++) {
                    userInfo[0][msg.sender].rewardDebt[i] = postAmount * _poolAccRew[i] / 1e30;
                }
				emit Deposit(msg.sender, 0, amountSwapped);
            }
    }

    // Withdraw unlocked tokens without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant onlyEmergency {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        uint256[] memory zeroArray = new uint256[](rwt.length);
        user.amount = 0;
        user.rewardDebt = zeroArray;
        user.claimableRWT = zeroArray;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }
	
	
    
//--------------------------------------------------------RESTRICTED FUNCTIONS --------------------------------------------------------	

    function depositFor(address sender, uint256 _pid, uint256 amount) public onlyAuthorized {
        _deposit(sender, _pid, amount);
    }
    // Create a new pool. Can only be called by the owner.
    function add(uint64 _allocPoint, IERC20 _lpToken, bool _withUpdate) public onlyOwner nonDuplicated(_lpToken) {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint64 lastRewardBlock = uint64(block.number > startBlock ? block.number : startBlock);
        totalAllocPoint = totalAllocPoint + _allocPoint;
        poolExistence[_lpToken] = true;
        uint256[] memory accRWT = new uint256[](rwt.length);
        poolInfo.push(PoolInfo({
        lpToken : _lpToken,
        allocPoint : _allocPoint,
        lastRewardBlock : lastRewardBlock,
        accRwtPerShare : accRWT
        }));
    }

	// Pull out tokens accidentally sent to the contract. Doesnt work with the reward token or any staked token. Can only be called by the owner.
    function rescueToken(address tokenaddress) public onlyOwner {
        require(!rwtExistence[IERC20(tokenaddress)] && !poolExistence[IERC20(tokenaddress)], "rescueToken : wrong token address");
        uint256 bal = IERC20(tokenaddress).balanceOf(address(this));
        IERC20(tokenaddress).transfer(msg.sender, bal);
    }

    // Update the given pool's rewards allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint64 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint ;
        poolInfo[_pid].allocPoint = _allocPoint;
    }
	// Initialize the rewards. Can only be called by the owner. 
    function startRewards() public onlyOwner {
        require(startBlock > block.number, "startRewards: rewards already started");
        startBlock = block.number;
        for (uint i; i < poolInfo.length; i++) {
            poolInfo[i].lastRewardBlock = uint64(block.number);            
        }
    }
    // Updates RWT emision rate. Can only be called by the owner
    function updateEmissionRate(uint256 _tokenID, uint256 _rwtPerBlock) public onlyOwner {
        require(_tokenID < rwt.length);
		massUpdatePools();
        rwtPerBlock[_tokenID] = _rwtPerBlock;
        emit UpdateEmissionRate(msg.sender, _rwtPerBlock);
    }
    // Sets the reward token address and the initial emission rate. Can only be called by the owner. 
    function addRewardToken(IERC20 _RWT, uint _rwtPerBlock) public onlyOwner nonDuplicatedRWT(_RWT) {
        rwt.push(_RWT);
        rwtPerBlock.push(_rwtPerBlock);
        rwtExistence[_RWT] = true;
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; pid++) {
            poolInfo[pid].accRwtPerShare.push();
        }
        emit RewardTokenSet(_RWT, _rwtPerBlock, block.timestamp);
    }

    function setPerBurn(uint256 _perBurn, uint256 _maxBurn) external onlyOwner {
        perBurn.push(_perBurn);
        maxBurn.push(_maxBurn);
    }
    
    // Emergency only 
    function emergency(bool _isEmergency) external onlyOwner {
        isEmergency = _isEmergency;
        emit Emergency(block.timestamp, _isEmergency);
    }
    function authorize(address _address) external onlyOwner {
        authorized[_address] = true;
    }
    function unauthorize(address _address) external onlyOwner {
        authorized[_address] = false;
    }

    function setLock(uint256 _lockUntil) external onlyOwner {
        require(_lockUntil <= block.timestamp + 2 weeks && lockUntil + 1 days <= block.timestamp);
        lockUntil = _lockUntil;
    }


//--------------------------------------------------------INTERNAL FUNCTIONS --------------------------------------------------------
    function _deposit(address sender, uint256 _pid, uint256 _amount) internal {
        require(_amount > 0);
        UserInfo storage user = userInfo[_pid][sender];
        uint256 amount = user.amount;
        updatePool(_pid);
        if(amount > 0) {
            _addToClaimable(_pid, sender);
        }

        poolInfo[_pid].lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        user.amount = amount + _amount;
        if(rwt.length != 0) {
            amount = user.amount;
            uint256[] memory accRwtPerShare = poolInfo[_pid].accRwtPerShare;
            for (uint i=0; i < user.rewardDebt.length; i++){
                user.rewardDebt[i] = amount * accRwtPerShare[i] / 1e30;
            }
            if (user.rewardDebt.length != rwt.length) {
                for (uint i = user.rewardDebt.length; i < rwt.length; i++) {
                    user.claimableRWT.push(0);
                    user.rewardDebt.push(amount * accRwtPerShare[i] / 1e30);
                }
            }    
        }
        emit Deposit(sender, _pid, _amount);
    }
    
    function _addToClaimable(uint256 _pid, address sender) internal {
        if(rwt.length != 0) {
            UserInfo storage user = userInfo[_pid][sender];
            PoolInfo memory pool = poolInfo[_pid];
            UserInfo memory _user = user;
            for (uint i=0; i < _user.rewardDebt.length; i++){
                uint256 pending = (_user.amount * pool.accRwtPerShare[i] / 1e30) - _user.rewardDebt[i] + _user.claimableRWT[i];
                if (pending > 0) {
                    user.claimableRWT[i] = pending;
                }
            }
            if (_user.rewardDebt.length != rwt.length) {
                for (uint i = _user.rewardDebt.length; i < rwt.length; i++) {
                    uint256 pending = (_user.amount * pool.accRwtPerShare[i] / 1e30);
                    user.claimableRWT.push(pending);
                    user.rewardDebt.push();
                }
            }
        }
    }

    // Safe transfer function, just in case if rounding error causes pool to not have enough RWTs.
    function safeRWTTransfer(uint tokenID, address _to, uint256 _amount) internal {
        IERC20 _rwt = rwt[tokenID];
        uint256 rwtBal = _rwt.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > rwtBal) {
            transferSuccess = _rwt.transfer(_to, rwtBal);
        } else {
            transferSuccess = _rwt.transfer(_to, _amount);
        }
        require(transferSuccess, "safeRWTTransfer: transfer failed");
    }
}