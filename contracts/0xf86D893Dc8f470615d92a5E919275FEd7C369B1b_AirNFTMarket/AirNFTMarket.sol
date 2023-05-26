/**
 *Submitted for verification at Etherscan.io on 2023-05-16
*/

// Sources flattened with hardhat v2.11.2 https://hardhat.org

// File @openzeppelin/contracts/security/[email protected]
// SPDX-License-Identifier: MIT


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


// File @openzeppelin/contracts/token/ERC20/[email protected]


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


// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File @openzeppelin/contracts/utils/introspection/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


// File @openzeppelin/contracts/token/ERC721/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}


// File @openzeppelin/contracts/token/ERC721/[email protected]


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


// File @openzeppelin/contracts/token/ERC1155/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}


// File @openzeppelin/contracts/token/ERC1155/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/access/[email protected]


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


// File contracts/AirNFTMarket.sol

pragma solidity ^0.8.9;








contract AirNFTMarket is IERC721Receiver, IERC1155Receiver, ReentrancyGuard, Ownable {


    address payable public contractOwner;

    uint8 public constant KIND_FIX_SALE = 1;
    uint8 public constant KIND_AUCTION = 2;

    uint8 public constant STATUS_OPEN = 1;
    uint8 public constant STATUS_DONE = 2;
    uint8 public constant STATUS_CANCELLED = 3;

    uint8 public constant DIRECT_BUY = 1;
    uint8 public constant OFFER_BUY = 2;

    uint8 public constant OFFER_CREATED = 1;
    uint8 public constant OFFER_ACCEPTED = 2;
    uint8 public constant OFFER_CANCELLED = 3; 


    uint8 public constant TOKEN_721 = 1; // 721 token
    uint8 public constant TOKEN_1155 = 2; // 1155 token


    struct TokenPair {
        address tokenAddress; // token contract address
        uint256 tokenId; // token id (if applicable)
        uint256 amount; // token amount (if applicable)
        uint8 kind; // token kind (721/1151)
    }

    struct Inventory {
        address seller;
        uint256 price; // display price
        uint256 netPrice; // actual price (auction: minus incentive)
        uint256 startAt; // (if auction kind)
        uint256 endAt; // (if auction kind)
        uint8 kind;
        uint8 status;
        TokenPair token;
    }

    struct Offer {
        uint256 amount; 
        uint256 startAt; 
        uint256 endAt;
        uint8 status;
    }

    

    // events
    event EvInventoryCreated(uint256 invId, TokenPair token, address indexed seller, uint256 price, uint256 kind);
    event EvInventoryAuctionCreated(uint256 invId, TokenPair token, address indexed seller, uint256 price, uint256 kind, uint256 startAt, uint256 endAt);
    event EvPurchased(address indexed previousOwner, address indexed newOwner, uint price, uint nftID);
    event EvInventoryCancelled(uint256 invId, address indexed seller, uint256 status, uint256 kind);
    event EvInventoryPriceUpdated(uint256 invId, address indexed seller, uint256 oldPrice, uint256 newPrice);
    event EvOfferCreated(uint256 invId, address indexed seller, address indexed offeror, uint256 amount, uint256 startAt, uint256 endAt);
    event EvOfferAccepted(uint256 invId, address indexed seller, address indexed offeror, uint256 amount);
    event EvOfferCancelled(uint256 invId, address indexed offeror, uint256 amount);
    event EvOfferUpdated(uint256 invId, address indexed offeror, uint256 amount);
    event EvBid(uint256 invId, address indexed bidder, uint256 bid);
    event EvAuctionCompleted(uint256 invId, address indexed seller, address indexed bidder, uint256 bid);
    event EvWithdrawBid(uint256 invId, address indexed bidder, uint256 bid);
    event EvMarketCommissionUpdated(uint256 minAuctionIncrement);
    event EvMinAuctionIncrementUpdated(uint256 marketCommission);

    mapping(uint256 => Inventory) public inventories;
    mapping(uint256 => mapping(address => Offer)) public offers;
    mapping(uint256 => mapping(address => uint256)) public bids;
    mapping(uint256 => address) public highestBidder;

    uint256 public invCount;

    uint256 public minAuctionIncrement = 10; // 10 percent
    uint256 public marketCommission = 40; // 2.5 percent

    constructor(address owner_) payable{
        contractOwner = payable(owner_);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override  returns (bytes4) {
        (operator);
        (from);
        (tokenId);
        (data);
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external pure override  returns (bytes4) {
        (operator);
        (from);
        (id);
        (value);
        (data);
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external pure override  returns (bytes4) {
        (operator);
        (from);
        (ids);
        (values);
        (data);
        return this.onERC1155BatchReceived.selector;
    }


    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return
            (interfaceId == type(IERC721Receiver).interfaceId) ||
            (interfaceId == type(IERC1155Receiver).interfaceId);
    }

    modifier isInvFixSaleOpen(uint256 invId) {
        require(hasInv(invId), 'inventory does not exist');
        require(isFixSaleOpen(invId), 'inventory is no longer opened');
        _;
    }

    modifier isInvAuctionValid(uint256 invId) {
        require(hasInv(invId), 'inventory does not exist');
        require(isAuctionOpen(invId), 'auction has ended');
        _;
    }

    modifier isInvAuctionEnded(uint256 invId) {
        require(hasInv(invId), 'inventory does not exist');
        require(isAuction(invId), 'auction does not exist');
        require(isAuctionExpired(invId), 'auction still going');
        _;
    }

    modifier onlySeller(uint256 invId) {
        Inventory storage inv = inventories[invId]; 
        require(msg.sender == inv.seller, "Only the seller can invoke this method");
        _;
    }

    function updateMinAuctionIncrement(uint256 minAuctionIncrement_)
        public
        onlyOwner
    {
        minAuctionIncrement = minAuctionIncrement_;
        emit EvMinAuctionIncrementUpdated(marketCommission);
    }

    function updateMarketCommission(uint256 marketCommission_)
        public
        onlyOwner
    {
        marketCommission = marketCommission_;
        emit EvMarketCommissionUpdated(marketCommission);
    }

    function createListing(
        TokenPair calldata token,
        uint256 kind,
        uint256 price,
        uint256 durationInSeconds
    ) public returns (uint256) {
        require(kind == KIND_FIX_SALE || kind == KIND_AUCTION, 'Listing type not supported');
        require(isApproved(token, msg.sender), 'token not approved');

        invCount++;
        uint256 invId = invCount;

        if(kind == KIND_FIX_SALE) {
            inventories[invId] = Inventory({
                seller: msg.sender,
                price: price,
                netPrice: price,
                status: STATUS_OPEN,
                kind: KIND_FIX_SALE,
                token: token,
                startAt: 0,
                endAt: 0
            });

            emit EvInventoryCreated(invId, token, msg.sender, price, kind);

        } else if(kind == KIND_AUCTION) {
            uint256 startAt = block.timestamp;
            uint256 endAt = startAt + durationInSeconds;

            inventories[invId] = Inventory({
                seller: msg.sender,
                price: price,
                netPrice: price,
                status: STATUS_OPEN,
                kind: KIND_AUCTION,
                token: token,
                startAt: startAt,
                endAt: endAt
            });

            _transferToken(
                inventories[invId].token.tokenAddress, 
                inventories[invId].token.tokenId, 
                inventories[invId].token.kind, 
                inventories[invId].token.amount, 
                msg.sender, 
                address(this)
            );

            emit EvInventoryAuctionCreated(invId, token, msg.sender, price, kind, startAt, endAt);

        } else {
            revert('impossible');
        }

        return invId;
    }

    function updateListingPrice(
        uint256 invId,
        uint256 price
    ) public isInvFixSaleOpen(invId) onlySeller(invId) {
        require(price > 0, "Error, the price must be greater than 0");
       Inventory storage inv = inventories[invId];
       uint256 oldPrice = inv.price;
       inv.price = price;
       inv.netPrice = price;

       emit EvInventoryPriceUpdated(invId, inv.seller, oldPrice, price);
    }

    function cancelFixSaleListing(
        uint256 invId
    ) public isInvFixSaleOpen(invId) onlySeller(invId) {
       Inventory storage inv = inventories[invId]; 
       inv.status = STATUS_CANCELLED;

       emit EvInventoryCancelled(invId, inv.seller, STATUS_CANCELLED, inv.kind);
    }

    function buy(
        uint256 invId
    ) public payable isInvFixSaleOpen(invId) nonReentrant {
        Inventory storage inv = inventories[invId];
        require(msg.value >= inv.price, "Error, the amount is lower");
        require(msg.sender != inv.seller, "Can not buy what you own");

        _transferToken(
            inventories[invId].token.tokenAddress, 
            inventories[invId].token.tokenId, 
            inventories[invId].token.kind, 
            inventories[invId].token.amount, 
            inv.seller, msg.sender
        );

        uint256 _commissionValue = inv.price / marketCommission;
        uint256 _sellerValue = inv.price - _commissionValue;

        _transfer(payable(inv.seller), _sellerValue);
        _transfer(contractOwner, _commissionValue);

        inv.status = STATUS_DONE;

        emit EvPurchased(inv.seller, msg.sender, inv.price, inv.token.tokenId);
    }

    function makeOffer(
        uint256 invId,
        uint256 durationInSeconds
    ) public payable isInvFixSaleOpen(invId) nonReentrant {        
        Inventory storage inv = inventories[invId];
        require(msg.value >= 0, "Error, the amount is lower");
        require(msg.sender != inv.seller, "Can not make offer on what you own");

        uint256 startAt = block.timestamp;
        uint256 endAt = startAt + durationInSeconds;

        offers[invId][msg.sender] = Offer({
            amount: msg.value,
            status: OFFER_CREATED,
            startAt: startAt,
            endAt: endAt
        });

        emit EvOfferCreated(invId, inv.seller, msg.sender, msg.value, startAt, endAt);
    }

    function updateOffer(uint256 invId) public payable nonReentrant {
        require(hasInv(invId), 'inventory does not exist');
        require(isFixSale(invId), 'inventory is not fix sale kind');
        
        Offer storage offer = offers[invId][msg.sender];
        require(offer.status == OFFER_CREATED, 'offer already processed');
        offer.amount += msg.value;

        emit EvOfferUpdated(invId, msg.sender, offer.amount);
    }

    function cancelOffer(
        uint256 invId
    ) public payable nonReentrant {
        require(hasInv(invId), 'inventory does not exist');
        require(isFixSale(invId), 'inventory is not fix sale kind');
        
        Offer storage offer = offers[invId][msg.sender];
        require(offer.status == OFFER_CREATED, 'offer already processed');
        _transfer(payable(msg.sender), offer.amount);

        offer.status = OFFER_CANCELLED;

        emit EvOfferCancelled(invId, msg.sender, offer.amount);
    }

    function acceptOffer(
        uint256 invId,
        address offeror
    ) public payable isInvFixSaleOpen(invId) onlySeller(invId) nonReentrant {
        Inventory storage inv = inventories[invId];
        
        Offer storage offer = offers[invId][offeror];
        require(offer.endAt > block.timestamp, "Offer already expired");
        require(offer.status == OFFER_CREATED, "Offer already processed");

        _transferToken(
            inventories[invId].token.tokenAddress, 
            inventories[invId].token.tokenId, 
            inventories[invId].token.kind, 
            inventories[invId].token.amount, 
            inv.seller, 
            offeror
        );

        uint256 _commissionValue = offer.amount / marketCommission;
        uint256 _sellerValue = offer.amount - _commissionValue;

        _transfer(payable(inv.seller), _sellerValue);
        _transfer(contractOwner, _commissionValue);

        offer.status = OFFER_ACCEPTED;
        inv.status = STATUS_DONE;

        emit EvOfferAccepted(invId, inv.seller, offeror, offer.amount);
    }

    function cancelAuctionListing(
        uint256 invId
    ) public isInvAuctionValid(invId) onlySeller(invId) {
        require(getHighestBidder(invId) == address(0), 'cannot cancel an auction with bids');

       Inventory storage inv = inventories[invId]; 
       inv.status = STATUS_CANCELLED;

       emit EvInventoryCancelled(invId, inv.seller, STATUS_CANCELLED, inv.kind);
    }

    function bid(uint256 invId) public payable isInvAuctionValid(invId) nonReentrant {
        Inventory storage inv = inventories[invId];
        require(msg.sender != inv.seller, "cannot bid on what you own");

        uint256 newBid = bids[invId][msg.sender] + msg.value;
        uint256 incentive = inv.price / minAuctionIncrement;
        require(newBid >= inv.price + incentive, 'bid price too low');

        bids[invId][msg.sender] += msg.value;

        highestBidder[invId] = msg.sender;

        inv.price = inv.price + incentive;

        emit EvBid(invId, msg.sender, newBid);
    }


    function completeAuction(uint256 invId) public payable isInvAuctionEnded(invId) nonReentrant {
        require(isStatusOpen(invId), 'auction not open');

        Inventory storage inv = inventories[invId];
        address winner = highestBidder[invId]; 
        require(
            msg.sender == inv.seller || msg.sender == winner, 
            'only seller or winner can complete auction'
        );

        if(winner != address(0)) {
           _transferToken(
                inventories[invId].token.tokenAddress, 
                inventories[invId].token.tokenId, 
                inventories[invId].token.kind, 
                inventories[invId].token.amount, 
                address(this), 
                winner
            );

            uint256 amount = bids[invId][winner]; 
            uint256 _commissionValue = amount / marketCommission;
            uint256 _sellerValue = amount - _commissionValue;

            _transfer(payable(inv.seller), _sellerValue);
            _transfer(contractOwner, _commissionValue);

        } else {
            _transferToken(
                inventories[invId].token.tokenAddress, 
                inventories[invId].token.tokenId, 
                inventories[invId].token.kind, 
                inventories[invId].token.amount, 
                address(this), 
                inv.seller
            );
        }

        inv.status = STATUS_DONE;

        emit EvAuctionCompleted(invId, inv.seller, winner, bids[invId][winner]);

    }

    function withdrawBid(uint256 invId) public payable isInvAuctionEnded(invId) nonReentrant {
        require(!isStatusOpen(invId), 'auction must be ended or cancelled');
        require(highestBidder[invId] != msg.sender, 'highest bidder cannot withdraw bid');

        uint256 balance = bids[invId][msg.sender];
        bids[invId][msg.sender] = 0;
        _transfer(payable(msg.sender), balance);

        emit EvWithdrawBid(invId, msg.sender, balance);

    }

    function isAuctionOpen(uint256 id) public view returns (bool) {
        return
            isAuction(id) &&
            inventories[id].status == STATUS_OPEN &&
            inventories[id].endAt > block.timestamp;
    }

    function isAuction(uint256 id) public view returns (bool) {
        return inventories[id].kind == KIND_AUCTION;
    }

    function isAuctionExpired(uint256 id) public view returns (bool) {
        return isAuction(id) && inventories[id].endAt <= block.timestamp;
    }

    function isFixSaleOpen(uint256 id) public view returns (bool) {
        return
            isFixSale(id) &&
            inventories[id].status == STATUS_OPEN;
    }

    function isFixSale(uint256 id) public view returns (bool) {
        return inventories[id].kind == KIND_FIX_SALE;
    }


    function hasInv(uint256 id) public view returns (bool) {
        return inventories[id].kind != 0;
    }

    function isStatusOpen(uint256 id) public view returns (bool) {
        return inventories[id].status == STATUS_OPEN;
    }

    function getHighestBidder(uint256 id) public view returns (address) {
        return highestBidder[id];
    }


    function isApproved(TokenPair calldata token, address tokenOwner) public view returns (bool) {
        if(token.kind == TOKEN_721){
            IERC721 t = IERC721(token.tokenAddress);
            if (
                t.ownerOf(token.tokenId) == tokenOwner &&
                (t.getApproved(token.tokenId) == address(this) ||
                t.isApprovedForAll(tokenOwner, address(this)))
                ) {
                   // pass
            } else {
                return false;
            }
        } else if (token.kind == TOKEN_1155) {
            IERC1155 t = IERC1155(token.tokenAddress);
            if (
                t.balanceOf(tokenOwner, token.tokenId) >= token.amount &&
                t.isApprovedForAll(tokenOwner, address(this))
            ) {
                // pass
            } else {
                return false;
            }
        } else {
            revert('unsupported token');
        }

        return true;
    }

    function _transferToken(address tokenAddress, uint256 tokenId, uint256 kind, uint256 amount, address from, address to) internal {
        if(kind == TOKEN_721){
            _executeERC721TransferFrom(tokenAddress,from, to, tokenId);
        } else if (kind == TOKEN_1155) {
            _executeERC1155SafeTransferFrom(tokenAddress, from, to, tokenId, amount);
        } else {
            revert('unsupported token');
        }

    }

    function _transfer(
        address payable to,
        uint256 amount
    ) internal {
        if (amount == 0) {
            return;
        }
        require(to != address(0), 'cannot transfer to address(0)');

        (bool transferSent, ) = to.call{value: amount}("");
        require(transferSent, "Failed to send Ether");

    }

    function _executeERC1155SafeTransferFrom(
        address tokenAddress,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal {
        if (tokenAddress.code.length == 0) {
            revert ("Not a contract");
        }

        (bool status, ) = tokenAddress.call(abi.encodeCall(IERC1155.safeTransferFrom, (from, to, tokenId, amount, "")));

        if (!status) {
            revert ("ERC1155SafeTransferFromFail");
        }
    }

    function _executeERC721TransferFrom(address tokenAddress, address from, address to, uint256 tokenId) internal {
        if (tokenAddress.code.length == 0) {
            revert ("Not a contract");
        }

        (bool status, ) = tokenAddress.call(abi.encodeCall(IERC721.transferFrom, (from, to, tokenId)));

        if (!status) {
            revert ("ERC721TransferFromFail");
        }
    }


}