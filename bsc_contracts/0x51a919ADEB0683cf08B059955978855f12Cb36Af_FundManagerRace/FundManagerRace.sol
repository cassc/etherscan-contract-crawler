/**
 *Submitted for verification at BscScan.com on 2023-01-04
*/

// File: @chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.6.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// File: ECDSA.sol



pragma solidity 0.6.12; // >=0.6.0 <0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// File: ReentrancyGuard.sol



pragma solidity 0.6.12; // >=0.6.0 <0.8.0;

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

    constructor () internal {
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
// File: Context.sol


pragma solidity 0.6.12; // >=0.6.0 <0.8.0;

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
// File: Ownable.sol


pragma solidity 0.6.12; // >=0.6.0 <0.8.0;


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
// File: Address.sol



pragma solidity 0.6.12; // >=0.6.2 <0.8;

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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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
// File: IBEP20.sol


pragma solidity 0.6.12; // >=0.6.4;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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
// File: SafeMath.sol


pragma solidity 0.6.12; // >=0.6.0 <0.8.0;

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
// File: SafeBEP20.sol






pragma solidity 0.6.12; // >=0.6.0 <0.8.0;

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IBEP20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IBEP20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IBEP20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeBEP20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}
// File: BEP20.sol



pragma solidity 0.6.12; // >=0.4.0;





/**
 * @dev Implementation of the {IBEP20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {BEP20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-BEP20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of BEP20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IBEP20-approve}.
 */
contract BEP20 is Context, IBEP20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external override view returns (address) {
        return owner();
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public override view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    /**
    * @dev Returns the number of decimals used to get its user representation.
    */
    function decimals() public override view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {BEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom (address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, 'BEP20: transfer amount exceeds allowance')
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, 'BEP20: decreased allowance below zero'));
        return true;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
     * the total supply.
     *
     * Requirements
     *
     * - `msg.sender` must be the token owner
     */
    function mint(uint256 amount) public virtual onlyOwner returns (bool) {
        _mint(_msgSender(), amount);
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer (address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), 'BEP20: transfer from the zero address');
        require(recipient != address(0), 'BEP20: transfer to the zero address');

        _balances[sender] = _balances[sender].sub(amount, 'BEP20: transfer amount exceeds balance');
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: mint to the zero address');

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: burn from the zero address');

        _balances[account] = _balances[account].sub(amount, 'BEP20: burn amount exceeds balance');
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve (address owner, address spender, uint256 amount) internal {
        require(owner != address(0), 'BEP20: approve from the zero address');
        require(spender != address(0), 'BEP20: approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, 'BEP20: burn amount exceeds allowance'));
    }
}
// File: HyperToken.sol







// File: contracts\HYPERToken.sol

pragma solidity 0.6.12;

//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.4.2/contracts/access/Ownable.sol";

