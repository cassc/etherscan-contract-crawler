/**
 *Submitted for verification at Etherscan.io on 2022-06-01
*/

// File: contracts/@openzeppelin/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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

// File: contracts/@openzeppelin/utils/Context.sol


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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: contracts/@openzeppelin/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
}

// File: contracts/@openzeppelin/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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

// File: contracts/@openzeppelin/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: contracts/@openzeppelin/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;



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

// File: contracts/@openzeppelin/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: contracts/Staking.sol





pragma solidity ^0.8.14;








/**

 * @title AGFI Staking

 * @author Aggregated Finance

 * @notice AGFIStaking is a contract that allows AGFI deposits and receives AGFI sent from the AGFI staking tax channel

 * harvests. Users deposit AGFI and receive a share of what has been sent from the AGFI contract based on their participation of

 * the total deposited AGFI.

 * This contract is a fork from sJOE, but just rewarding the same token that is staked 

 * Every time `updateReward(token)` is called, We distribute the balance of that tokens as rewards to users that are

 * currently staking inside this contract, and they can claim it using `withdraw(0)`

 */

contract AGFIStaking is Ownable, ReentrancyGuard {

    using SafeMath for uint256;

    using SafeERC20 for IERC20;



    /// @notice Info of each user

    struct UserInfo {

        uint256 amount;

        mapping(IERC20 => uint256) rewardDebt;

        /**

         * @notice We do some fancy math here. Basically, any point in time, the amount of AGFI

         * entitled to a user but is pending to be distributed is:

         *

         *   pending reward = (user.amount * accRewardPerShare) - user.rewardDebt[token]

         *

         * Whenever a user deposits or withdraws AGFI. Here's what happens:

         *   1. accRewardPerShare (and `lastRewardBalance`) gets updated

         *   2. User receives the pending reward sent to his/her address

         *   3. User's `amount` gets updated

         *   4. User's `rewardDebt[token]` gets updated

         */

    }



    IERC20 public agfi;



    /// @dev Internal balance of AGFI, this gets updated on user deposits / withdrawals

    /// this allows to reward users with AGFI

    uint256 public internalAGFIBalance;

    /// @notice Array of tokens that users can claim

    IERC20[] public rewardTokens;

    mapping(IERC20 => bool) public isRewardToken;

    /// @notice Last reward balance of `token`

    mapping(IERC20 => uint256) public lastRewardBalance;



    address public feeCollector;



    /// @notice The deposit fee, scaled to `DEPOSIT_FEE_PERCENT_PRECISION`

    uint256 public depositFeePercent;

    /// @notice The precision of `depositFeePercent`

    uint256 public DEPOSIT_FEE_PERCENT_PRECISION;



    /// @notice Accumulated `token` rewards per share, scaled to `ACC_REWARD_PER_SHARE_PRECISION`

    mapping(IERC20 => uint256) public accRewardPerShare;

    /// @notice The precision of `accRewardPerShare`

    uint256 public ACC_REWARD_PER_SHARE_PRECISION;



    /// @dev Info of each user that stakes AGFI

    mapping(address => UserInfo) private userInfo;



    /// @notice Emitted when a user deposits AGFI

    event Deposit(address indexed user, uint256 amount, uint256 fee);



    /// @notice Emitted when owner changes the deposit fee percentage

    event DepositFeeChanged(uint256 newFee, uint256 oldFee);



    /// @notice Emitted when a user withdraws AGFI

    event Withdraw(address indexed user, uint256 amount);



    /// @notice Emitted when a user claims reward

    event ClaimReward(address indexed user, address indexed rewardToken, uint256 amount);



    /// @notice Emitted when a user emergency withdraws its AGFI

    event EmergencyWithdraw(address indexed user, uint256 amount);



    /// @notice Emitted when owner adds a token to the reward tokens list

    event RewardTokenAdded(address token);



    /// @notice Emitted when owner removes a token from the reward tokens list

    event RewardTokenRemoved(address token);



    /**

     * @notice Initialize a new AGFIStaking contract

     * @dev This contract needs to receive an ERC20 `_rewardToken` in order to distribute them

     * @param _rewardToken The address of the ERC20 reward token

     * @param _agfi The address of the AGFI token

     * @param _feeCollector The address where deposit fees will be sent

     * @param _depositFeePercent The deposit fee percent, scalled to 1e18, e.g. 3% is 3e16

     */

    constructor(

        IERC20 _rewardToken,

        IERC20 _agfi,

        address _feeCollector,

        uint256 _depositFeePercent

    ) {

        require(address(_rewardToken) != address(0), "AGFIStaking: reward token can't be address(0)");

        require(address(_agfi) != address(0), "AGFIStaking: agfi can't be address(0)");

        require(_feeCollector != address(0), "AGFIStaking: fee collector can't be address(0)");

        require(_depositFeePercent <= 5e17, "AGFIStaking: max deposit fee can't be greater than 50%");



        agfi = _agfi;

        depositFeePercent = _depositFeePercent;

        feeCollector = _feeCollector;



        isRewardToken[_rewardToken] = true;

        rewardTokens.push(_rewardToken);

        DEPOSIT_FEE_PERCENT_PRECISION = 1e18;

        ACC_REWARD_PER_SHARE_PRECISION = 1e24;

    }



    /**

     * @notice Deposit AGFI for reward token allocation

     * @param _amount The amount of AGFI to deposit

     */

    function deposit(uint256 _amount) external nonReentrant {

        UserInfo storage user = userInfo[_msgSender()];



        uint256 _fee = _amount.mul(depositFeePercent).div(DEPOSIT_FEE_PERCENT_PRECISION);

        uint256 _amountMinusFee = _amount.sub(_fee);



        uint256 _previousAmount = user.amount;

        uint256 _newAmount = user.amount.add(_amountMinusFee);

        user.amount = _newAmount;



        uint256 _len = rewardTokens.length;

        for (uint256 i; i < _len; i++) {

            IERC20 _token = rewardTokens[i];

            updateReward(_token);



            uint256 _previousRewardDebt = user.rewardDebt[_token];

            user.rewardDebt[_token] = _newAmount.mul(accRewardPerShare[_token]).div(ACC_REWARD_PER_SHARE_PRECISION);



            if (_previousAmount != 0) {

                uint256 _pending = _previousAmount

                    .mul(accRewardPerShare[_token])

                    .div(ACC_REWARD_PER_SHARE_PRECISION)

                    .sub(_previousRewardDebt);

                if (_pending != 0) {

                    safeTokenTransfer(_token, _msgSender(), _pending);

                    emit ClaimReward(_msgSender(), address(_token), _pending);

                }

            }

        }



        internalAGFIBalance = internalAGFIBalance.add(_amountMinusFee);

        agfi.safeTransferFrom(_msgSender(), feeCollector, _fee);

        agfi.safeTransferFrom(_msgSender(), address(this), _amountMinusFee);

        emit Deposit(_msgSender(), _amountMinusFee, _fee);

    }



    /**

     * @notice Get user info

     * @param _user The address of the user

     * @param _rewardToken The address of the reward token

     * @return The amount of AGFI user has deposited

     * @return The reward debt for the chosen token

     */

    function getUserInfo(address _user, IERC20 _rewardToken) external view returns (uint256, uint256) {

        UserInfo storage user = userInfo[_user];

        return (user.amount, user.rewardDebt[_rewardToken]);

    }



    /**

     * @notice Get the number of reward tokens

     * @return The length of the array

     */

    function rewardTokensLength() external view returns (uint256) {

        return rewardTokens.length;

    }



    /**

     * @notice Add a reward token

     * @param _rewardToken The address of the reward token

     */

    function addRewardToken(IERC20 _rewardToken) external onlyOwner {

        require(

            !isRewardToken[_rewardToken] && address(_rewardToken) != address(0),

            "AGFIStaking: token can't be added"

        );

        require(rewardTokens.length < 25, "AGFIStaking: list of token too big");

        rewardTokens.push(_rewardToken);

        isRewardToken[_rewardToken] = true;

        updateReward(_rewardToken);

        emit RewardTokenAdded(address(_rewardToken));

    }



    /**

     * @notice Remove a reward token

     * @param _rewardToken The address of the reward token

     */

    function removeRewardToken(IERC20 _rewardToken) external onlyOwner {

        require(isRewardToken[_rewardToken], "AGFIStaking: token can't be removed");

        updateReward(_rewardToken);

        isRewardToken[_rewardToken] = false;

        uint256 _len = rewardTokens.length;

        for (uint256 i; i < _len; i++) {

            if (rewardTokens[i] == _rewardToken) {

                rewardTokens[i] = rewardTokens[_len - 1];

                rewardTokens.pop();

                break;

            }

        }

        emit RewardTokenRemoved(address(_rewardToken));

    }



    /**

     * @notice Set the deposit fee percent

     * @param _depositFeePercent The new deposit fee percent

     */

    function setDepositFeePercent(uint256 _depositFeePercent) external onlyOwner {

        require(_depositFeePercent <= 5e17, "AGFIStaking: deposit fee can't be greater than 50%");

        uint256 oldFee = depositFeePercent;

        depositFeePercent = _depositFeePercent;

        emit DepositFeeChanged(_depositFeePercent, oldFee);

    }



    /**

     * @notice View function to see pending reward token on frontend

     * @param _user The address of the user

     * @param _token The address of the token

     * @return `_user`'s pending reward token

     */

    function pendingReward(address _user, IERC20 _token) external view returns (uint256) {

        require(isRewardToken[_token], "AGFIStaking: wrong reward token");

        UserInfo storage user = userInfo[_user];

        uint256 _totalAGFI = internalAGFIBalance;

        uint256 _accRewardTokenPerShare = accRewardPerShare[_token];



        uint256 _currRewardBalance = _token.balanceOf(address(this));

        uint256 _rewardBalance = _token == agfi ? _currRewardBalance.sub(_totalAGFI) : _currRewardBalance;



        if (_rewardBalance != lastRewardBalance[_token] && _totalAGFI != 0) {

            uint256 _accruedReward = _rewardBalance.sub(lastRewardBalance[_token]);

            _accRewardTokenPerShare = _accRewardTokenPerShare.add(

                _accruedReward.mul(ACC_REWARD_PER_SHARE_PRECISION).div(_totalAGFI)

            );

        }

        return

            user.amount.mul(_accRewardTokenPerShare).div(ACC_REWARD_PER_SHARE_PRECISION).sub(user.rewardDebt[_token]);

    }



    /**

     * @notice Withdraw AGFI and harvest the rewards

     * @param _amount The amount of AGFI to withdraw

     */

    function withdraw(uint256 _amount) external nonReentrant {

        UserInfo storage user = userInfo[_msgSender()];

        uint256 _previousAmount = user.amount;

        require(_amount <= _previousAmount, "AGFIStaking: withdraw amount exceeds balance");

        uint256 _newAmount = user.amount.sub(_amount);

        user.amount = _newAmount;



        uint256 _len = rewardTokens.length;

        if (_previousAmount != 0) {

            for (uint256 i; i < _len; i++) {

                IERC20 _token = rewardTokens[i];

                updateReward(_token);



                uint256 _pending = _previousAmount

                    .mul(accRewardPerShare[_token])

                    .div(ACC_REWARD_PER_SHARE_PRECISION)

                    .sub(user.rewardDebt[_token]);

                user.rewardDebt[_token] = _newAmount.mul(accRewardPerShare[_token]).div(ACC_REWARD_PER_SHARE_PRECISION);



                if (_pending != 0) {

                    safeTokenTransfer(_token, _msgSender(), _pending);

                    emit ClaimReward(_msgSender(), address(_token), _pending);

                }

            }

        }



        internalAGFIBalance = internalAGFIBalance.sub(_amount);

        agfi.safeTransfer(_msgSender(), _amount);

        emit Withdraw(_msgSender(), _amount);

    }



    /**

     * @notice Withdraw without caring about rewards. EMERGENCY ONLY

     */

    function emergencyWithdraw() external nonReentrant {

        UserInfo storage user = userInfo[_msgSender()];



        uint256 _amount = user.amount;

        user.amount = 0;

        uint256 _len = rewardTokens.length;

        for (uint256 i; i < _len; i++) {

            IERC20 _token = rewardTokens[i];

            user.rewardDebt[_token] = 0;

        }

        internalAGFIBalance = internalAGFIBalance.sub(_amount);

        agfi.safeTransfer(_msgSender(), _amount);

        emit EmergencyWithdraw(_msgSender(), _amount);

    }



    /**

     * @notice Update reward variables

     * @param _token The address of the reward token

     * @dev Needs to be called before any deposit or withdrawal

     */

    function updateReward(IERC20 _token) public {

        require(isRewardToken[_token], "AGFIStaking: wrong reward token");



        uint256 _totalAGFI = internalAGFIBalance;



        uint256 _currRewardBalance = _token.balanceOf(address(this));

        uint256 _rewardBalance = _token == agfi ? _currRewardBalance.sub(_totalAGFI) : _currRewardBalance;



        // Did AGFIStaking receive any token

        if (_rewardBalance == lastRewardBalance[_token] || _totalAGFI == 0) {

            return;

        }



        uint256 _accruedReward = _rewardBalance.sub(lastRewardBalance[_token]);



        accRewardPerShare[_token] = accRewardPerShare[_token].add(

            _accruedReward.mul(ACC_REWARD_PER_SHARE_PRECISION).div(_totalAGFI)

        );

        lastRewardBalance[_token] = _rewardBalance;

    }



    /**

     * @notice Safe token transfer function, just in case if rounding error

     * causes pool to not have enough reward tokens

     * @param _token The address of then token to transfer

     * @param _to The address that will receive `_amount` `rewardToken`

     * @param _amount The amount to send to `_to`

     */

    function safeTokenTransfer(

        IERC20 _token,

        address _to,

        uint256 _amount

    ) internal {

        uint256 _currRewardBalance = _token.balanceOf(address(this));

        uint256 _rewardBalance = _token == agfi ? _currRewardBalance.sub(internalAGFIBalance) : _currRewardBalance;



        if (_amount > _rewardBalance) {

            lastRewardBalance[_token] = lastRewardBalance[_token].sub(_rewardBalance);

            _token.safeTransfer(_to, _rewardBalance);

        } else {

            lastRewardBalance[_token] = lastRewardBalance[_token].sub(_amount);

            _token.safeTransfer(_to, _amount);

        }

    }

}