/**
 *Submitted for verification at Etherscan.io on 2023-09-10
*/

// Dependency file: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/Context.sol";

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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


// Dependency file: @openzeppelin/contracts/access/Ownable2Step.sol

// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable2Step.sol)

// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}


// Dependency file: @openzeppelin/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol

// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

// pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}


// Dependency file: @openzeppelin/contracts/utils/Address.sol

// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

// pragma solidity ^0.8.1;

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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


// Dependency file: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol

// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
// import "@openzeppelin/contracts/utils/Address.sol";

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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
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
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}


// Dependency file: contracts/interfaces/IPermit2.sol


// pragma solidity 0.8.18;

interface IPermit2 {

  struct PermitDetails {
    address token;
    uint160 amount;
    uint48 expiration;
    uint48 nonce;
  }

  struct PermitSingle {
    PermitDetails details;
    address spender;
    uint256 sigDeadline;
  }

  function permit(address owner, PermitSingle memory permitSingle, bytes calldata signature) external;

  function transferFrom(address from, address to, uint160 amount, address token) external;

  function allowance(address user, address token, address spender) external view returns (uint160 amount, uint48 expiration, uint48 nonce);

}


// Dependency file: contracts/interfaces/IDePayRouterV2.sol


// pragma solidity 0.8.18;

// import 'contracts/interfaces/IPermit2.sol';

interface IDePayRouterV2 {

  struct Payment {
    uint256 amountIn;
    bool permit2;
    uint256 paymentAmount;
    uint256 feeAmount;
    address tokenInAddress;
    address exchangeAddress;
    address tokenOutAddress;
    address paymentReceiverAddress;
    address feeReceiverAddress;
    uint8 exchangeType;
    uint8 receiverType;
    bytes exchangeCallData;
    bytes receiverCallData;
    uint256 deadline;
  }

  function pay(
    Payment calldata payment
  ) external payable returns(bool);

  function pay(
    IDePayRouterV2.Payment calldata payment,
    IPermit2.PermitSingle memory permitSingle,
    bytes calldata signature
  ) external payable returns(bool);

  event Enabled(
    address indexed exchange
  );

  event Disabled(
    address indexed exchange
  );

  function enable(address exchange, bool enabled) external returns(bool);

  function withdraw(address token, uint amount) external returns(bool);

}


// Dependency file: contracts/interfaces/IDePayForwarderV2.sol


// pragma solidity 0.8.18;

// import 'contracts/interfaces/IDePayRouterV2.sol';

interface IDePayForwarderV2 {

  function forward(
    IDePayRouterV2.Payment calldata payment
  ) external payable returns(bool);

  function toggle(bool stop) external returns(bool);

}


// Root file: contracts/DePayRouterV2.sol


pragma solidity 0.8.18;

// import "@openzeppelin/contracts/access/Ownable2Step.sol";
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// import 'contracts/interfaces/IPermit2.sol';
// import 'contracts/interfaces/IDePayRouterV2.sol';
// import 'contracts/interfaces/IDePayForwarderV2.sol';

