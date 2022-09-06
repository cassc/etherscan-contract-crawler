/**
 *Submitted for verification at Etherscan.io on 2022-07-27
*/

/**
 *Submitted for verification at BscScan.com on 2022-03-23
*/

// Sources flattened with hardhat v2.6.7 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/utils/[email protected]



pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]



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


// File @openzeppelin/contracts/utils/[email protected]



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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File contracts/interfaces/IOracleAggregator.sol


pragma solidity ^0.8.0;

interface IOracleAggregator {
    function setPriceFeed(
        address token,
        address baseCurrencyAddress,
        address feed,
        uint8 decimals,
        bytes memory callData
    ) external;

    function removePriceFeed(address token) external;

    function getPricePerNative(address token) external view returns (uint256 adjustedPrice);

    function getPrice(address token) external view returns (uint256 tokenPrice);
}


// File contracts/lib/ConveyorTypes.sol


pragma solidity ^0.8.0;

library ConveyorTypes {
    struct MetaTransaction {
        address from;
        address to;
        address feeToken;
        bool useOraclePriceFeed;
        uint256 maxTokenAmount;
        uint256 deadline;
        uint256 nonce;
        bytes data;
        uint256[] extendCategories;
    }
}


// File contracts/interfaces/IEIP1271Wallet.sol


pragma solidity ^0.8.0;

interface IEIP1271Wallet {
    function isValidSignature(bytes32 _hash, bytes memory _signature) external view returns (bytes4 magicValue);
}


// File @openzeppelin/contracts/utils/cryptography/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
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
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

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
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}


// File contracts/lib/SignatureValidator.sol


pragma solidity ^0.8.0;


/// @notice Provides functionality to verify a signature for both Externally Owned Accounts and smart contract accounts (via EIP-1271).
abstract contract SignatureValidator {
    // bytes4(keccak256("isValidSignature(bytes32,bytes)")
    bytes4 internal constant EIP1271_VALID_SIG_RESP = 0x1626ba7e;

    /// @notice The type of signer for the EIP-712 signature
    enum SignatureSignerType {
        EOA,
        CONTRACT // Only EIP-1271 verification is supported.
    }

    /// @notice Reverts if the signature is invalid
    /// @param _from address of signer we're trying to verify
    /// @param _hash hash of the message
    /// @param _sig signed message provided by user
    function verifySignature(
        address _from,
        bytes32 _hash,
        SignatureSignerType _signerType,
        bytes memory _sig
    ) internal view {
        require(_from != address(0), "Invalid signer");
        if (_signerType == SignatureSignerType.CONTRACT) {
            _verifySmartContractSignature(_from, _hash, _sig);
        } else {
            _verifyExternalAccountSignature(_from, _hash, _sig);
        }
    }

    function _verifyExternalAccountSignature(
        address _from,
        bytes32 _hash,
        bytes memory _sig
    ) private pure {
        address recoveredSigner = ECDSA.recover(_hash, _sig);
        require(_from == recoveredSigner, "ForwarderError: Invalid EOA signature");
    }

    function _verifySmartContractSignature(
        address _from,
        bytes32 _hash,
        bytes memory _sig
    ) private view {
        bytes4 signResp = IEIP1271Wallet(_from).isValidSignature(_hash, _sig);
        require(signResp == EIP1271_VALID_SIG_RESP, "ForwarderError: Invalid EIP1271 signature");
    }
}


// File contracts/ConveyorForwarder.sol


pragma solidity ^0.8.0;





