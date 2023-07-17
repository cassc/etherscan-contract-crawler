/**
 *Submitted for verification at Etherscan.io on 2020-12-02
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.6.0;

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
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.6.0;




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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity ^0.6.0;

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/ODSMiner.sol

pragma solidity ^0.6.0;





contract ODSMiner is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant ODS_TOTAL_SUPPLY = 4200000;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        IERC20 lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accOdsPerShare;
        uint256 totalSupply;
    }

    uint256 public odsPerBlock;

    PoolInfo[] public poolInfo;

    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    uint256 public totalAllocPoint = 0;

    uint256 public startBlock;

    uint256 private constant ODS_PREMINE = 10000;
    uint256 public premineAmount = 0;

    uint256 private tokenDecimals = 0;
    IERC20 private token;

    uint256 private contributionShare;

    struct NodeInfo {
        bool active;
        bool superNode;
        uint256 lastRewardBlock;
        uint256 amount;
        uint256 superNodeRewardCount;
        uint256 nodeRewardCount;
    }

    address[] public nodeList;
    mapping(address => NodeInfo) public nodeInfo;
    uint256 superNodeCount = 0;
    uint256 nodeCount = 0;

    uint256 private rewardPreSuperNode = 10000;
    uint256 private rewardShareForSuperNodes = 10000;
    uint256 private rewardPreNode = 0;
    uint256 private rewardShareForNodes = 0;
    uint256 private constant rewardDurationForNodes = 5760;

    uint256 private constant maxRewardCount = 100;

    mapping(address => bool) private _operators;


    event Deposit(address indexed user, uint256 indexed pid, uint256 amount, uint256 poolAccOdsPerShare, uint256 pending, uint256 userAmount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount, uint256 poolAccOdsPerShare, uint256 pending, uint256 userAmount);

    uint256 private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, "LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }
    
    modifier onlyOperator() {
        require(_operators[msg.sender], "Ownable: caller is not the operator");
        _;
    }

    constructor(
        IERC20 _token,
        uint256 _odsPerBlock,
        uint256 _startBlock
    ) public {
        token = _token;
        tokenDecimals = 18;

        odsPerBlock = _odsPerBlock;
        startBlock = _startBlock;
        
        _operators[msg.sender] = true;

        rewardPreSuperNode = rewardPreSuperNode.mul(10**tokenDecimals).div(
            10000
        );

        rewardShareForSuperNodes = rewardShareForSuperNodes
            .mul(10**tokenDecimals)
            .div(10000);

        rewardPreNode = rewardPreNode.mul(10**tokenDecimals).div(10000);

        rewardShareForNodes = rewardShareForNodes.mul(10**tokenDecimals).div(
            10000
        );
    }

    function init(uint256 totalSupply) public payable onlyOwner {
        require(
            totalSupply == ODS_TOTAL_SUPPLY.mul(10**tokenDecimals),
            "wrong total supply for ODS"
        );

        uint256 allowance = token.allowance(msg.sender, address(this));

        require(allowance >= totalSupply, "check the token allowance");

        premineAmount = ODS_PREMINE.mul(10**tokenDecimals);

        token.transferFrom(msg.sender, address(this), totalSupply);
    }

    function initNode(address[] memory nodes, bool[] memory superNode)
        public
        onlyOwner
    {
        require(nodes.length == superNode.length, "initNode: length mismatch");

        for (uint256 i = 0; i < nodes.length; i++) {
            nodeList.push(nodes[i]);
            nodeInfo[nodes[i]] = NodeInfo({
                active: true,
                superNode: superNode[i],
                lastRewardBlock: block.number > startBlock
                    ? block.number
                    : startBlock,
                amount: 0,
                superNodeRewardCount: 0,
                nodeRewardCount: 0
            });

            if (superNode[i]) {
                superNodeCount = superNodeCount.add(1);
            } else {
                nodeCount = nodeCount.add(1);
            }
        }
    }

    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accOdsPerShare: 0,
                totalSupply: 0
            })
        );
    }

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    function getMultiplier(uint256 _from, uint256 _to)
        private
        pure
        returns (uint256)
    {
        return _to.sub(_from);
    }

    function pendingOds(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accOdsPerShare = pool.accOdsPerShare;
        uint256 lpSupply = pool.totalSupply;
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number);
            uint256 odsReward =
                multiplier.mul(odsPerBlock).mul(pool.allocPoint).div(
                    totalAllocPoint
                );
            accOdsPerShare = accOdsPerShare.add(
                odsReward.mul(1e12).div(lpSupply)
            );
        }
        return user.amount.mul(accOdsPerShare).div(1e12).sub(user.rewardDebt);
    }

    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.totalSupply;
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 odsReward =
            multiplier.mul(odsPerBlock).mul(pool.allocPoint).div(
                totalAllocPoint
            );
        pool.accOdsPerShare = pool.accOdsPerShare.add(
            odsReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    function deposit(uint256 _pid, uint256 _amount) public lock {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);

        uint256 pending = 0;
        if (user.amount > 0) {
            pending = user.amount.mul(pool.accOdsPerShare).div(1e12).sub(
                user.rewardDebt
            );
            if (pending > 0) {
                safeOdsTransfer(msg.sender, pending);
            }
        }

        if (_amount > 0) {
            user.amount = user.amount.add(_amount);
            pool.totalSupply = pool.totalSupply.add(_amount);
            pool.lpToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
        }

        user.rewardDebt = user.amount.mul(pool.accOdsPerShare).div(1e12);

        emit Deposit(msg.sender, _pid, _amount, pool.accOdsPerShare, pending, user.amount);
    }

    function withdraw(uint256 _pid, uint256 _amount) public lock {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending =
            user.amount.mul(pool.accOdsPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            safeOdsTransfer(msg.sender, pending);
        }

        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.totalSupply = pool.totalSupply.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }

        user.rewardDebt = user.amount.mul(pool.accOdsPerShare).div(1e12);

        emit Withdraw(msg.sender, _pid, _amount, pool.accOdsPerShare, pending, user.amount);
    }

    function setNodeReward(
        uint256 _rewardPreSuperNode,
        uint256 _rewardShareForSuperNodes,
        uint256 _rewardPreNode,
        uint256 _rewardShareForNodes
    ) public onlyOperator {
        require(
            _rewardPreSuperNode >= 0 && _rewardPreSuperNode <= 1000000,
            "rewardPreSuperNode is invalid"
        );
        require(
            _rewardShareForSuperNodes >= 0 &&
                _rewardShareForSuperNodes <= 1000000,
            "rewardShareForSuperNodes is invalid"
        );
        require(
            _rewardPreNode >= 0 && _rewardPreNode <= 1000000,
            "rewardPreNode is invalid"
        );
        require(
            _rewardShareForNodes >= 0 && _rewardShareForNodes <= 1000000,
            "rewardShareForNodes is invalid"
        );
        require(
            _rewardPreSuperNode > 0 ||
                _rewardShareForSuperNodes > 0 ||
                _rewardPreNode > 0 ||
                _rewardShareForSuperNodes > 0,
            "invalid set for node reward"
        );

        massUpdateNodes();

        if (_rewardPreSuperNode > 0)
            rewardPreSuperNode = _rewardPreSuperNode.mul(10**tokenDecimals).div(
                10000
            );
        if (_rewardShareForSuperNodes > 0)
            rewardShareForSuperNodes = _rewardShareForSuperNodes
                .mul(10**tokenDecimals)
                .div(10000);
        if (_rewardPreNode > 0)
            rewardPreNode = _rewardPreNode.mul(10**tokenDecimals).div(10000);
        if (_rewardShareForNodes > 0)
            rewardShareForNodes = _rewardShareForNodes
                .mul(10**tokenDecimals)
                .div(10000);
    }

    function massUpdateNodes() private {
        for (uint256 i = 0; i < nodeList.length; i++) {
            updateNode(nodeList[i]);
        }
    }

    function updateNode(address _node) private {
        (uint256 amount, uint256 rewardBlocks) = nodeReward(_node);

        if (amount > 0) {
            NodeInfo storage node = nodeInfo[_node];
            node.amount = node.amount.add(amount);
            node.lastRewardBlock = node.lastRewardBlock.add(
                rewardBlocks.mul(rewardDurationForNodes)
            );

            if (node.superNode) {
                node.superNodeRewardCount = node.superNodeRewardCount.add(
                    rewardBlocks
                );
            } else {
                node.nodeRewardCount = node.nodeRewardCount.add(rewardBlocks);
            }
        }
    }

    function nodeReward(address _node) private view returns (uint256, uint256) {
        NodeInfo storage node = nodeInfo[_node];

        if (
            (node.superNode && node.superNodeRewardCount >= maxRewardCount) ||
            (!node.superNode && node.nodeRewardCount >= maxRewardCount) ||
            block.number < startBlock
        ) {
            return (0, 0);
        }

        uint256 rewardBlocks =
            block.number > node.lastRewardBlock
                ? (block.number - node.lastRewardBlock) / rewardDurationForNodes
                : 0;

        if (rewardBlocks == 0) {
            return (0, 0);
        }

        if (
            node.superNode &&
            node.superNodeRewardCount.add(rewardBlocks) > maxRewardCount
        ) {
            rewardBlocks = maxRewardCount.sub(node.superNodeRewardCount);
        } else if (
            !node.superNode &&
            node.nodeRewardCount.add(rewardBlocks) > maxRewardCount
        ) {
            rewardBlocks = maxRewardCount.sub(node.nodeRewardCount);
        }

        (uint256 _superNodeCount, uint256 _nodeCount) = nodeCountInfo();

        // node reward
        uint256 rewardAmount = 0;
        if (node.superNode) {
            // super node reward
            rewardAmount = rewardBlocks.mul(rewardPreSuperNode);

            // super node share reward
            rewardAmount = rewardBlocks
                .mul(rewardShareForSuperNodes)
                .div(_superNodeCount)
                .add(rewardAmount);
        } else {
            // node reward
            rewardAmount = rewardBlocks.mul(rewardPreNode);

            // node share
            rewardAmount = rewardBlocks
                .mul(rewardShareForNodes)
                .div(_nodeCount)
                .add(rewardAmount);
        }

        return (rewardAmount, rewardBlocks);
    }

    function nodeCountInfo()
        public
        view
        returns (uint256 _superNodeCount, uint256 _nodeCount)
    {
        _superNodeCount = superNodeCount;
        _nodeCount = nodeCount;
    }

    function isNode() external view returns (bool, bool) {
        NodeInfo storage node = nodeInfo[msg.sender];

        if (!node.active) {
            return (false, false);
        }

        return (true, node.superNode);
    }

    function pendingNodeOds() external view returns (uint256) {
        NodeInfo storage node = nodeInfo[msg.sender];

        if (!node.active) {
            return 0;
        }

        (uint256 amount, ) = nodeReward(msg.sender);

        return node.amount.add(amount);
    }

    function withdrawNodeOds(uint256 _amount) public {
        NodeInfo storage node = nodeInfo[msg.sender];

        require(node.active, "invalid node");

        updateNode(msg.sender);

        require(nodeInfo[msg.sender].amount >= _amount, "not enough balance");

        nodeInfo[msg.sender].amount = nodeInfo[msg.sender].amount.sub(_amount);

        safeOdsTransfer(address(msg.sender), _amount);
    }

    function addNodes(address account, bool superNode) public onlyOperator {
        NodeInfo storage node = nodeInfo[account];

        require(!node.active, "node is activated");

        massUpdateNodes();

        if (node.lastRewardBlock > 0) {
            // exist in map
            nodeList.push(account);

            node.active = true;
            node.lastRewardBlock = block.number > startBlock
                ? block.number
                : startBlock;
            node.superNode = superNode;
        } else {
            nodeList.push(account);
            nodeInfo[account] = NodeInfo({
                active: true,
                superNode: superNode,
                lastRewardBlock: block.number > startBlock
                    ? block.number
                    : startBlock,
                amount: 0,
                superNodeRewardCount: 0,
                nodeRewardCount: 0
            });
        }

        if (superNode) {
            superNodeCount = superNodeCount.add(1);
        } else {
            nodeCount = nodeCount.add(1);
        }
    }

    function removeNodes(address account) public onlyOperator {
        NodeInfo storage node = nodeInfo[account];

        require(node.active, "node is not activated");

        massUpdateNodes();

        for (uint256 i = 0; i < nodeList.length; i++) {
            if (nodeList[i] == account) {
                nodeList[i] = nodeList[nodeList.length - 1];
                nodeList.pop();
                break;
            }
        }

        if (node.superNode) {
            superNodeCount = superNodeCount.sub(1);
        } else {
            nodeCount = nodeCount.sub(1);
        }

        node.active = false;

        if (node.amount > 0) {
            uint256 amount = node.amount;
            node.amount = 0;
            safeOdsTransfer(account, amount);
        }
    }

    function getNodeRewardSetting()
        public
        view
        returns (
            uint256 _rewardPreSuperNode,
            uint256 _rewardShareForSuperNodes,
            uint256 _rewardPreNode,
            uint256 _rewardShareForNodes
        )
    {
        _rewardPreSuperNode = rewardPreSuperNode;
        _rewardPreNode = rewardPreNode;
        _rewardShareForSuperNodes = rewardShareForSuperNodes;
        _rewardShareForNodes = rewardShareForNodes;
    }

    function withdrawPreMine(uint256 _amount) public onlyOperator {
        require(_amount >= 0, "amount is zero");
        require(premineAmount >= _amount, "not enough balance");

        premineAmount = premineAmount.sub(_amount);

        token.transfer(msg.sender, _amount);
    }

    function contributionAmount() public view returns (uint256) {
        uint256 blocks =
            block.number > startBlock ? block.number - startBlock : 0;

        return odsPerBlock.mul(blocks).sub(contributionShare);
    }

    function contributionWithdraw(uint256 amount) public onlyOperator {
        require(amount >= 0, "amount is zero");
        require(contributionAmount() >= amount, "not enough balance");

        contributionShare = contributionShare.add(amount);

        token.transfer(msg.sender, amount);
    }

    function safeOdsTransfer(address _to, uint256 _amount) internal {
        uint256 balance =
            token
                .balanceOf(address(this))
                .sub(ODS_PREMINE.mul(10**tokenDecimals))
                .div(2);
        if (_amount > balance) {
            token.transfer(msg.sender, balance);
        } else {
            token.transfer(_to, _amount);
        }
    }
    
    function addOperator(address account) public onlyOwner {
        require(account != address(0), "invalid address");
        require(!_operators[account], "account is already operator");
        
        _operators[account] = true;
    }
    
    function removeOperator(address account) public onlyOwner {
        require(account != address(0), "invalid address");
        require(_operators[account], "account is not operator");
        
        _operators[account] = false;
    }
}