/// @title DePayRouterV2
/// @notice This contract handles payments and token conversions.
/// @dev Inherit from Ownable2Step for ownership functionalities.
contract DePayRouterV2 is Ownable2Step {

  using SafeERC20 for IERC20;

  // Custom errors
  error PaymentDeadlineReached();
  error WrongAmountPaidIn();
  error ExchangeNotApproved();
  error ExchangeCallMissing();
  error ExchangeCallFailed();
  error ForwardingPaymentFailed();
  error NativePaymentFailed();
  error NativeFeePaymentFailed();
  error PaymentToZeroAddressNotAllowed();
  error InsufficientBalanceInAfterPayment();
  error InsufficientBalanceOutAfterPayment();

  /// @notice Address representing the NATIVE token (e.g. ETH, BNB, MATIC, etc.)
  address constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  /// @notice Address of PERMIT2
  address public immutable PERMIT2;

  /// @notice Address of the payment FORWARDER contract
  address public immutable FORWARDER;

  /// @notice List of approved exchanges for conversion.
  mapping (address => bool) public exchanges;

  /// @dev Initializes the contract with PERMIT2 and FORWARDER addresses.
  /// @param _PERMIT2 The address of the PERMIT2 contract.
  /// @param _FORWARDER The address of the FORWARDER contract.
  constructor (address _PERMIT2, address _FORWARDER) {
    PERMIT2 = _PERMIT2;
    FORWARDER = _FORWARDER;
  }

  /// @notice Accepts NATIVE payments, which is required in order to swap from and to NATIVE, especially unwrapping as part of conversions.
  receive() external payable {}

  /// @dev Transfer polyfil event for internal transfers.
  event InternalTransfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  /// @dev Handles the payment process (tokenIn approval has been granted prior).
  /// @param payment The payment data.
  /// @return Returns true if successful.
  function _pay(
    IDePayRouterV2.Payment calldata payment
  ) internal returns(bool){
    uint256 balanceInBefore;
    uint256 balanceOutBefore;

    (balanceInBefore, balanceOutBefore) = _validatePreConditions(payment);
    _payIn(payment);
    _performPayment(payment);
    _validatePostConditions(payment, balanceInBefore, balanceOutBefore);

    return true;
  }

  /// @notice Handles the payment process for external callers.
  /// @param payment The payment data.
  /// @return Returns true if successful.
  function pay(
    IDePayRouterV2.Payment calldata payment
  ) external payable returns(bool){
    return _pay(payment);
  }

  /// @dev Handles the payment process with permit2 approval (internal).
  /// @param payment The payment data.
  /// @param permitSingle The permit single data.
  /// @param signature The permit signature.
  /// @return Returns true if successful.
  function _pay(
    IDePayRouterV2.Payment calldata payment,
    IPermit2.PermitSingle memory permitSingle,
    bytes calldata signature
  ) internal returns(bool){
    uint256 balanceInBefore;
    uint256 balanceOutBefore;

    (balanceInBefore, balanceOutBefore) = _validatePreConditions(payment);
    _permit(permitSingle, signature);
    _payIn(payment);
    _performPayment(payment);
    _validatePostConditions(payment, balanceInBefore, balanceOutBefore);

    return true;
  }

  /// @notice Handles the payment process with permit2 approval for external callers.
  /// @param payment The payment data.
  /// @param permitSingle The permit single data.
  /// @param signature The permit signature.
  /// @return Returns true if successful.
  function pay(
    IDePayRouterV2.Payment calldata payment,
    IPermit2.PermitSingle memory permitSingle,
    bytes calldata signature
  ) external payable returns(bool){
    return _pay(payment, permitSingle, signature);
  }

  /// @dev Validates the pre-conditions for a payment.
  /// @param payment The payment data.
  /// @return balanceInBefore The balance in before the payment.
  /// @return balanceOutBefore The balance out before the payment.
  function _validatePreConditions(IDePayRouterV2.Payment calldata payment) internal returns(uint256 balanceInBefore, uint256 balanceOutBefore) {
    // Make sure payment deadline has not been passed, yet
    if(payment.deadline < block.timestamp) {
      revert PaymentDeadlineReached();
    }

    // Store tokenIn balance prior to payment
    if(payment.tokenInAddress == NATIVE) {
      balanceInBefore = address(this).balance - msg.value;
    } else {
      balanceInBefore = IERC20(payment.tokenInAddress).balanceOf(address(this));
    }

    // Store tokenOut balance prior to payment
    if(payment.tokenOutAddress == NATIVE) {
      balanceOutBefore = address(this).balance - msg.value;
    } else {
      balanceOutBefore = IERC20(payment.tokenOutAddress).balanceOf(address(this));
    }
  }

  /// @dev Handles permit2 operations.
  /// @param permitSingle The permit single data.
  /// @param signature The permit signature.
  function _permit(
    IPermit2.PermitSingle memory permitSingle,
    bytes calldata signature
  ) internal {

    IPermit2(PERMIT2).permit(
      msg.sender, // owner
      permitSingle,
      signature
    );
  }

  /// @dev Processes the payIn operations.
  /// @param payment The payment data.
  function _payIn(
    IDePayRouterV2.Payment calldata payment
  ) internal {
    // Make sure that the sender has paid in the correct token & amount
    if(payment.tokenInAddress == NATIVE) {
      if(msg.value != payment.amountIn) {
        revert WrongAmountPaidIn();
      }
    } else if(payment.permit2) {
      IPermit2(PERMIT2).transferFrom(msg.sender, address(this), uint160(payment.amountIn), payment.tokenInAddress);
    } else {
      IERC20(payment.tokenInAddress).safeTransferFrom(msg.sender, address(this), payment.amountIn);
    }
  }

  /// @dev Processes the payment.
  /// @param payment The payment data.
  function _performPayment(IDePayRouterV2.Payment calldata payment) internal {
    // Perform conversion if required
    if(payment.exchangeAddress != address(0)) {
      _convert(payment);
    }

    // Perform payment to paymentReceiver
    _payReceiver(payment);

    // Perform payment to feeReceiver
    if(payment.feeReceiverAddress != address(0)) {
      _payFee(payment);
    }
  }

  /// @dev Validates the post-conditions for a payment.
  /// @param payment The payment data.
  /// @param balanceInBefore The balance in before the payment.
  /// @param balanceOutBefore The balance out before the payment.
  function _validatePostConditions(IDePayRouterV2.Payment calldata payment, uint256 balanceInBefore, uint256 balanceOutBefore) internal view {
    // Ensure balances of tokenIn remained
    if(payment.tokenInAddress == NATIVE) {
      if(address(this).balance < balanceInBefore) {
        revert InsufficientBalanceInAfterPayment();
      }
    } else {
      if(IERC20(payment.tokenInAddress).balanceOf(address(this)) < balanceInBefore) {
        revert InsufficientBalanceInAfterPayment();
      }
    }

    // Ensure balances of tokenOut remained
    if(payment.tokenOutAddress == NATIVE) {
      if(address(this).balance < balanceOutBefore) {
        revert InsufficientBalanceOutAfterPayment();
      }
    } else {
      if(IERC20(payment.tokenOutAddress).balanceOf(address(this)) < balanceOutBefore) {
        revert InsufficientBalanceOutAfterPayment();
      }
    }
  }

  /// @dev Handles token conversions.
  /// @param payment The payment data.
  function _convert(IDePayRouterV2.Payment calldata payment) internal {
    if(!exchanges[payment.exchangeAddress]) {
      revert ExchangeNotApproved();
    }
    bool success;
    if(payment.tokenInAddress == NATIVE) {
      if(payment.exchangeCallData.length == 0) {
        revert ExchangeCallMissing();
      }
      (success,) = payment.exchangeAddress.call{value: msg.value}(payment.exchangeCallData);
    } else {
      if(payment.exchangeType == 1) { // pull
        IERC20(payment.tokenInAddress).safeApprove(payment.exchangeAddress, payment.amountIn);
      } else if(payment.exchangeType == 2) { // push
        IERC20(payment.tokenInAddress).safeTransfer(payment.exchangeAddress, payment.amountIn);
      }
      (success,) = payment.exchangeAddress.call(payment.exchangeCallData);
      if(payment.exchangeType == 1) { // pull
        IERC20(payment.tokenInAddress).safeApprove(payment.exchangeAddress, 0);
      }
    }
    if(!success){
      revert ExchangeCallFailed();
    }
  }

  /// @dev Processes payment to receiver.
  /// @param payment The payment data.
  function _payReceiver(IDePayRouterV2.Payment calldata payment) internal {
    if(payment.receiverType != 0) { // call receiver contract

      {
        bool success;
        if(payment.tokenOutAddress == NATIVE) {
          success = IDePayForwarderV2(FORWARDER).forward{value: payment.paymentAmount}(payment);
          emit InternalTransfer(msg.sender, payment.paymentReceiverAddress, payment.paymentAmount);
        } else {
          IERC20(payment.tokenOutAddress).safeTransfer(FORWARDER, payment.paymentAmount);
          success = IDePayForwarderV2(FORWARDER).forward(payment);
        }
        if(!success) {
          revert ForwardingPaymentFailed();
        }
      }

    } else { // just send payment to address

      if(payment.tokenOutAddress == NATIVE) {
        if(payment.paymentReceiverAddress == address(0)){
          revert PaymentToZeroAddressNotAllowed();
        }
        (bool success,) = payment.paymentReceiverAddress.call{value: payment.paymentAmount}(new bytes(0));
        if(!success) {
          revert NativePaymentFailed();
        }
        emit InternalTransfer(msg.sender, payment.paymentReceiverAddress, payment.paymentAmount);
      } else {
        IERC20(payment.tokenOutAddress).safeTransfer(payment.paymentReceiverAddress, payment.paymentAmount);
      }
    }
  }

  /// @dev Processes fee payments.
  /// @param payment The payment data.
  function _payFee(IDePayRouterV2.Payment calldata payment) internal {
    if(payment.tokenOutAddress == NATIVE) {
      (bool success,) = payment.feeReceiverAddress.call{value: payment.feeAmount}(new bytes(0));
      if(!success) {
        revert NativeFeePaymentFailed();
      }
      emit InternalTransfer(msg.sender, payment.feeReceiverAddress, payment.feeAmount);
    } else {
      IERC20(payment.tokenOutAddress).safeTransfer(payment.feeReceiverAddress, payment.feeAmount);
    }
  }

  /// @dev Event emitted if new exchange has been enabled.
  event Enabled(
    address indexed exchange
  );

  /// @dev Event emitted if an exchange has been disabled.
  event Disabled(
    address indexed exchange
  );

  /// @notice Enables or disables an exchange.
  /// @param exchange The address of the exchange.
  /// @param enabled A boolean value to enable or disable the exchange.
  /// @return Returns true if successful.
  function enable(address exchange, bool enabled) external onlyOwner returns(bool) {
    exchanges[exchange] = enabled;
    if(enabled) {
      emit Enabled(exchange);
    } else {
      emit Disabled(exchange);
    }
    return true;
  }

  /// @notice Allows the owner to withdraw accidentally sent tokens.
  /// @param token The token address.
  /// @param amount The amount to withdraw.
  function withdraw(
    address token,
    uint amount
  ) external onlyOwner returns(bool) {
    if(token == NATIVE) {
      (bool success,) = address(msg.sender).call{value: amount}(new bytes(0));
      require(success, 'DePay: withdraw failed!');
    } else {
      IERC20(token).safeTransfer(msg.sender, amount);
    }
    return true;
  }
}