// HyperToken with Governance.
contract HyperToken is BEP20('Hyper Token', 'HYP') {
    address[] public managers;
    
    modifier onlyManagers {
        require(isManager(msg.sender) != 0, 'HyperToken: caller is not a manager');
        _;
    }

    event Mint(address indexed user, uint256 amount);
    event AddManager(address indexed user, address indexed manager);
    event RemoveManager(address indexed user, address indexed manager);
    
    function mint(address _to, uint256 _amount) public onlyManagers {
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);
    }
    function mint(uint256 amount) public override onlyOwner returns (bool) {
        _mint(msg.sender, amount);
        _moveDelegates(address(0), _delegates[msg.sender], amount);
        emit Mint(msg.sender, amount);
        return true;
    }
    
    function addManager(address _manager) public onlyOwner {
        if (isManager(_manager) == 0) {
            managers.push(_manager);
        }
        emit AddManager(msg.sender, _manager);
    }
    function removeManager(address _manager) public onlyOwner {
        uint256 id = isManager(_manager);
        if (id != 0) {
            managers[id - 1] = managers[managers.length - 1];
            managers.pop();
        }
        emit RemoveManager(msg.sender, _manager);
    }
    function isManager(address _manager) internal view returns (uint256) {
        for (uint256 t = 0; t < managers.length; t++) {
            if (managers[t] == _manager) {
                return t + 1;
            }
        }
        return 0;
    }
    function getManagers() public view returns (uint256 count, address[] memory managersList) {
        return (managers.length, managers);
    }

    // Copied and modified from YAM code:
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernanceStorage.sol
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernance.sol
    // Which is copied and modified from COMPOUND:
    // https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol

    /// @dev A record of each accounts delegate
    mapping (address => address) internal _delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

      /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegator The address to get delegatee for
     */
    function delegates(address delegator)
        external
        view
        returns (address)
    {
        return _delegates[delegator];
    }

   /**
    * @notice Delegate votes from `msg.sender` to `delegatee`
    * @param delegatee The address to delegate votes to
    */
    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name())),
                getChainId(),
                address(this)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATION_TYPEHASH,
                delegatee,
                nonce,
                expiry
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                structHash
            )
        );

        // address signatory = ecrecover(digest, v, r, s);
        address signatory = ECDSA.recover(digest, v, r, s);
        require(signatory != address(0), "HYP::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "HYP::delegateBySig: invalid nonce");
        require(now <= expiry, "HYP::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account)
        external
        view
        returns (uint256)
    {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber)
        external
        view
        returns (uint256)
    {
        require(blockNumber < block.number, "HYP::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee)
        internal
    {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying HYPs (not scaled);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    )
        internal
    {
        uint32 blockNumber = safe32(block.number, "HYP::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        super.transfer(recipient, amount);
        _moveDelegates(_delegates[_msgSender()], _delegates[recipient], amount);
        return true;
    }

    function transferFrom(
        address sender, 
        address recipient, 
        uint256 amount
    ) public override returns (bool) {
        super.transferFrom(sender, recipient, amount); 
        _moveDelegates(_delegates[sender], _delegates[recipient], amount); 
        return true;
    }

    function burn(uint256 _amount) public {
        _burn(_msgSender(), _amount);
        _moveDelegates(_delegates[_msgSender()], address(0), _amount);
    }
}
// File: FundManager_Race.sol












// File: contracts\FundManager_Race.sol

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;


interface IHyperdexPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;

    function getTwapPrice() external view returns (uint256 price0, uint256 price1);
}

contract FundManagerRace is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    modifier isEnabled {
        require(enabled, "FM Disabled");
        _;
    }

    modifier validatePoolByCubeId(uint256 _cubeId) {
        require (_cubeId < cubeInfo.length , "E000") ;
        _;
    }

    modifier onlyBackend {
        require(msg.sender == backendAddress, "E999");
        _;
    }

    struct Totals {
        uint256 assetAmount;
        uint256 pendingAssetAmount;
        uint256 earlyUnlockedAssetAmount;
        uint256 lastAvailUpdate;
        uint256 hyperTokenAmount;
        uint256 avgEntryPrice;
        uint256 cumulativePosition;
        uint256 cumulativeRatio;
        uint256 lastOperationBlock;
    }

    struct Fees {
        uint256 depositFeeBP;
        uint256 guaranteedBP;
        uint256 referralBonusBP;
        uint256 minHyperTokenRatioBP;
        uint256 maxHyperTokenRatioBP;
        uint256 riskLevelBP;
    }
    
    struct Bonus {
        uint256 stepUSD;
        uint256 bonusRewardBP;
    }
    
    struct ProfitDetail {
        uint256 assetProfit;
        uint256 assetLoss;
        uint256 hyperTokenProfitBase;
        uint256 hyperTokenProfitBonus;
    }
    
    struct ProfitInfo {
        uint256 assetInvestment;
        uint256 hyperTokenInvestment;
        uint256 hyperTokenInvestmentUSD;
        ProfitDetail profitDetail;
        uint256 userElapsed;
        uint256 secondsToExpiration;
        uint256 assetPriceUSD;
        uint256 hyperTokenPrice;
    }
    
    struct LedgerEntry {
        uint240 timestamp;
        uint16 operationType;
        uint256 assetAmount;
        uint256 profitAmount;
        uint256 lossAmount;
        uint256 hyperTokenAmount;
        uint256 hyperTokenProfitBase;
        uint256 hyperTokenProfitBonus;
        uint256 assetPrice;
        uint256 hyperTokenPrice;
    }
    
    struct Unlocked {
        uint256 assetAmount;
        uint256 cumulativePosition;
        uint256 hyperTokenAmount;
        uint256 hyperTokenAmountUSD;
        uint256 assetProfit;
        uint256 assetLoss;
        uint256 hyperTokenProfitBase;
        uint256 hyperTokenProfitBonus;
    }

    struct UserInfo {
        uint256 assetAmount;
        uint256 pendingAssetAmount;
        Unlocked earlyUnlockedValues;
        uint256 nextWithdrawalAllowed;
        uint256 avgEntryPrice;
        uint256 cumulativePosition;
        uint256 cumulativeRatio;
        uint256 hyperTokenAmount;
        uint256 hyperTokenUSDvalue;
        uint256 bonusRewardBP;
        uint256 referralBonusBP;
        uint256 lastOperationBlock;
        uint256 lastAssetPrice;
        bool referralUsed;
        LedgerEntry[] ledgerEntries;
    }
    
    struct Times {
        uint256 expiration;
        uint256 lastUpdateBlock;
    }

    struct CubeInfo {
        IBEP20 asset;
        string symbol;
        Times times;
        Fees fees;
        Totals totals;
        address[] suspendedUsersIndex;
        uint256 suspendedUsersCount;
        address managedAddress;
        address priceFeed;
        uint256 targetPrice;
        uint256 stopPrice;
        uint256 lastAssetPrice;
        uint256 borderPrice;
        bool enabled;
    }

    HyperToken public hyperToken;
    address public backendAddress;
    IHyperdexPair public hyperTokenPricePair;
    Bonus[] public bonuses;
    bool public enabled;
    
    CubeInfo[] public cubeInfo;
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;

    event Invest(address indexed user, uint256 indexed cubeId, uint256 amount, uint256 hyperTokenAmount);
    event SetPriceForSuspended(address indexed user, uint256 indexed cubeId, uint256 price);
    event Withdraw(address indexed user, uint256 indexed cubeId, uint256 amount);
    event EarlyUnlockAmount(address indexed user, uint256 indexed cubeId, uint256 amount);
    event StatusChange(bool indexed enabled);
    event BackendAddressChange(address indexed oldBackendAddress, address indexed newBackendAddress);
    event HyperTokenPricePairChange(IHyperdexPair indexed oldHyperTokenPricePair, IHyperdexPair indexed _hyperTokenPricePair);
    event AddCube(address indexed user, IBEP20 indexed asset);
    event SetCube(address indexed user, uint256 indexed cubeId);
    event SetBonus(address indexed user, uint16 indexed bonusID, uint256 stepUSD, uint256 bonusRewardBP);
    event UpdateCube(address indexed user, uint256 indexed cubeId, uint256 lastAssetPrice, bool availUpdate);
    event StopCube(address indexed user, uint256 indexed cubeId, uint256 stopType);
    event ExtractToken(address indexed user, IBEP20 indexed asset, address indexed to, uint256 amount);
    event ExtractBNB(address indexed user, address indexed to, uint256 amount);

    constructor(
        HyperToken _hyperToken,
        address _backendAddress,
        IHyperdexPair _hyperTokenPricePair
    ) public {
        require(address(_hyperToken) != address(0), "Ec01");
        require(_backendAddress != address(0), "Ec03");
        require(address(_hyperTokenPricePair) != address(0), "Ec04");
        hyperToken = _hyperToken;
        backendAddress = _backendAddress;
        hyperTokenPricePair = _hyperTokenPricePair;
        bonuses.push(Bonus({ stepUSD: 0, bonusRewardBP: 0 }));
        bonuses.push(Bonus({ stepUSD: 100 * 1e18, bonusRewardBP: 250 }));
        bonuses.push(Bonus({ stepUSD: 500 * 1e18, bonusRewardBP: 500 }));
        bonuses.push(Bonus({ stepUSD: 1000 * 1e18, bonusRewardBP: 750 }));
        bonuses.push(Bonus({ stepUSD: 10000 * 1e18, bonusRewardBP: 1000 }));
        enabled = true;
    }
    
    // Manager
    
    function setStatus(bool _enabled) external onlyOwner {
        enabled = _enabled;
        emit StatusChange(_enabled);
    }

    function setBackendAddress(address _backendAddress) external onlyOwner {
        require(_backendAddress != address(0), "E005"); // setBackendAddress: ZERO
        address oldBackendAddress = backendAddress;
        backendAddress = _backendAddress;
        emit BackendAddressChange(oldBackendAddress, _backendAddress);
    }
    
     function setHyperTokenPricePair(IHyperdexPair _hyperTokenPricePair) external onlyOwner {
        require(address(_hyperTokenPricePair) != address(0), "E006"); // setHyperTokenPricePair: ZERO
        IHyperdexPair oldHyperTokenPricePair = hyperTokenPricePair;
        hyperTokenPricePair = _hyperTokenPricePair;
        emit HyperTokenPricePairChange(oldHyperTokenPricePair, _hyperTokenPricePair);
    }

    function cubeLength() external view returns (uint256) {
        return cubeInfo.length;
    }

    function addCube(IBEP20 _asset, Fees calldata _fees, uint256 _expiration, 
        address _managedAddress, address _priceFeed, uint256 _targetPrice, uint256 _stopPrice, uint256 _assetPrice, uint256 _borderPrice, 
        bool _enabled) external onlyOwner {
        require(_fees.depositFeeBP <= 10000, "E007"); // add: invalid deposit fee
        require(_fees.guaranteedBP <= 10000, "E008"); // add: invalid guaranteed
        require(_fees.referralBonusBP <= 10000, "E009"); // add: invalid referral bonus
        require(_fees.maxHyperTokenRatioBP <= 10000 && _fees.minHyperTokenRatioBP >= 1000 && _fees.minHyperTokenRatioBP <= _fees.maxHyperTokenRatioBP, "E011"); // add: invalid max HYP ratio
        require(_fees.riskLevelBP <= 10000 && _fees.riskLevelBP >= 1000, "E011b"); // add: invalid risk level
        require(_expiration > block.timestamp, "E012"); // add: invalid expiration
        require(_managedAddress != address(0), "E013"); // add: invalid managed address
        require(_priceFeed != address(0), "E014"); // add: invalid price feed address
        require(_targetPrice != 0 && _stopPrice != 0 && _borderPrice != 0, "E014b"); // add: target/stop/border price cannot be zero
        if (_targetPrice > _stopPrice) {
            require(_borderPrice < _targetPrice && _borderPrice > _stopPrice, "E014c"); // add: invalid borderPrice
        } else {
            require(_borderPrice > _targetPrice && _borderPrice < _stopPrice, "E014d"); // add: invalid borderPrice
        }
        cubeInfo.push(CubeInfo({
            asset: _asset,
            symbol: _asset.symbol(),
            fees: _fees,
            times: Times({
                expiration: _expiration,
                lastUpdateBlock: 0
            }),
            totals: Totals({ 
                assetAmount: 0, 
                pendingAssetAmount: 0,
                earlyUnlockedAssetAmount: 0,
                lastAvailUpdate: 0,
                hyperTokenAmount: 0,
                avgEntryPrice: 0,
                cumulativePosition: 0,
                cumulativeRatio: 0,
                lastOperationBlock: 0
            }),
            suspendedUsersIndex: new address[](0),
            suspendedUsersCount: 0,
            managedAddress: _managedAddress,
            priceFeed: _priceFeed,
            targetPrice: _targetPrice,
            stopPrice: _stopPrice,
            lastAssetPrice: _assetPrice,
            borderPrice: _borderPrice,
            enabled: _enabled
        }));
        emit AddCube(msg.sender, _asset);
    }

    function setCube(uint256 _cubeId, Fees memory _fees, uint256 _expiration, address _managedAddress, address _priceFeed, bool _enabled) external onlyOwner validatePoolByCubeId(_cubeId) {
        require(_fees.depositFeeBP <= 10000, "E015"); // set: invalid deposit fee
        require(_fees.referralBonusBP <= 10000, "E016"); // set: invalid referral bonus
        require(_fees.maxHyperTokenRatioBP <= 10000 && _fees.minHyperTokenRatioBP >= 1000 && _fees.minHyperTokenRatioBP <= _fees.maxHyperTokenRatioBP, "E018"); // set: invalid max HYP ratio
        require(_expiration > block.timestamp, "E019"); // set: invalid expiration
        require(_managedAddress != address(0), "E020"); // set: invalid managed address
        require(_priceFeed != address(0), "E021"); // set: invalid price feed address
        CubeInfo storage cube = cubeInfo[_cubeId];
        cube.fees = _fees;
        cube.times.expiration = _expiration;
        cube.managedAddress = _managedAddress;
        cube.priceFeed = _priceFeed;
        cube.enabled = _enabled;
        emit SetCube(msg.sender, _cubeId);
    }
    
    function setBonus(uint16 _bonusID, uint256 _stepUSD, uint256 _bonusRewardBP) external onlyOwner {
        require(_bonusID < bonuses.length, "E022"); // setBonus: wrong bonus ID
        require(_bonusRewardBP <= 10000, "E023"); // setBonus: invalid bonus reward
        bonuses[_bonusID].stepUSD = _stepUSD;
        bonuses[_bonusID].bonusRewardBP = _bonusRewardBP;
        emit SetBonus(msg.sender, _bonusID, _stepUSD, _bonusRewardBP);
    }
    
    function getHyperTokenPrice() public view returns (uint256) {
        IHyperdexPair h = IHyperdexPair(hyperTokenPricePair);
        ( , uint256 price1 ) = h.getTwapPrice();
        return price1;
    }
    
    function setPriceForSuspended(uint256 _cubeId, uint256 _lastAssetPrice, uint256 _refBlockNumber) external onlyBackend validatePoolByCubeId(_cubeId) nonReentrant {
        CubeInfo storage cube = cubeInfo[_cubeId];
        require(cube.suspendedUsersIndex.length != 0, "E024"); // setPriceForSuspended: no suspended users
        uint256 updated = 0;
        uint256 totalUpdatedAssetAmount = 0;
        for (uint256 i = 0; i < cube.suspendedUsersCount; i++) {
            UserInfo storage user = userInfo[_cubeId][cube.suspendedUsersIndex[i]];
            if (user.lastOperationBlock != 0 && user.lastOperationBlock < block.timestamp && user.lastOperationBlock <= _refBlockNumber) {
                if (user.earlyUnlockedValues.assetAmount != 0) {
                    user.lastAssetPrice = _lastAssetPrice;
                    setEarlyUnlockedProfit(_cubeId, cube.suspendedUsersIndex[i], _lastAssetPrice);
                    user.avgEntryPrice = 0;
                    user.cumulativePosition = 0;
                    user.cumulativeRatio = 0;
                }
                if (user.pendingAssetAmount != 0) {
                    totalUpdatedAssetAmount = totalUpdatedAssetAmount.add(user.pendingAssetAmount);
                    uint256 leverage = 0;
                    if (cube.targetPrice > cube.stopPrice) {
                        leverage = cube.stopPrice.mul(1e8).div(_lastAssetPrice.sub(cube.stopPrice));
                    } else {
                        leverage = cube.stopPrice.mul(1e8).div(cube.stopPrice.sub(_lastAssetPrice));
                    }
                    uint256 thisPosition = user.pendingAssetAmount.mul(_lastAssetPrice).mul(leverage).div(1e26);
                    thisPosition = thisPosition.mul(cube.fees.riskLevelBP).div(10000);
                    user.cumulativePosition = user.cumulativePosition.add(thisPosition);
                    user.cumulativeRatio = user.cumulativeRatio.add(thisPosition.mul(1e18).div(_lastAssetPrice));
                    cube.totals.cumulativePosition = cube.totals.cumulativePosition.add(thisPosition);
                    cube.totals.cumulativeRatio = cube.totals.cumulativeRatio.add(thisPosition.mul(1e18).div(_lastAssetPrice));
                    user.avgEntryPrice = user.cumulativePosition.mul(1e18).div(user.cumulativeRatio);
                    user.pendingAssetAmount = 0;
                }
                user.lastOperationBlock = 0;
            }
            if (user.lastOperationBlock == 0) {
                updated++;
            }
        }
        cube.totals.pendingAssetAmount = cube.totals.pendingAssetAmount.sub(totalUpdatedAssetAmount);
        if (cube.totals.cumulativeRatio == 0) {
            cube.totals.avgEntryPrice = 0;
        } else {
            cube.totals.avgEntryPrice = cube.totals.cumulativePosition.mul(1e18).div(cube.totals.cumulativeRatio);
        }
        if (updated == cube.suspendedUsersIndex.length) {
            cube.suspendedUsersCount = 0;
        }
        emit SetPriceForSuspended(msg.sender, _cubeId, _lastAssetPrice);
    }
    
    function updateCube(uint256 _cubeId, uint256 _lastAssetPrice, bool _availUpdate) external onlyBackend validatePoolByCubeId(_cubeId) {
        CubeInfo storage cube = cubeInfo[_cubeId];
        if (block.number <= cube.times.lastUpdateBlock) {
            return;
        }
        cube.times.lastUpdateBlock = block.number;
        if (_availUpdate) {
            cube.totals.lastAvailUpdate = block.timestamp;
        }
        if (_lastAssetPrice != 0) {
            cube.lastAssetPrice = _lastAssetPrice;
            if ((cube.targetPrice > cube.stopPrice && (_lastAssetPrice >= cube.targetPrice || _lastAssetPrice <= cube.stopPrice))
                || (cube.targetPrice < cube.stopPrice && (_lastAssetPrice <= cube.targetPrice || _lastAssetPrice >= cube.stopPrice))) { 
                cube.times.expiration = block.timestamp;
                cube.enabled = false;
            }
        }
        emit UpdateCube(msg.sender, _cubeId, _lastAssetPrice, _availUpdate);
    }

    function stopCube(uint256 _cubeId, uint256 _stopType) external onlyBackend validatePoolByCubeId(_cubeId) {
        CubeInfo storage cube = cubeInfo[_cubeId];
        require(cube.enabled, "E024b"); // stopCube: cube is not enabled
        require(cube.times.expiration > block.timestamp, "E024c"); // stopCube: cube is expired
        cube.times.expiration = block.timestamp;
        if (_stopType == 1) {
            cube.lastAssetPrice = cube.targetPrice;
        } else if (_stopType == 2) {
            cube.lastAssetPrice = cube.stopPrice;
        }
        emit StopCube(msg.sender, _cubeId, _stopType);
    }
    
    function extractToken(IBEP20 _asset, address _to, uint256 _amount) external onlyOwner nonReentrant {
        _asset.safeTransfer(_to, _amount);
        emit ExtractToken(msg.sender, _asset, _to, _amount);
    }
    
    function extractBNB(address payable _to, uint256 _amount) external payable onlyOwner nonReentrant {
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "E025"); // Failed to send BNB
        emit ExtractBNB(msg.sender, _to, _amount);
    }
    
    function getInfo() external view returns (address _backendAddress, address _hyperToken, uint256 _hyperTokenPrice) {
        return (backendAddress, address(hyperToken), getHyperTokenPrice());
    }
    
    // Cube
    
    function getLatestPrice(uint256 _cubeId) private view returns (uint256) {
        CubeInfo storage cube = cubeInfo[_cubeId];
        AggregatorV3Interface pf = AggregatorV3Interface(cube.priceFeed);
	    (, int256 price, , ,) = pf.latestRoundData();
        uint256 decimals = 18 - uint256(pf.decimals());
        return uint256(price).mul(10**decimals);
    }
    
    function getAUM() external view returns (uint256 totalUsdAUM) {
        uint256 total = 0;
        uint256 hyperTokenPrice = getHyperTokenPrice();
        for (uint256 id = 0; id < cubeInfo.length; id++) {
            total = total.add(cubeInfo[id].totals.assetAmount.mul(getLatestPrice(id)).div(1e18));
            total = total.add(cubeInfo[id].totals.hyperTokenAmount.mul(hyperTokenPrice).div(1e18));
        }
        return total;
    }
    
    // User
    
    function invest(uint256 _cubeId, uint256 _amount, uint256 _hyperTokenAmount, address _referral) external nonReentrant isEnabled validatePoolByCubeId(_cubeId) {
        require(_amount != 0, "E026"); // invest: amount is zero.
        CubeInfo storage cube = cubeInfo[_cubeId];
        require(cube.enabled, "E028"); // invest: cube is not enabled
        require(cube.times.expiration > block.timestamp, "E028b"); // invest: cube is expired
        UserInfo storage user = userInfo[_cubeId][msg.sender];
        require(user.earlyUnlockedValues.assetAmount == 0, "E028c"); // invest: previous early unlock still pending
        if (_referral != address(0)) {
            require(!user.referralUsed, "E029"); // invest: referral bonus already used
            require(_referral != msg.sender, "E030"); // invest: referral cannot be the sender
        }
        uint256 assetPriceUSD = getLatestPrice(_cubeId);
        require((cube.targetPrice > cube.stopPrice && assetPriceUSD > cube.borderPrice) || (assetPriceUSD < cube.borderPrice), "E030b"); // invest: asset price under/over limit (too high risk)
        uint256 hyperTokenPrice = getHyperTokenPrice();
        if (_hyperTokenAmount != 0) {
            uint256 ratioBP = _hyperTokenAmount.mul(hyperTokenPrice).mul(10000).div(_amount).div(assetPriceUSD);
            require(ratioBP >= cube.fees.minHyperTokenRatioBP, "E031"); // invest: hyperTokenAmount under minimum
            require(ratioBP <= cube.fees.maxHyperTokenRatioBP, "E032"); // invest: hyperTokenAmount over maximum
        }
        uint256 fee;
        if (!user.referralUsed && _referral != address(0) && cube.fees.referralBonusBP != 0) {
            fee = _amount.mul(cube.fees.referralBonusBP);
            fee = fee.mul(assetPriceUSD).div(hyperTokenPrice).div(10000);
            if (_hyperTokenAmount != 0) {
                fee = fee.add(_hyperTokenAmount.mul(cube.fees.referralBonusBP).div(10000));
            }
            hyperToken.mint(_referral, fee);
            user.referralBonusBP = cube.fees.referralBonusBP;
            user.referralUsed = true;
        }
        if (cube.fees.depositFeeBP > 0) {
            fee = _amount.mul(cube.fees.depositFeeBP).div(10000);
            cube.asset.safeTransferFrom(address(msg.sender), backendAddress, fee);
            _amount = _amount.sub(fee);
        }
        cube.asset.safeTransferFrom(address(msg.sender), cube.managedAddress, _amount);
        uint256 newAmount = user.assetAmount.add(_amount);
        uint256 newCubeAmount = cube.totals.assetAmount.add(_amount);
        user.assetAmount = newAmount;
        cube.totals.assetAmount = newCubeAmount;
        cube.totals.pendingAssetAmount = cube.totals.pendingAssetAmount.add(_amount);
        user.bonusRewardBP = getBonusRewardBP(newAmount.mul(assetPriceUSD).div(1e18));
        if (_hyperTokenAmount != 0) {
            bool transferOK = true;
            if (cube.fees.depositFeeBP > 0) {
                uint256 depositFee = _hyperTokenAmount.mul(cube.fees.depositFeeBP).div(10000);
                transferOK = hyperToken.transferFrom(address(msg.sender), backendAddress, depositFee);
                _hyperTokenAmount = _hyperTokenAmount.sub(depositFee);
            }
            transferOK = transferOK && hyperToken.transferFrom(address(msg.sender), address(this), _hyperTokenAmount);
            require(transferOK, "E032b");
            user.hyperTokenAmount = user.hyperTokenAmount.add(_hyperTokenAmount);
            uint256 hyperTokenAmountUSD = _hyperTokenAmount.mul(hyperTokenPrice).div(1e18);
            user.hyperTokenUSDvalue = user.hyperTokenUSDvalue.add(hyperTokenAmountUSD);
            cube.totals.hyperTokenAmount = cube.totals.hyperTokenAmount.add(_hyperTokenAmount);
        }
        user.ledgerEntries.push(LedgerEntry({
            timestamp: uint240(block.timestamp),
            operationType: 1,
            assetAmount: _amount,
            profitAmount: 0,
            lossAmount: 0,
            hyperTokenAmount: _hyperTokenAmount,
            hyperTokenProfitBase: 0,
            hyperTokenProfitBonus: 0,
            assetPrice: assetPriceUSD,
            hyperTokenPrice: hyperTokenPrice
        }));
        user.lastOperationBlock = block.number;
        if (!suspendedUserExists(_cubeId, msg.sender)) {
            if (cube.suspendedUsersCount >= cube.suspendedUsersIndex.length) {
                cube.suspendedUsersIndex.push(msg.sender);
            } else {
                cube.suspendedUsersIndex[cube.suspendedUsersCount] = msg.sender;
            }
            cube.suspendedUsersCount++;
        }
        user.pendingAssetAmount = user.pendingAssetAmount.add(_amount);
        cube.totals.lastOperationBlock = block.number;
        emit Invest(msg.sender, _cubeId, _amount, _hyperTokenAmount);
    }
    
    function earlyUnlockAmount(uint256 _cubeId) external nonReentrant isEnabled validatePoolByCubeId(_cubeId) {
        CubeInfo storage cube = cubeInfo[_cubeId];
        require(block.timestamp < cube.times.expiration, "E033b"); // cube expired
        UserInfo storage user = userInfo[_cubeId][msg.sender];
        require(user.avgEntryPrice != 0, "E034"); // unlockAmount: pending investment
        require(user.earlyUnlockedValues.assetAmount == 0, "E035"); // earlyUnlockAmount: previous early unlock still pending
        require(user.pendingAssetAmount == 0, "E035b"); // earlyUnlockAmount: previous invest() still pending
        user.nextWithdrawalAllowed = block.timestamp;
        user.earlyUnlockedValues.assetAmount = user.assetAmount.mul(cube.fees.guaranteedBP).div(10000);
        user.earlyUnlockedValues.cumulativePosition = user.cumulativePosition.mul(cube.fees.guaranteedBP).div(10000);
        user.earlyUnlockedValues.hyperTokenAmount = user.hyperTokenAmount.mul(cube.fees.guaranteedBP).div(10000);
        user.earlyUnlockedValues.hyperTokenAmountUSD = user.hyperTokenUSDvalue.mul(cube.fees.guaranteedBP).div(10000);
        cube.totals.earlyUnlockedAssetAmount = cube.totals.earlyUnlockedAssetAmount.add(user.assetAmount.mul(cube.fees.guaranteedBP).div(10000));
        cube.totals.assetAmount = cube.totals.assetAmount.sub(user.assetAmount);
        cube.totals.cumulativePosition = cube.totals.cumulativePosition.sub(user.cumulativePosition);
        cube.totals.cumulativeRatio = cube.totals.cumulativeRatio.sub(user.cumulativeRatio);
        cube.totals.hyperTokenAmount = cube.totals.hyperTokenAmount.sub(user.hyperTokenAmount);
        user.ledgerEntries.push(LedgerEntry({
            timestamp: uint240(block.timestamp),
            operationType: 4,
            assetAmount: user.assetAmount.mul(cube.fees.guaranteedBP).div(10000),
            profitAmount: 0,
            lossAmount: 0,
            hyperTokenAmount: user.hyperTokenAmount.mul(cube.fees.guaranteedBP).div(10000),
            hyperTokenProfitBase: 0,
            hyperTokenProfitBonus: 0,
            assetPrice: getLatestPrice(_cubeId),
            hyperTokenPrice: getHyperTokenPrice()
        }));
        user.lastOperationBlock = block.number;
        if (!suspendedUserExists(_cubeId, msg.sender)) {
            if (cube.suspendedUsersCount >= cube.suspendedUsersIndex.length) {
                cube.suspendedUsersIndex.push(msg.sender);
            } else {
                cube.suspendedUsersIndex[cube.suspendedUsersCount] = msg.sender;
            }
            cube.suspendedUsersCount++;
        }
        uint256 amount = user.assetAmount;
        user.assetAmount = 0;
        user.cumulativePosition = 0;
        user.cumulativeRatio = 0;
        user.hyperTokenAmount = 0;
        user.hyperTokenUSDvalue = 0;
        cube.totals.lastOperationBlock = block.number;
        emit EarlyUnlockAmount(msg.sender, _cubeId, amount);
    }
    
    function withdraw(uint256 _cubeId) external nonReentrant isEnabled validatePoolByCubeId(_cubeId) {
        CubeInfo storage cube = cubeInfo[_cubeId];
        UserInfo storage user = userInfo[_cubeId][msg.sender];
        require(canWithdraw(_cubeId, msg.sender), "E037"); // withdraw: not allowed by lock time
        require(fundsAvailable(_cubeId, msg.sender), "E038"); // withdraw: waiting for funds
        ProfitInfo memory localProfitInfo = getActualProfit(_cubeId, msg.sender);
        uint256 withdrawAmount = user.earlyUnlockedValues.assetAmount.add(user.earlyUnlockedValues.assetProfit).sub(user.earlyUnlockedValues.assetLoss);
        if (block.timestamp > cube.times.expiration) {
            withdrawAmount = withdrawAmount.add(user.assetAmount).add(localProfitInfo.profitDetail.assetProfit).sub(localProfitInfo.profitDetail.assetLoss);
        }
        require(cube.asset.balanceOf(address(this)) >= withdrawAmount, "E039"); // withdraw: waiting for asset funds
        uint256 hyperTokenProfit = user.earlyUnlockedValues.hyperTokenProfitBase.add(user.earlyUnlockedValues.hyperTokenProfitBonus);
        if (block.timestamp > cube.times.expiration) {
            hyperTokenProfit = hyperTokenProfit.add(localProfitInfo.profitDetail.hyperTokenProfitBase).add(localProfitInfo.profitDetail.hyperTokenProfitBonus);
        }
        uint256 hyperTokenWithdrawAmount = user.earlyUnlockedValues.hyperTokenAmount;
        if (block.timestamp > cube.times.expiration) {
            hyperTokenWithdrawAmount = hyperTokenWithdrawAmount.add(user.hyperTokenAmount);
        }
        require(hyperToken.balanceOf(address(this)) >= hyperTokenWithdrawAmount, "E040"); // withdraw: waiting for HYP funds
        user.ledgerEntries.push(LedgerEntry({
            timestamp: uint240(block.timestamp),
            operationType: 2,
            assetAmount: withdrawAmount,
            profitAmount: user.earlyUnlockedValues.assetProfit.add(localProfitInfo.profitDetail.assetProfit),
            lossAmount: user.earlyUnlockedValues.assetLoss.add(localProfitInfo.profitDetail.assetLoss),
            hyperTokenAmount: hyperTokenWithdrawAmount,
            hyperTokenProfitBase: user.earlyUnlockedValues.hyperTokenProfitBase.add(localProfitInfo.profitDetail.hyperTokenProfitBase),
            hyperTokenProfitBonus: user.earlyUnlockedValues.hyperTokenProfitBonus.add(localProfitInfo.profitDetail.hyperTokenProfitBonus),
            assetPrice: getLatestPrice(_cubeId),
            hyperTokenPrice: getHyperTokenPrice()
        }));
        if (block.timestamp >= user.nextWithdrawalAllowed && user.nextWithdrawalAllowed != 0) {
            cube.totals.earlyUnlockedAssetAmount = cube.totals.earlyUnlockedAssetAmount.sub(user.earlyUnlockedValues.assetAmount.add(user.earlyUnlockedValues.assetProfit).sub(user.earlyUnlockedValues.assetLoss));
            user.earlyUnlockedValues = Unlocked({
                assetAmount: 0,
                cumulativePosition: 0, 
                assetProfit: 0,
                assetLoss: 0,
                hyperTokenAmount: 0,
                hyperTokenAmountUSD: 0,
                hyperTokenProfitBase: 0,
                hyperTokenProfitBonus: 0
            });
            user.nextWithdrawalAllowed = 0;
        }
        if (block.timestamp > cube.times.expiration) {
            cube.totals.assetAmount = cube.totals.assetAmount.sub(user.assetAmount);
            cube.totals.hyperTokenAmount = cube.totals.hyperTokenAmount.sub(user.hyperTokenAmount);
            cube.totals.cumulativePosition = cube.totals.cumulativePosition.sub(user.cumulativePosition);
            cube.totals.cumulativeRatio = cube.totals.cumulativeRatio.sub(user.cumulativeRatio);
            user.avgEntryPrice = 0;
            user.cumulativePosition = 0;
            user.cumulativeRatio = 0;
            user.hyperTokenAmount = 0;
            user.hyperTokenUSDvalue = 0;
            user.assetAmount = 0;
        }
        user.referralBonusBP = 0;
        user.lastAssetPrice = 0;
        if (withdrawAmount != 0) {
            cube.asset.safeTransfer(address(msg.sender), withdrawAmount);
        }
        if (hyperTokenProfit != 0) {
            hyperToken.mint(address(msg.sender), hyperTokenProfit);
        }
        if (hyperTokenWithdrawAmount != 0) {
            hyperToken.transfer(address(msg.sender), hyperTokenWithdrawAmount);
        }
        emit Withdraw(msg.sender, _cubeId, withdrawAmount);
    }

    function getProfitLoss(bool _long, uint256 _position, uint256 _entryPrice, uint256 _closePrice) private pure returns (uint256 baseProfit, uint256 baseLoss) {
        baseProfit = 0;
        baseLoss = 0;
        if (_entryPrice != 0 && _closePrice != 0) {
            if (_long && _closePrice >= _entryPrice) {
                baseProfit = (_position.mul(1e18).div(_entryPrice)).sub(_position.mul(1e18).div(_closePrice));
            } else if (_long && _closePrice < _entryPrice) {
                baseLoss = (_position.mul(1e18).div(_closePrice)).sub(_position.mul(1e18).div(_entryPrice));
            } else if (!_long && _closePrice < _entryPrice) {
                baseProfit = (_position.mul(1e18).div(_closePrice)).sub(_position.mul(1e18).div(_entryPrice));
            } else if (!_long && _closePrice >= _entryPrice) {
                baseLoss = (_position.mul(1e18).div(_entryPrice)).sub(_position.mul(1e18).div(_closePrice));
            }
        }
        return (baseProfit, baseLoss);
    }
    
    function setEarlyUnlockedProfit(uint256 _cubeId, address _user, uint256 _price) private {
        CubeInfo storage cube = cubeInfo[_cubeId];
        UserInfo storage user = userInfo[_cubeId][_user];
        uint256 assetPriceUSD = getLatestPrice(_cubeId);
        uint256 hyperTokenPrice = getHyperTokenPrice();
        (uint256 baseProfit, uint256 baseLoss) = getProfitLoss(cube.targetPrice > cube.stopPrice, user.earlyUnlockedValues.cumulativePosition, user.avgEntryPrice, _price);
        if (baseLoss > user.earlyUnlockedValues.assetAmount) {
            baseLoss = user.earlyUnlockedValues.assetAmount;
        }
        user.earlyUnlockedValues.assetProfit = baseProfit;
        user.earlyUnlockedValues.assetLoss = baseLoss;
        cube.totals.earlyUnlockedAssetAmount = cube.totals.earlyUnlockedAssetAmount.add(baseProfit).sub(baseLoss);
        if (user.hyperTokenAmount == 0) {
            if (hyperTokenPrice != 0) {
                user.earlyUnlockedValues.hyperTokenProfitBonus = baseProfit.mul(assetPriceUSD).mul(user.bonusRewardBP.add(user.referralBonusBP)).div(hyperTokenPrice).div(10000);
            }
        } else {
            uint256 profitBP = baseProfit.mul(10000).div(user.earlyUnlockedValues.assetAmount);
            uint256 baseHyperTokenProfit = user.hyperTokenUSDvalue.mul(profitBP).mul(1e18).div(hyperTokenPrice).div(10000);
            uint256 bonusHyperTokenProfit = baseHyperTokenProfit.mul(user.bonusRewardBP.add(user.referralBonusBP)).div(10000);
            user.earlyUnlockedValues.hyperTokenProfitBase = baseHyperTokenProfit;
            user.earlyUnlockedValues.hyperTokenProfitBonus = bonusHyperTokenProfit;
        }
    }

    function getActualProfit(uint256 _cubeId, address _user) public view returns (ProfitInfo memory profitInfo) {
        CubeInfo storage cube = cubeInfo[_cubeId];
        UserInfo storage user = userInfo[_cubeId][_user];
        ProfitInfo memory localProfitInfo = ProfitInfo({
            assetInvestment: user.assetAmount,
            profitDetail: ProfitDetail({
                assetProfit: 0,
                assetLoss: 0,
                hyperTokenProfitBase: 0,
                hyperTokenProfitBonus: 0
            }),
            hyperTokenInvestment: user.hyperTokenAmount,
            hyperTokenInvestmentUSD: user.hyperTokenUSDvalue,
            userElapsed: 0,
            secondsToExpiration: 0,
            assetPriceUSD: 0,
            hyperTokenPrice: getHyperTokenPrice()
        });
        uint256 assetPriceUSD = getLatestPrice(_cubeId);
        uint256 lastAssetPrice = user.lastAssetPrice;
        if (block.timestamp > cube.times.expiration) {
            lastAssetPrice = cube.lastAssetPrice;
        } else {
            localProfitInfo.secondsToExpiration = cube.times.expiration - block.timestamp;
        }
        localProfitInfo.assetPriceUSD = assetPriceUSD;
        localProfitInfo.hyperTokenPrice = getHyperTokenPrice();
        if (lastAssetPrice == 0 || user.assetAmount == 0 || user.avgEntryPrice == 0) {
            return localProfitInfo;
        }
        (uint256 baseProfit, uint256 baseLoss) = getProfitLoss(cube.targetPrice > cube.stopPrice, user.cumulativePosition, user.avgEntryPrice, lastAssetPrice);
        if (baseLoss > user.assetAmount) {
            baseLoss = user.assetAmount;
        }
        localProfitInfo.profitDetail.assetProfit = baseProfit;
        localProfitInfo.profitDetail.assetLoss = baseLoss;
        if (user.hyperTokenAmount == 0) {
            if (localProfitInfo.hyperTokenPrice != 0) {
                localProfitInfo.profitDetail.hyperTokenProfitBonus = localProfitInfo.profitDetail.assetProfit.mul(localProfitInfo.assetPriceUSD).mul(user.bonusRewardBP.add(user.referralBonusBP)).div(localProfitInfo.hyperTokenPrice).div(10000);
            }            
        } else if (localProfitInfo.hyperTokenPrice != 0) {
            uint256 profitBP = baseProfit.mul(10000).div(user.assetAmount);
            uint256 baseHyperTokenProfit = user.hyperTokenUSDvalue.mul(profitBP).mul(1e18).div(localProfitInfo.hyperTokenPrice).div(10000);
            uint256 bonusHyperTokenProfit = baseHyperTokenProfit.mul(user.bonusRewardBP.add(user.referralBonusBP)).div(10000);
            localProfitInfo.profitDetail.hyperTokenProfitBase = baseHyperTokenProfit;
            localProfitInfo.profitDetail.hyperTokenProfitBonus = bonusHyperTokenProfit;
        }
        return localProfitInfo;
    }
    
    function getTotalUserActualProfit(address _user) external view returns (uint256 usdInvestment, uint256 usdProfit, uint256 usdLoss, uint256 hyperTokenProfitBase, uint256 hyperTokenProfitBonus) {
        for (uint256 id = 0; id < cubeInfo.length; id++) {
            ProfitInfo memory profitInfo = getActualProfit(id, _user);
            usdInvestment = usdInvestment.add(profitInfo.assetInvestment.mul(profitInfo.assetPriceUSD).div(1e18));
            usdProfit = usdProfit.add(profitInfo.profitDetail.assetProfit.mul(profitInfo.assetPriceUSD).div(1e18));
            usdLoss = usdLoss.add(profitInfo.profitDetail.assetLoss.mul(profitInfo.assetPriceUSD).div(1e18));
            hyperTokenProfitBase = hyperTokenProfitBase.add(profitInfo.profitDetail.hyperTokenProfitBase);
            hyperTokenProfitBonus = hyperTokenProfitBonus.add(profitInfo.profitDetail.hyperTokenProfitBonus);
        }
        return (usdInvestment, usdProfit, usdLoss, hyperTokenProfitBase, hyperTokenProfitBonus);
    }
    
    function getLedgerEntries(uint256 _cubeId, address _user, uint256 _backLimit, uint256 _backStep) external view 
        returns (uint256 totalLedgerEntriesCount, uint256 thisListCount, LedgerEntry[] memory ledgerEntriesList) {
        UserInfo storage user = userInfo[_cubeId][_user];
        uint256 start = 0;
        uint256 end = 0;
        if (_backStep + _backLimit >= user.ledgerEntries.length) {
            start = 0;
            end = user.ledgerEntries.length;
        } else {
            start = user.ledgerEntries.length - _backStep - _backLimit;
            end = user.ledgerEntries.length - _backStep;
            
        }
        uint256 count = end - start;
        LedgerEntry[] memory le = new LedgerEntry[](count);
        if (count > 0) {
            count = 0;
            for (uint256 t = start; t < end; t++) {
                le[count] = user.ledgerEntries[t];
                count++;
            }
        }
        return (user.ledgerEntries.length, le.length, le);
    }
    
    // Misc

    function canWithdraw(uint256 _cubeId, address _user) public view returns (bool) {
        CubeInfo storage cube = cubeInfo[_cubeId];
        UserInfo storage user = userInfo[_cubeId][_user];
        if (user.earlyUnlockedValues.assetAmount != 0 && user.lastAssetPrice == 0) {
            return false;
        }
        bool expiredPrice = (cube.targetPrice > cube.stopPrice && (cube.lastAssetPrice >= cube.targetPrice || cube.lastAssetPrice <= cube.stopPrice))
            || (cube.targetPrice < cube.stopPrice && (cube.lastAssetPrice <= cube.targetPrice || cube.lastAssetPrice >= cube.stopPrice));        
        return ((block.timestamp >= user.nextWithdrawalAllowed) && user.nextWithdrawalAllowed != 0) || (block.timestamp >= cube.times.expiration) || expiredPrice;
    }
    
    function fundsAvailable(uint256 _cubeId, address _user) public view returns (bool) {
        CubeInfo storage cube = cubeInfo[_cubeId];
        UserInfo storage user = userInfo[_cubeId][_user];
        return (cube.totals.lastAvailUpdate > user.nextWithdrawalAllowed || cube.totals.lastAvailUpdate > cube.times.expiration);
    }
    
    function suspendedUserExists(uint256 _cubeId, address _user) public view returns (bool) {
        CubeInfo storage cube = cubeInfo[_cubeId];
        if (cube.suspendedUsersCount == 0) return false;
        uint256 usersCount = cube.suspendedUsersIndex.length;
        if (cube.suspendedUsersCount < usersCount) {
            usersCount = cube.suspendedUsersCount;
        }
        for (uint t = 0; t < usersCount; t++) {
            if (cube.suspendedUsersIndex[t] == _user) {
                return true;
            }
        }
        return false;
    }
    
    function getBonusRewardBP(uint256 _usdValue) private view returns (uint256) {
        for (uint256 id = bonuses.length; id > 0; id--) {
            if (_usdValue > bonuses[id - 1].stepUSD) {
                return bonuses[id - 1].bonusRewardBP;
            }
        }
        return 0;
    }
    
    function getUsdValue(uint256 _cubeId, uint256 _amount) public view returns (uint256) {
        uint256 price = getLatestPrice(_cubeId);
        return price.mul(_amount).div(1e18);
    }
}