contract ConveyorForwarder is Ownable, SignatureValidator {
    using SafeERC20 for IERC20;

    uint256 public constantFee = 21000;
    uint256 public transferFee = 65000;
    address public aggregator;
    mapping(address => bool) public relayers;
    mapping(address => uint256) public nonces;

    struct ConveyorTransaction {
        ConveyorTypes.MetaTransaction metatx;
        string domainName;
        bool relayerChargeEnabled;
        uint256 tokenPricePerNativeToken;
        SignatureSignerType signerType;
        bytes sig;
        bytes extendParamData;
    }

    // keccak256(bytes("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"))
    bytes32 public constant DOMAIN_TYPEHASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;
    // keccak256(bytes("Forwarder(address from,address to,address feeToken,bool useOraclePriceFeed,uint256 maxTokenAmount,uint256 deadline,uint256 nonce,bytes data,uint256[] extendCategories)"))
    bytes32 public constant FORWARDER_TYPEHASH = 0x4ae61fc164e25799870cbaae10b17b28f9ce2fc9c3042f705d445aea56a8ebf1;

    event MetaStatus(address sender, bool success, string error);
    event BatchedMetaStatus(bool[] successArr);

    modifier onlyRelayer() {
        require(relayers[msg.sender], "ConveyorForwarderError: Not relayer!");
        _;
    }

    // ------------------------------------  Admin Functions  ------------------------------------------ //
    function setConstantFee(uint256 _newConstantFee) external onlyOwner {
        constantFee = _newConstantFee;
    }

    function setTransferFee(uint256 _newTransferFee) external onlyOwner {
        transferFee = _newTransferFee;
    }

    function setRelayer(address _relayer, bool _trusted) external onlyOwner {
        relayers[_relayer] = _trusted;
    }

    function setAggregator(address _aggregator) external onlyOwner {
        aggregator = _aggregator;
    }

    function withdrawFeeTokens(address token, address feeReceiver) external onlyOwner {
        IERC20(token).safeTransfer(feeReceiver, IERC20(token).balanceOf(address(this)));
    }

    function withdraw() external onlyOwner {
        // avoid using send() or transfer(). See https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "ConveyorForwarderError: ETH Withdraw failed!");
    }

    // ------------------------------------  Primary MetaTxn Execution  ------------------------------------------ //
    function executeMetaTxV2(
        ConveyorTypes.MetaTransaction memory metatx,
        string memory domainName,
        bool relayerChargeEnabled,
        uint256 tokenPricePerNativeToken,
        SignatureSignerType signerType,
        bytes memory sig,
        bytes memory extendParamData
    ) external payable onlyRelayer returns (bool success, bytes memory data) {
        if (relayerChargeEnabled) {
            uint256 startingGas = gasleft();
            // check if sender opted for using oracle price feed
            if (metatx.useOraclePriceFeed && aggregator != address(0)) {
                uint256 oraclePrice = IOracleAggregator(aggregator).getPricePerNative(metatx.feeToken);
                if (oraclePrice > 0) {
                    tokenPricePerNativeToken = oraclePrice;
                }
            }
            _preExecution(startingGas, metatx, domainName, tokenPricePerNativeToken, signerType, sig);
            (success, data) = _onExecution(metatx, extendParamData);
            uint256 price = (tokenPricePerNativeToken * tx.gasprice); // this price has been amplified by a factor of 10**18
            uint256 executionGas = startingGas - gasleft();
            _postExecution(metatx, executionGas, price);
        } else {
            _verifyEIP712Signature(metatx, domainName, signerType, sig);
            (success, data) = _onExecution(metatx, extendParamData);
            require(success, _getRevertMsg(data));
        }
    }

    function executeBatchedMetaTx(ConveyorTransaction[] memory conveyorTransactions)
        external
        payable
        onlyRelayer
        returns (bool[] memory, bytes[] memory)
    {
        bool[] memory successArr = new bool[](conveyorTransactions.length);
        bytes[] memory dataArr = new bytes[](conveyorTransactions.length);
        bytes4 selector = this.executeMetaTxV2.selector;
        for (uint256 i = 0; i < conveyorTransactions.length; i++) {
            bytes memory encodedData = abi.encodeWithSelector(
                selector,
                conveyorTransactions[i].metatx,
                conveyorTransactions[i].domainName,
                conveyorTransactions[i].relayerChargeEnabled,
                conveyorTransactions[i].tokenPricePerNativeToken,
                conveyorTransactions[i].signerType,
                conveyorTransactions[i].sig,
                conveyorTransactions[i].extendParamData
            );
            (bool success, bytes memory data) = address(this).delegatecall(encodedData);
            successArr[i] = success;
            dataArr[i] = data;
        }
        emit BatchedMetaStatus(successArr);
        return (successArr, dataArr);
    }

    // ------------------------------------  Common MetaTxn Helper Functions ------------------------------------------ //
    function _convertBytesToBytes4(bytes memory inBytes) private pure returns (bytes4 outBytes4) {
        if (inBytes.length == 0) {
            return 0x0;
        }

        assembly {
            outBytes4 := mload(add(inBytes, 32))
        }
    }

    function _verifyResult(
        address from,
        bool success,
        bytes memory data
    ) private {
        string memory errorLog;
        if (!success) {
            errorLog = _getRevertMsg(data);
        }
        emit MetaStatus(from, success, errorLog);
    }

    function _preExecution(
        uint256 startingGas,
        ConveyorTypes.MetaTransaction memory metatx,
        string memory domainName,
        uint256 tokenPricePerNativeToken,
        SignatureSignerType signerType,
        bytes memory sig
    ) private {
        // performing necessary checks. any point of reverts will not be refunded.
        // collect maxTokenAmount of fee upfront
        uint256 total = metatx.maxTokenAmount;
        require(
            IERC20(metatx.feeToken).balanceOf(metatx.from) >= total,
            "ConveyorForwarderError: Insufficient balance"
        );
        uint256 fee = (startingGas * tokenPricePerNativeToken * tx.gasprice) / (10**18);
        require(total >= fee, "ConveyorForwarderError: Insufficient maxTokenAmount");
        _verifyEIP712Signature(metatx, domainName, signerType, sig);
        IERC20(metatx.feeToken).safeTransferFrom(metatx.from, address(this), metatx.maxTokenAmount);
    }

    function _onExecution(ConveyorTypes.MetaTransaction memory metatx, bytes memory extendParamData)
        private
        returns (bool success, bytes memory data)
    {
        bytes4 destinationFunctionSig = _convertBytesToBytes4(metatx.data);
        bool functionIsValid = destinationFunctionSig != msg.sig;
        if (functionIsValid) {
            uint256 length = extendParamData.length;
            (success, data) = metatx.to.call(abi.encodePacked(metatx.data, extendParamData, length, metatx.from));
            _verifyResult(metatx.from, success, data);
        } else {
            emit MetaStatus(metatx.from, false, "ConveyorForwarderError: Invalid function signature");
        }
    }

    function _postExecution(
        ConveyorTypes.MetaTransaction memory metatx,
        uint256 executionGas,
        uint256 tokenPrice
    ) private {
        uint256 gasUsed = executionGas + constantFee + (transferFee * 2);
        uint256 fee = (tokenPrice * gasUsed) / (10**18); // adjust the fee to reflect the transaction fee in wei
        bool refund = metatx.maxTokenAmount > fee;
        if (refund) {
            IERC20(metatx.feeToken).safeTransfer(metatx.from, metatx.maxTokenAmount - fee);
        }
    }

    // Ref: https://ethereum.stackexchange.com/questions/83528/how-can-i-get-the-revert-reason-of-a-call-in-solidity-so-that-i-can-use-it-in-th
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    // ------------------------------------  Signature Verification ------------------------------------------ //
    function _registerDomain(string memory _name) private view returns (bytes32 DOMAIN_SEPARATOR) {
        uint256 chainId;

        assembly {
            chainId := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(_name)), keccak256(bytes("1")), chainId, address(this))
        );
    }

    function _generateHashedMessage(ConveyorTypes.MetaTransaction memory metatx) private returns (bytes32) {
        return (
            keccak256(
                abi.encode(
                    FORWARDER_TYPEHASH,
                    metatx.from,
                    metatx.to,
                    metatx.feeToken,
                    metatx.useOraclePriceFeed,
                    metatx.maxTokenAmount,
                    metatx.deadline,
                    nonces[metatx.from]++,
                    keccak256(metatx.data),
                    keccak256(abi.encodePacked(metatx.extendCategories))
                )
            )
        );
    }

    function _generateEIP712Message(string memory _domainName, bytes32 _hashedMessage) private view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", _registerDomain(_domainName), _hashedMessage));
    }

    /// @notice Reverts if signature does not match metaTxn sender
    function _verifyEIP712Signature(
        ConveyorTypes.MetaTransaction memory metatx,
        string memory domainName,
        SignatureSignerType _signerType,
        bytes memory sig
    ) private {
        bytes32 hashedMessage = _generateHashedMessage(metatx);
        bytes32 hashDigest = _generateEIP712Message(domainName, hashedMessage);
        verifySignature(metatx.from, hashDigest, _signerType, sig);
    }
}