/**
 *Submitted for verification at BscScan.com on 2023-01-04
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/[email protected]/utils/Address.sol


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

// File: @openzeppelin/[email protected]/token/ERC20/extensions/draft-IERC20Permit.sol


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

// File: @openzeppelin/[email protected]/token/ERC20/IERC20.sol


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

// File: @openzeppelin/[email protected]/token/ERC20/utils/SafeERC20.sol


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

// File: @openzeppelin/[email protected]/utils/Context.sol


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

// File: @openzeppelin/[email protected]/access/Ownable.sol


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

// File: @openzeppelin/[email protected]/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: LAUNCHPAD_UNEMETA.sol


pragma solidity ^0.8.7;





interface IERC721YULIBOX {
    function safeMint(
        address to,
        uint256 boxType,
        uint256 platform
    ) external;
}

contract YOGBoxLaunchPad is Pausable, Ownable {
    /* ========== LIBs ========== */
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */
    address public receiver = 0x33F4b9f19863E638A0308Ef590116f5eD19ceAd2;
    address public platformReceiver;
    address public BUSDAddress = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public NFTBoxAddress = 0x369d7b51BC81D69A3e8C313f036594504D1edda0;

    uint256 public maxBuyAmount = 100000;

    uint256 private startTime;
    uint256 private endTime;

    mapping(uint256 => uint256) private boxStockMap;
    mapping(uint256 => uint256) private boxTotalMap;
    mapping(uint256 => uint256) private boxPriceMap;
    mapping(address => bool) private whitelistAddressMap;
    mapping(address => uint256) private buyCountMap;

    /* ========== EVENTS ========== */

    event BuyLog(
        address indexed caller,
        uint256 boxType,
        uint256 buyAmount,
        uint256 tokenAmount
    );

    constructor() {
        platformReceiver = address(this);

        startTime = 1671940800;
        endTime = startTime + 86400 * 90;

        boxPriceMap[3] = 200 ether;
        boxPriceMap[4] = 1000 ether;

        boxTotalMap[3] = 450;
        boxTotalMap[4] = 50;

        boxStockMap[3] = 450;
        boxStockMap[4] = 50;

        whitelistAddressMap[0x80E4a18Db248C7DE222fa9F6e48372590456694D] = true;
        whitelistAddressMap[0x9DF823D90a10F50E1692160B6bC7C86a055A2b16] = true;
        whitelistAddressMap[0x73BCD8e9bBd2c18e8473e46c56CC5A9b798F36F2] = true;
        whitelistAddressMap[0x7fb34A2a67BdA34b4A6236ed84BCdFfEAb9B10d3] = true;
        whitelistAddressMap[0x48242179A889a157E60618E255676F61E095b798] = true;
        whitelistAddressMap[0x0Bf6192712c2625417B16Cf11B5f99EC1F539c19] = true;
        whitelistAddressMap[0xD3337B2b12f7f626d7D1855a3141e41c85a29A88] = true;
        whitelistAddressMap[0x72c1109093B48a10da7A88601bf5A817044C4c70] = true;
        whitelistAddressMap[0xba8a214E66BdE3585b868aBB1d623d9228383516] = true;
        whitelistAddressMap[0xd3E1e4B00E80BB21bE86F6342CeCDDEAE8bc3aFd] = true;
        whitelistAddressMap[0x180F81ceAd28209E53Cdb6AA7F8F2F29C3f32B04] = true;
        whitelistAddressMap[0x5488AcFB5A4Db5e2770b24235a037AF8a003E625] = true;
        whitelistAddressMap[0x32C9101c790c118a3b16811e3aF59C09BE63c500] = true;
        whitelistAddressMap[0xB9ee4782a05FEBd9aDE94b852DBAdCb45a230aC5] = true;
        whitelistAddressMap[0xc12f50E1B6885113a4D28E5EDA9b88660C5c8295] = true;
        whitelistAddressMap[0xFCbe2d2E835F018640eef90FF3fF106Cd23487F5] = true;
        whitelistAddressMap[0x04bf3541d6596A154199526dD89C5FA291BcC800] = true;
        whitelistAddressMap[0x1fd383F1da4F5c9F50706819aA65A8301E215324] = true;
        whitelistAddressMap[0x7aCde7327063BCA11b2ad82E93cb0cACEBBA4052] = true;
        whitelistAddressMap[0x400d149913F0f1A73A6ecDaA2e03451200CBB5c5] = true;
        whitelistAddressMap[0x9DF6cCbee0A4C94c502B5d1Eba6220a07F712293] = true;
        whitelistAddressMap[0x3cC49318CC5304c8CDB158e1D414B452aa7B72Ad] = true;
        whitelistAddressMap[0x7df14d5C59FDCDBAD208A6d618d763e4e192a4c1] = true;
        whitelistAddressMap[0x75727DEDFEE6f6c2712cD283eABD20699E3196bB] = true;
        whitelistAddressMap[0x5997423907688E9627018687249F14489D5b3c57] = true;
        whitelistAddressMap[0xCb935FFe75b220F240FBEd413a8683A898BD20D4] = true;
        whitelistAddressMap[0x2225e76d3c36dE0c08f32D44334a2095e082aB49] = true;
        whitelistAddressMap[0xf79687341E7B0C8deF1bB0f7C95B7252c8c3C645] = true;
        whitelistAddressMap[0x3f9AA5eCa041999238a46A099c55b63151CC5e4d] = true;
        whitelistAddressMap[0x73A4E15BEd5b27324C1190C4206cEd932928Cd4e] = true;
        whitelistAddressMap[0x8B8519853e8c3D7792124ac556690877859C22EA] = true;
        whitelistAddressMap[0x0fbf911146b7a355A2f16CeE30A373da86B8375d] = true;
        whitelistAddressMap[0xFB33C0d67Da5Aa40a5c531012955d39e2Be74190] = true;
        whitelistAddressMap[0xeEd59b85a2C580C3ebC1A5101857FaefFFa212C6] = true;
        whitelistAddressMap[0x555915510Dc8B7E6a36f45eb665A3224Be703C0c] = true;
        whitelistAddressMap[0xC2c6200d521CCb3868bCe1B7dE07A39958303b63] = true;
        whitelistAddressMap[0xD60A69DFC4d85Fdc6E88f16ccbC6F622CAF1278d] = true;
        whitelistAddressMap[0x56d08026d8E3e908Af181a6b76300e40707bb985] = true;
        whitelistAddressMap[0x7B472A7CE8FeADFF1Cfd1C08dBd194eFE2A29D07] = true;
        whitelistAddressMap[0xac74a999fd71Bed40F59001D16b31eBb4DE3D85D] = true;
        whitelistAddressMap[0x1B34A8A6445D0A1b5E279469c11cceb9eb131DFC] = true;
        whitelistAddressMap[0xa63e242e2e09AeE4C1408372cBc10B4325e49520] = true;
        whitelistAddressMap[0xEe052C3EF235591bFa2519ff3Ea1cF794e169Df4] = true;
        whitelistAddressMap[0x1546fb1D15D1cC68d1Dd3972928F69Aa9e66B776] = true;
        whitelistAddressMap[0x1c64a062E4B9257BD368C93Ff49402c235d9c6E0] = true;
        whitelistAddressMap[0xfE30235E7BaBf732E5D40CBD65Bc719ab6213F47] = true;
        whitelistAddressMap[0xc8E4b21260968CF6a9bE10C3eDe4cFe7D9D36BC1] = true;
        whitelistAddressMap[0x6b7Aa5D572fbCB67252165Def631305E00C49f7b] = true;
        whitelistAddressMap[0xe431119b2248c43f48B09E93E931B90D7Fb2EEd0] = true;
        whitelistAddressMap[0xC8465849Ee7De2aA5ef1fab2d96C44eCEA82C72f] = true;
        whitelistAddressMap[0x47B131b85401aE9e5f37F81312a80f7083c2BA02] = true;
        whitelistAddressMap[0xA1304bec6E5249B45E26B4eD04e5eA7EC43df829] = true;
        whitelistAddressMap[0x078Ca0b8B10891887c4c8F1Bc064F766565a9787] = true;
        whitelistAddressMap[0x6b070543cc4278892C07e967D5365c900EF99b18] = true;
        whitelistAddressMap[0x83F8D743947101D39C0BF2E27553609BBD71Dc23] = true;
        whitelistAddressMap[0x77738aa1F3133DF3c5Ade2ecb5ECde43cc5ecB47] = true;
        whitelistAddressMap[0x848d8eF5010cb5Eb77F5969B7BEb442dA08b2517] = true;
        whitelistAddressMap[0x993071B23D4c7055168280D5c20800Af862C8bb0] = true;
        whitelistAddressMap[0xc087fC2E6a5b3b53f2326283D0D3A96a530693Ab] = true;
        whitelistAddressMap[0xf8b49D5cDDa4c3A78d0DfEeCfead1cf553151551] = true;
        whitelistAddressMap[0x92c1C153F17f9F3E2774d6f146097312824a8f24] = true;
        whitelistAddressMap[0xb800C11C9A2DcbAae33D5c13c3A686beCF423024] = true;
        whitelistAddressMap[0x1B36519c6734A2E6578c83A1D882Cc29F098Af5F] = true;
        whitelistAddressMap[0x246b485Dcb857A7033C7B0D696486a98E05ead46] = true;
        whitelistAddressMap[0xd03e3397DEFC9f155D4d6605A33ea19d78B210E7] = true;
        whitelistAddressMap[0xE1f4eED5f79C0ab6dA095C52af2f9811A0b1c02e] = true;
        whitelistAddressMap[0x56eA1051700B5aE5CF01a2acd13553b48ec67E8e] = true;
        whitelistAddressMap[0xE0279B1532c9f5De97cc2Ce5f47F8B8A5761265F] = true;
        whitelistAddressMap[0xf71F50AD3d8E6c48cC15e7Ec29A62A0a9E17bE65] = true;
        whitelistAddressMap[0x3aa50e86b3aC589bf3a9b9D3f90Bb6801611e8ED] = true;
        whitelistAddressMap[0x99b414147bb790B9D26Bd7da18fF1e35d9B86580] = true;
        whitelistAddressMap[0xf7Fc1e05c6cF5f0C67af65ef4fF55d2DF49c8727] = true;
        whitelistAddressMap[0xE8A9Dd11CF736e8540d33C060316597EA81073eB] = true;
        whitelistAddressMap[0xc243B5D058CC4cDF51E6fA8cDED991AC3f17E2bA] = true;
        whitelistAddressMap[0xE734436b7F60DD829c46A34C6111d67a33a1BEea] = true;
        whitelistAddressMap[0x8545Cb7151f1d26D716E923B5Fc517fD12886c7F] = true;
        whitelistAddressMap[0x544dFDE47dDfF4d39622781559aFc616338c8019] = true;
        whitelistAddressMap[0x717e7fc777A6236d9dEa3f046D71eD80b5E963AB] = true;
        whitelistAddressMap[0x4F84D004Ef6F2056E0c387b3cDA57c9c2779804f] = true;
        whitelistAddressMap[0x93b5C773D059ab62d68f8CdEE0C9F072488d6827] = true;
        whitelistAddressMap[0x852A6af6c0fd8fFBc90f8a3408861FcB2732636f] = true;
        whitelistAddressMap[0xC68116b6De5daf2255D1aEa17C22b37bC2CC1157] = true;
        whitelistAddressMap[0x4054ca73a7d8d254F58c298319559c82a297aC36] = true;
        whitelistAddressMap[0xC967eC733dF62FF344ca7D416e6308d0350823d2] = true;
        whitelistAddressMap[0x97a6A81f3a484955f8b36D42Cf1626f4f30AB5fe] = true;
        whitelistAddressMap[0xB6da1b456CdE06668488e54f73427CA83d3200A7] = true;
        whitelistAddressMap[0x011df17eD7256C33d65d7dC6622B0F3D9FeC820E] = true;
        whitelistAddressMap[0x311c17FeAb4912daD07f97549292b367509A661D] = true;
        whitelistAddressMap[0xfBE37D048883F3D91FcF9DFA90B7586bF8a45322] = true;
        whitelistAddressMap[0xe1200606aE0b35Ce5D5e31Dcb4F1a2EcAaaf64A6] = true;
        whitelistAddressMap[0x88fA1305AbdF0E95A95CDf26661046382a2ECF7f] = true;
        whitelistAddressMap[0xDadC7A0F411BbdB6dA1f467eAd25b618121860f3] = true;
        whitelistAddressMap[0xb9684a9698F1079491De7dB44646C6660EE4D8f3] = true;
        whitelistAddressMap[0x480aF33e586Ff2c8eBcF6D29a378B91c16684EfC] = true;
        whitelistAddressMap[0x3E5948C4F7A83aEE0204dE7c0E1Bbd331C760Bb0] = true;
        whitelistAddressMap[0x082eAaC7720CbEfc27B319c787d29AF4fc43a739] = true;
        whitelistAddressMap[0x7174ecdD6eb1Af4540fa659af9b416f858F2bBa1] = true;
        whitelistAddressMap[0xCC8223D078971ec16E2ef85E180d68BBCB361F37] = true;
        whitelistAddressMap[0xe5586c679705979c38589Dd154Ed9d8481CB2e75] = true;
        whitelistAddressMap[0x0688195E8c31bDDe9B4737087176dee185Ed7Bd9] = true;
        whitelistAddressMap[0xC79F3D358324E20C57504DeD1bC875DDa2bB9cC3] = true;
        whitelistAddressMap[0x0D08c7D3d00F5937a772893B90f75981aEbea253] = true;
        whitelistAddressMap[0x426F4D2d81f1bd1cA1d288e3BDaC0020662daA7F] = true;
        whitelistAddressMap[0x851392192394fAa1Ad1fA0f0087288e7434128A0] = true;
        whitelistAddressMap[0xF7e7BDF26071d05eD5447153E483eD74Cdb12202] = true;
        whitelistAddressMap[0x36E8Ee6de00bd6032aA1f4ee86Ce8Ea5581159AB] = true;
        whitelistAddressMap[0xd4083F91d0ac928961c009547F76340BBa56b40f] = true;
        whitelistAddressMap[0xAB22B7ec7092b90903225ABBcD4e4a912984E63d] = true;
        whitelistAddressMap[0x2C3eD0211d5EA74Ce3dA545b7AF217e4284eA030] = true;
        whitelistAddressMap[0x5c84c99775D4FD13DC58e813dd26879496Fd3492] = true;
        whitelistAddressMap[0x2De500dd57c9304cfc3285582Edebc3FD2C964a6] = true;
        whitelistAddressMap[0xC9FF128c5E85ed0623f4bbC8b9aE003D4334Ab1e] = true;
        whitelistAddressMap[0x9960186F540d736F45D11c7a3467d9Dff5083dF1] = true;
        whitelistAddressMap[0x50839E3f64D90b1131c2A6d5e47D8B88741971bF] = true;
        whitelistAddressMap[0x9d09Ec3CBb97Bc6571168A155cAd17043Ff1093D] = true;
        whitelistAddressMap[0x6e2805675A7660C9bbF2DC0DB741F04AB1e9e7Cd] = true;
        whitelistAddressMap[0x99C4388211CD070881e5eBE6C7927C20440296Fd] = true;
        whitelistAddressMap[0x590f05F834DC87D8194739aB2DA022b2172345FB] = true;
        whitelistAddressMap[0xcE09347DC1ABF2A7015d44E8b29cdcB9FA47D1aa] = true;
        whitelistAddressMap[0x9fC0F27a8865aF5472a7ef8166cCe1a90eF6F5e7] = true;
        whitelistAddressMap[0x622372558A8d49A227938f7cd2B5C581a042964E] = true;
        whitelistAddressMap[0x91937EBD9b46b786fC38d392C95dd82a94AE519B] = true;
        whitelistAddressMap[0xddf38b15405421Cbd345395fB865C48a4b5B95bc] = true;
        whitelistAddressMap[0x55C79b7FE486ED31FfED2E0be53920A0D3398657] = true;
        whitelistAddressMap[0x30089c77d2F3c384F64C344ffD1971da510Ec755] = true;
        whitelistAddressMap[0x01550bc512A073460b9a76c130F8111Aa1a90812] = true;
        whitelistAddressMap[0x024af5a595bE4725Ce1c2C4E6D2B697eC64117D0] = true;
        whitelistAddressMap[0x03Cdf46e8dDc1bC4511B56e10b408c6125b413d5] = true;
        whitelistAddressMap[0x03f6FB263E31307EF191Cc6070Aa9D7a5f04d9F7] = true;
        whitelistAddressMap[0x09387537Bd181456C9D51b70d05371eF56B94153] = true;
        whitelistAddressMap[0x0a57b72eCB12d8E7def594eDd1F0630A0cADF9eE] = true;
        whitelistAddressMap[0x0aC0709dF751c4231B7a965FC146E48732A50FD7] = true;
        whitelistAddressMap[0x0Bf6192712c2625417B16Cf11B5f99EC1F539c19] = true;
        whitelistAddressMap[0x0D243C836a7Cb479Da9e9d7d5c8b5deC57ffe0Ac] = true;
        whitelistAddressMap[0x0Ebe3F08c43C2fdf1C236FDF0F2E6dBb8018aE9A] = true;
        whitelistAddressMap[0x0fC04356279D5AeFbd1754c2c31E576251d1375e] = true;
        whitelistAddressMap[0x11635Bd29933F87E0F637b5D2F81F3250222F144] = true;
        whitelistAddressMap[0x12955b3eb46c6E249fd9694c099C11EEB890873d] = true;
        whitelistAddressMap[0x135CBA5975f5a4c1EB9995B9faC946e0A13CfFfE] = true;
        whitelistAddressMap[0x13fD8Aa51C1a11834213A4D1257575F3e546fFd5] = true;
        whitelistAddressMap[0x1421Bf929Fe1fc8B14B6f81c78313C8905680df8] = true;
        whitelistAddressMap[0x19c1298ff39D5427E9f5CEA66341c1B8ff8CDd55] = true;
        whitelistAddressMap[0x1C9a6fa651a6d0e1452517867c11a8A3202F0b72] = true;
        whitelistAddressMap[0x1cb49ecB9EbB0555dAB1AC4f569526F94F12E9e5] = true;
        whitelistAddressMap[0x1E3672666f9F0815fC66834CF171F893c4b14121] = true;
        whitelistAddressMap[0x2169C7ec10350e7F38603Db8237F5fE4602B62e1] = true;
        whitelistAddressMap[0x2297c5133b6eEaDab7BEBdbEB1820dF14c6aCBA3] = true;
        whitelistAddressMap[0x256d65D50cD60e192E3300D593D54A58Dc06238e] = true;
        whitelistAddressMap[0x294C2a8BD233fAd3D9c29e9362A42f8881f4461B] = true;
        whitelistAddressMap[0x29e5d52016Bc342d01250d4C8305eB097cD37DAf] = true;
        whitelistAddressMap[0x2A89Ca1CbbA98e6F37539C12B4F7f0806B382596] = true;
        whitelistAddressMap[0x2B13A9A626aC6F12F9b7047C4a6Cb0f504194a01] = true;
        whitelistAddressMap[0x2B242241d497bfC471b6D4F26e34bd9A51E12Da5] = true;
        whitelistAddressMap[0x2bb713b923fB1bBBac81881DA533dee574b054ce] = true;
        whitelistAddressMap[0x2C9a5ecCafD96F9BF2aF76718D1b49A41ddB1ef9] = true;
        whitelistAddressMap[0x2CF5085d68CE7c25D7678a3a9BCC6DCC8fcB66e3] = true;
        whitelistAddressMap[0x2E36623B7FfB5829E6d61Bc4D5F70Aaca4c1c4a2] = true;
        whitelistAddressMap[0x2FF9cF61f88938940b400d93c91BB973C0fd2921] = true;
        whitelistAddressMap[0x31E73D65e715fc80469edC3c3FeC77E9478097Be] = true;
        whitelistAddressMap[0x32c37dFB62C51896383DF04212889C4a01bBDc6A] = true;
        whitelistAddressMap[0x3454686e7Ef12904D20b32a57222572D196C662c] = true;
        whitelistAddressMap[0x387c15a2F8C008ac737061d078B6195CedB9C4CB] = true;
        whitelistAddressMap[0x394ecfBc4caefb3065c072D5060B11Fa6E31741d] = true;
        whitelistAddressMap[0x3958F7EA181E8A6De32D1e9fcC134546012f6E47] = true;
        whitelistAddressMap[0x3a2f7A9cc533a3BC75bB6614537578AC657527e5] = true;
        whitelistAddressMap[0x3b0F5C031ddE33939CEdA9873304f6730e9dEC16] = true;
        whitelistAddressMap[0x3dD8014510b2cde7b185f2dfD1284dDA3B9Bd9D2] = true;
        whitelistAddressMap[0x3F48Bc1debe6925F3d14EEfB4aF237E4A7A1ceEE] = true;
        whitelistAddressMap[0x3F51A98C068D08209979bbD082208CB36711CA4D] = true;
        whitelistAddressMap[0x40aBc300D51d4305781CB864b3f960E428b6B49d] = true;
        whitelistAddressMap[0x4109266acaC7Bc28c754884920b059E016DDAf41] = true;
        whitelistAddressMap[0x414Abd3ebcFE3D57C21A580dCDcDA093D06C19F5] = true;
        whitelistAddressMap[0x41a1e092646003dD44BA004f8863f426e71540Df] = true;
        whitelistAddressMap[0x422e3A5175c510BD2c6c1937E7ddEC54881d4F93] = true;
        whitelistAddressMap[0x441dE1F2BdaA19d6Ff7a8Ac0A61e3675825703C2] = true;
        whitelistAddressMap[0x463908d0D4D382311BdCD891A857373F793e2E41] = true;
        whitelistAddressMap[0x46B08b6C219de638c418AaA6B355ef47771e73D4] = true;
        whitelistAddressMap[0x492FcF43a535B329532dC598a75417177920b54C] = true;
        whitelistAddressMap[0x4A3C02ef993C0dbBd5580cAB60d5A576E967B8DC] = true;
        whitelistAddressMap[0x4a4B9A1553dadB071Fe6a53bFE909EC08cB6ce35] = true;
        whitelistAddressMap[0x4ca59bbA3b6B546A6Bdf49cCe4763eee9f5192A6] = true;
        whitelistAddressMap[0x4D22694a2B78Fc87E5C0cD4aC4BC6502612FC095] = true;
        whitelistAddressMap[0x50a305EAADBA9E729c8c988aeeD5BD9FB209Ee0D] = true;
        whitelistAddressMap[0x50C77E7F4a83dE5Fb9e3B1eC6e157520BFcE9b61] = true;
        whitelistAddressMap[0x516F13545C7BB348deB39eA1A6FFE3F89A2fc423] = true;
        whitelistAddressMap[0x5220A01A6F11E32f96DfB28CBC51CE94991F620C] = true;
        whitelistAddressMap[0x52953b76DBF4CdC905bA243a25055850E2B75DBe] = true;
        whitelistAddressMap[0x5A3097B82062CB2c64D9d0a68B6964cE94945bed] = true;
        whitelistAddressMap[0x5F71132134580A8bE3715d2C0a116Fb576924FE1] = true;
        whitelistAddressMap[0x5f9569AE88b5f3958aCE0068511C3Ce2bFd08b9F] = true;
        whitelistAddressMap[0x62Aae6031dB7e283e4A486Fce0309d2A5d66983C] = true;
        whitelistAddressMap[0x631fadefB037aD1119A9eb7AAc3479a3E215100E] = true;
        whitelistAddressMap[0x632056FaCfe2E380c21dE52221B6620074482f84] = true;
        whitelistAddressMap[0x670cdd4f75Ae6706E0996372f8C775e5e8a847a4] = true;
        whitelistAddressMap[0x698F16Ac5E9f2bA4365f8190Ad435bC7897fFA9f] = true;
        whitelistAddressMap[0x6a2Af8b9008b07D7C98efE5A23636bd8fE60DB7A] = true;
        whitelistAddressMap[0x6A9065271055E710116209C8032D2e18e42535A7] = true;
        whitelistAddressMap[0x6d15972017AB9Ec0F2dFFFAf84eCE0cC3ec04359] = true;
        whitelistAddressMap[0x6e7191052F51f96eF48e7bdf14A00Ab1EAB18496] = true;
        whitelistAddressMap[0x6EAf52ac0046D8233976cb79bb46e7d90e7D94aD] = true;
        whitelistAddressMap[0x70a0876D097b4410A7e1a5acc2F1e0a13bf924C5] = true;
        whitelistAddressMap[0x72D3A35c18ff364101E67363113c7c3B3F4AbB42] = true;
        whitelistAddressMap[0x75697d4802423fdAb397ABB3F5dE74cb311B3A6d] = true;
        whitelistAddressMap[0x781E66b72630351541939e4C7f83fe4CA5F0d82E] = true;
        whitelistAddressMap[0x782bB2A5BAF4051FC1393dbF98F14B295B3A7D4f] = true;
        whitelistAddressMap[0x7b73a820927a768954938DB29D787F4B655107B0] = true;
        whitelistAddressMap[0x80E4a18Db248C7DE222fa9F6e48372590456694D] = true;
        whitelistAddressMap[0x818D98D137764d978dB848182967Ad11706CdB52] = true;
        whitelistAddressMap[0x83F8D743947101D39C0BF2E27553609BBD71Dc23] = true;
        whitelistAddressMap[0x852A6af6c0fd8fFBc90f8a3408861FcB2732636f] = true;
        whitelistAddressMap[0x858e9387089E882F383E8B4b338b266a1d422CD9] = true;
        whitelistAddressMap[0x85b0764eC26D1f53E48BBE8CfaC4345144d39C67] = true;
        whitelistAddressMap[0x89938390f5a31bC7860C8B9F456E02FF97448a91] = true;
        whitelistAddressMap[0x8A9C21AC31421567e62a33d867d8eB5eA5b4A890] = true;
        whitelistAddressMap[0x8aA60881Dde54833fd2e2186EE7a9661440c16A1] = true;
        whitelistAddressMap[0x8ff5390D72E22Cb4E1F3AeC2b3301310f4023E80] = true;
        whitelistAddressMap[0x9113eb1aC0Eb21c78347eaD2De999F1787B6dcB8] = true;
        whitelistAddressMap[0x925dFB35442bc204D60281B84819Fb4747B61BB6] = true;
        whitelistAddressMap[0x9489E2a1556371CfEbf4e5AEb6161fccB71faAdA] = true;
        whitelistAddressMap[0x94e419e764D5C1AEB7dBC5afEbf7d13aF53bC9d2] = true;
        whitelistAddressMap[0x9637D3dD9213EEc18618ddf510F0d891f2854AB8] = true;
        whitelistAddressMap[0x9C98F3a430163C1D3F07C33479719D0d1cC96478] = true;
        whitelistAddressMap[0x9cBAF379Dd6e3f7457184Cb335160211074b3851] = true;
        whitelistAddressMap[0x9FfD7Bf7bfAa1012e01CBf906F926817a3ddB307] = true;
        whitelistAddressMap[0xa05F2f31F81CCe809c183Df0fB8050D4926e772c] = true;
        whitelistAddressMap[0xa1129eD1f31EB318afe98d8c41BD12cbFacb9f75] = true;
        whitelistAddressMap[0xa30c2f5FE633f16a435231820c1Ba2F6cbaba5D9] = true;
        whitelistAddressMap[0xA7A9e6137D2582fC8bDDAD6A6dAEb8fB985396F2] = true;
        whitelistAddressMap[0xaA67Ab4F0CFcb7dC5050a0166653a81208e302fF] = true;
        whitelistAddressMap[0xAC1281Db6B2D853F01FD1fe85cD6d6dC4096Ca7B] = true;
        whitelistAddressMap[0xaC3b76cA9D5a6f157DA72415881A4fedCE88baF2] = true;
        whitelistAddressMap[0xad1F277b0154b485DE16Aa3a6AB8D5Cb88d0299C] = true;
        whitelistAddressMap[0xAE7d48103a53535C6D7Dc38Df302b98e84aEfa0a] = true;
        whitelistAddressMap[0xAF5DE4777c33Ae69505Fd190D6eB26F78b5d51B7] = true;
        whitelistAddressMap[0xAFB2c01f5Ee0cb9D5BA04bA5B6398C3799E0c718] = true;
        whitelistAddressMap[0xaffb9Ad129E2966E60701c32d4028fdF6fFc27f9] = true;
        whitelistAddressMap[0xb774432b01aD131Bf81CBd3034DCd750B08211F9] = true;
        whitelistAddressMap[0xB8B7245eaC1ad2E82d380071d3ee0CBB547EAB2C] = true;
        whitelistAddressMap[0xBE36a4DD37dcb8692EF52947FCa828562A206244] = true;
        whitelistAddressMap[0xbe836BF050418a7F3CBf54284D49DaCa491fe3A3] = true;
        whitelistAddressMap[0xc19cB68Da68580D3BF65613Af5750D01b7E0fB54] = true;
        whitelistAddressMap[0xc1fE7165B99615B393Cb0CbCe8A2071116053c79] = true;
        whitelistAddressMap[0xC42A8aBEbEA0D36775f4d274e0Cb87e160e02945] = true;
        whitelistAddressMap[0xC62DDf5Ac2DbC88C3B63f2721D77c42881341Be9] = true;
        whitelistAddressMap[0xC8Dd81E7319339326B95FA16A43E19f4B295aC1e] = true;
        whitelistAddressMap[0xc95b7339A006B5A1Eb1d8e500E80019547627A89] = true;
        whitelistAddressMap[0xc9690a37D571304fF0bD61E756A158A99eE55E0c] = true;
        whitelistAddressMap[0xcAdA38b3D2e3d8714E783ae8C420B4024817E3E8] = true;
        whitelistAddressMap[0xCb0B0600eB5B2f63596913FeB74eE060BC4F1e72] = true;
        whitelistAddressMap[0xcCB3C6eD6CB22da170304A5143b76453997aE3fd] = true;
        whitelistAddressMap[0xcCb868C79C13FD47e3967C51D6Ea304c7D425Ab0] = true;
        whitelistAddressMap[0xd03e3397DEFC9f155D4d6605A33ea19d78B210E7] = true;
        whitelistAddressMap[0xD06A5a1E40c666fEacFEfbCB7bcc94d022D9f37C] = true;
        whitelistAddressMap[0xD229A3c9C05185d4ce2f453724877EcB1Bd3d269] = true;
        whitelistAddressMap[0xD6BB3fA74DFc35e5128B48aB0e246A1608A036Fc] = true;
        whitelistAddressMap[0xDadC7A0F411BbdB6dA1f467eAd25b618121860f3] = true;
        whitelistAddressMap[0xdfC0F066a606561d2EfEDf0FA9747942087E89BD] = true;
        whitelistAddressMap[0xe35f840748166072F906791d28d6097413bb0683] = true;
        whitelistAddressMap[0xe475947928C61003940bc0F28Cf44bB80202eDE9] = true;
        whitelistAddressMap[0xe619D091233580cc171E4AFDaD94D98c16Fd5a0C] = true;
        whitelistAddressMap[0xe6d963027FC4682f6C77Dcc0F1c09795D8b5A907] = true;
        whitelistAddressMap[0xEc0a7e357cfd98f8C2586832DD704Bc77cF5b72d] = true;
        whitelistAddressMap[0xEc8EDfAe340278B79a9a7Ba58C8f97b36f3739Ef] = true;
        whitelistAddressMap[0xEc9e85445048ad43fCBd96eEdb1c324334d04379] = true;
        whitelistAddressMap[0xf17Ba6F67aD3eB8fFAb3164f8e22f112B9304d2f] = true;
        whitelistAddressMap[0xF2b2cd027741373A5a7d8eCd75e7cC4E5427D195] = true;
        whitelistAddressMap[0xf4Ada3108Ad3089582269751E96baf34f6A5a3E5] = true;
        whitelistAddressMap[0xf4cFA4CeD07Cf430903c851603424041649C78C0] = true;
        whitelistAddressMap[0xf4F041438735eaA35c4908e863DFf9CCA9565f41] = true;
        whitelistAddressMap[0xf71F50AD3d8E6c48cC15e7Ec29A62A0a9E17bE65] = true;
        whitelistAddressMap[0xF7d56C885777140B4c800E018EedC50e9A86742f] = true;
        whitelistAddressMap[0xF96b453acd15b5822A5C3a4ef4211CA58027C672] = true;
        whitelistAddressMap[0xf9B9ceB7680d269818D3BC5fA5CAe9a14981E008] = true;
        whitelistAddressMap[0xfAfC2AA937A8d973267543960670d966e2b759A2] = true;
        whitelistAddressMap[0x0Fc8977acAfd9a6158C30A4DfDdf36cABCd2Ff63] = true;
        whitelistAddressMap[0xb6EB448a5D4476717CAC523Fe77c1E8D28B57612] = true;
        whitelistAddressMap[0x2B13A9A626aC6F12F9b7047C4a6Cb0f504194a01] = true;
        whitelistAddressMap[0x02A28434c3E01388C08605db61E4CC67fBB7E8c8] = true;
        whitelistAddressMap[0xd0A698Eb8E80793F641fdC85b1Eb10a4D9264A1F] = true;
        whitelistAddressMap[0x5465f838D85878fddCA1e004894BB629432ab868] = true;
        whitelistAddressMap[0x02058C65a69f14841Ec7Ca2711F00292Adf1fd7b] = true;
        whitelistAddressMap[0x1B34A8A6445D0A1b5E279469c11cceb9eb131DFC] = true;
        whitelistAddressMap[0x36B85040540621DA83c23bDA9132C5981B17dAB1] = true;
        whitelistAddressMap[0x53C66e340262895a1Bc0F31D6dACA98AfD557220] = true;
        whitelistAddressMap[0x3F51A98C068D08209979bbD082208CB36711CA4D] = true;
        whitelistAddressMap[0xDDFf46e5B1a5a7F8836eDC3c3Dc1686119A26f28] = true;
        whitelistAddressMap[0x7C9c5420CDbCf1786aBf91FCB9E17D2324601C25] = true;
        whitelistAddressMap[0x24eC805cA60187a46d95027B224cD27D3c36e48a] = true;
        whitelistAddressMap[0x0AC4dd0D43A587B5f44Afd3c4E47CE49A5713292] = true;
        whitelistAddressMap[0x14193D084a931f53aEaE4Fb7Cb575809a8a235d4] = true;
        whitelistAddressMap[0xe3244F04C8C1eB63E9DDBC59d37791eAb0eC7679] = true;
        whitelistAddressMap[0x00b1D673083eF4849435ACB19Cc32c68edEa8Cf4] = true;
        whitelistAddressMap[0x8701CdE35d4097D0b170769c4846c4a16258EB58] = true;
        whitelistAddressMap[0x753FEcA04b759f560d64c5D264349E21BC67f3D2] = true;
        whitelistAddressMap[0x436902d3E7b45a1d90791049D369283B49A032AA] = true;
        whitelistAddressMap[0xFe8560331b24D45D6998932b751e8CF3B13bD82f] = true;
        whitelistAddressMap[0x91cc9d8602Fa1Da2829635838Aaa3A9C8568a79A] = true;
        whitelistAddressMap[0x21bF3a3F7ae27763582ffa4fCD3006fbD3990b8c] = true;
        whitelistAddressMap[0x3F7AD74C24F3175cAe850Cc4Ed442eA5DaC0654a] = true;
        whitelistAddressMap[0xAC13fa9Ad1A2fF720c6d7330342151440982D2Af] = true;
        whitelistAddressMap[0xd17DBEFE0E3bcFe658828b45Ac9Eb6B8C7718cb0] = true;
        whitelistAddressMap[0x001Bf5f51453E74aa44dE9eE47F9deB6E896Ca29] = true;
        whitelistAddressMap[0xE8C64C35bc075FBe1c94d62FEa5a4eC6E2397020] = true;
        whitelistAddressMap[0x2c2344fc2f3c2e0442233aA1AE3969866C151aAb] = true;
        whitelistAddressMap[0x7b73a820927a768954938DB29D787F4B655107B0] = true;
        whitelistAddressMap[0xbDd2819dB9CF0b79B9f88F5093E5c67c027CC559] = true;
        whitelistAddressMap[0xB313Afd87A7ae549f1b176477605aa439bB97d88] = true;
        whitelistAddressMap[0x1f1027365A7c4f6652f3c96e895C40EaA92dc399] = true;
        whitelistAddressMap[0x31B4B32eB924c32afa7777B8785351456f246540] = true;
        whitelistAddressMap[0xd4Bc4c2E1b5E49D91d7e0bf07c6025ffEAba1366] = true;
        whitelistAddressMap[0xeFAE08c393Cb4Ef3DD694198c1cf249957A24782] = true;
        whitelistAddressMap[0x14fE3f2889Cd05977Ad4E2508E44Cb0F3D7f56Bb] = true;
        whitelistAddressMap[0x32A14A2eB58B9bFBbe959dc469078D6b2a38b360] = true;
        whitelistAddressMap[0xAc683692902a158bA1a43003e134e45F02BdBE39] = true;
        whitelistAddressMap[0x566d5397DD3E77C36e213e2Cb4d4d103bBaeE3F8] = true;
        whitelistAddressMap[0xb51667DDAffDBE32e676704A0CA280Ea19eb342B] = true;
        whitelistAddressMap[0x02E99a30574e06620DE13DF466CC9dd76Bed6480] = true;
        whitelistAddressMap[0x343E66e0dF7Ef62dae33983d87aC50eD39e7bE35] = true;
        whitelistAddressMap[0x58cbD228a77217F6155417b2521Cb9E16739bd0a] = true;
        whitelistAddressMap[0x7459f623AE785D550Ed3690808a65683211504B1] = true;
        whitelistAddressMap[0x0fFac36e4fFC971bff337b9D367fC27f99EAA21f] = true;
        whitelistAddressMap[0xEd2dbcC0B8369B88A7Ec9551E906F69E07e7C239] = true;
        whitelistAddressMap[0x1B34A8A6445D0A1b5E279469c11cceb9eb131DFC] = true;
        whitelistAddressMap[0x7B5213D712430d286241C1B7e3A1eB9148f3Ec5a] = true;
        whitelistAddressMap[0x8701CdE35d4097D0b170769c4846c4a16258EB58] = true;
        whitelistAddressMap[0xE0C8Ff5e3337B37A51Ae604BFf704F1684d1779c] = true;
        whitelistAddressMap[0x4be9CA5267A8F4aF9D12f8Ed3b1aCFDd0eA33c1F] = true;
        whitelistAddressMap[0x02058C65a69f14841Ec7Ca2711F00292Adf1fd7b] = true;
        whitelistAddressMap[0xDb5D099a6d2f2BC090Fcd258CC564861d552C387] = true;
        whitelistAddressMap[0x297a43a06C1055fD6903B2136DaE1cb83330C3CF] = true;
        whitelistAddressMap[0x938a49E24fD7A26149Dd537019078D8a8F919290] = true;
        whitelistAddressMap[0x7459f623AE785D550Ed3690808a65683211504B1] = true;
        whitelistAddressMap[0xde0Fa6299B4CdD054ce4d0C263305E37fB32f749] = true;
        whitelistAddressMap[0xeFAE08c393Cb4Ef3DD694198c1cf249957A24782] = true;
        whitelistAddressMap[0x7453606f794E451a8927C97c3D2E031C7bAC0250] = true;
        whitelistAddressMap[0x762e952805612a7f9A33aC722f9BE3BdDB5dE242] = true;
        whitelistAddressMap[0xDf9FbFAF274ddC01Ef8fC7C332Bc158fdCA316F8] = true;
        whitelistAddressMap[0x6E9f4a40895b8956439E3265F9734236ca1f3D5C] = true;
        whitelistAddressMap[0x0ED32D315a337be21c9DF4f64F20a9edA6139854] = true;
        whitelistAddressMap[0x42BE504Dd2F0104e0397a5D5519aCfA970C1de84] = true;
        whitelistAddressMap[0x31B4B32eB924c32afa7777B8785351456f246540] = true;
        whitelistAddressMap[0x30488E740c18315434Cfc77E5990E0e6C94dEB4C] = true;
        whitelistAddressMap[0x6C17a1CA8F71D9Fd9f9FEfA2707ebA950fe2FcbB] = true;
        whitelistAddressMap[0x38C0c04aEFBA0Fcb3700430D5117906BE374a929] = true;
        whitelistAddressMap[0xB47056A91CcBb396003C12645319a3a2e69fbEfB] = true;
        whitelistAddressMap[0x5BD050a072F7DcEA2B3eEbEfCEd25e6EB4085d87] = true;
        whitelistAddressMap[0xa5BE60342CAe79d55ae49d3a741257a9328a17EA] = true;
        whitelistAddressMap[0x853A858D119E727631102FbCE9C6c823A29013a4] = true;
        whitelistAddressMap[0x54d3ad1f57D37bF383566784601f4e1c151BF8cc] = true;
        whitelistAddressMap[0x980F18a06a74005ff6BaA867fF617198db85a590] = true;
        whitelistAddressMap[0x7AA07bDD8955833F45a946a735381131610DDd64] = true;
        whitelistAddressMap[0xa8ac9C0403d8a31cfC1Bf43e09231C0FfAf52dd7] = true;
        whitelistAddressMap[0x901f1A621bE23367292633B0182A03FDBa6160f9] = true;
        whitelistAddressMap[0xd799C2fE0dd489adFC2CffBa99233c7f8ee99dA8] = true;
        whitelistAddressMap[0x876A1267a2870865C973714B7FA6cd3623cA10E2] = true;
        whitelistAddressMap[0xc1617D31bC78d87CC09065dFAcE6C475caA2BC00] = true;
        whitelistAddressMap[0xEb2439085D03f4D6610108519823410f6B2aCbd8] = true;
        whitelistAddressMap[0x4a53133cc77F32b01B36211f3020FdAe0E484987] = true;
        whitelistAddressMap[0x2A7B0ae50aD7271e5B24FEF62b33ea5B1193ffa3] = true;
        whitelistAddressMap[0x1a016834F4C2869Bff27996Da19118658b6f1FA4] = true;
        whitelistAddressMap[0x9a08B67bF102d96Fc138a8d0F2626a60248918f9] = true;
        whitelistAddressMap[0x8677268c1A3BB3183344dCB159d3f9611f912947] = true;
        whitelistAddressMap[0xc28cA830AD6c3138432D305286E66FA7Ec12446D] = true;
        whitelistAddressMap[0x4ADa632eB41B94cac37A18c6D1196A9323611e1d] = true;
        whitelistAddressMap[0xfb631490deC6174E6819C879F4A5044D6ed97829] = true;
        whitelistAddressMap[0xdE3Cd9455b4a697d2313019b7dD9f870358B119b] = true;
        whitelistAddressMap[0xD94FEe622EA1F5eb550C9846a0229791225420AB] = true;
        whitelistAddressMap[0xD6FB966977F0d317B8250dea56EC628e940dFeBA] = true;
        whitelistAddressMap[0xcAEbE5C13c5756984738163e332EaB0e449cCCe8] = true;
        whitelistAddressMap[0xBebBC616f93e877dd95D8478441897FC69b066c7] = true;
        whitelistAddressMap[0xba58236b379c7F2f5a0600dFdd851662F5db20c6] = true;
        whitelistAddressMap[0xB28E3e084B674d263fa3E4B5B80df4c6eD6fE570] = true;
        whitelistAddressMap[0x900fA4aaF307fa89517CBf745b7C13F2dea1aE5E] = true;
        whitelistAddressMap[0x8C2ED787afa60Dc4E0A31721c800ac530d565559] = true;
        whitelistAddressMap[0x881026517DD743C167527159a1539E2cc04d5b75] = true;
        whitelistAddressMap[0x7A0321e385CACbF7241bc53e7aeE32C12830C02F] = true;
        whitelistAddressMap[0x79d3D692b3a08a5EB6144184cbC92A8dd97b71A7] = true;
        whitelistAddressMap[0x43Cf389c9B5F05075B44FD83f02f72ECbf0759E0] = true;
        whitelistAddressMap[0x3fF873F96B69FC6ba5A575855369a14A502d1087] = true;
        whitelistAddressMap[0x327A778398859279Fc9aAe0D3a06622350E57037] = true;
        whitelistAddressMap[0x2D750F37415EA2Cd039b8e0b20E37671E742B05F] = true;
        whitelistAddressMap[0x2784D0Af81B14C7486fe0DC21daFf4987E7b37b5] = true;
        whitelistAddressMap[0x14a0c9F1A9482BF5f8FB749bA425B2a8DBB318ef] = true;
        whitelistAddressMap[0x1022C7a16C895095b6681CD49A601Afe980F407c] = true;
        whitelistAddressMap[0x0EE3D3126663E75A4f98Bf114f074574c98dcb7E] = true;
        whitelistAddressMap[0x5bFBB0Cb89c2EEe5417bfAa855BA1e8e85Ac4c45] = true;
        whitelistAddressMap[0xd699e5b3b80fEb2E86d9bA11F9EaCc77AB3D0976] = true;
        whitelistAddressMap[0x16e12a6223A75702872d143e4BAfD26B83C0aD48] = true;
        whitelistAddressMap[0xcC6804ab377Be1E348c756D5A429529207852330] = true;
        whitelistAddressMap[0xcC6804ab377Be1E348c756D5A429529207852330] = true;
        whitelistAddressMap[0x8B61B6E70F9462cb4dEDF3Ad3fB29b6B1f39Be96] = true;
        whitelistAddressMap[0xf3119222FefD46875391333Ed596246194717f70] = true;
        whitelistAddressMap[0x465050115C77566C87344B740a40095444bc0205] = true;
        whitelistAddressMap[0xFF1882511a5673194b252c35f2530562f74F47e4] = true;
        whitelistAddressMap[0x8B09120CA4485B94b2fA94C74dF31930c049Ca63] = true;
        whitelistAddressMap[0xAC17598D5d6E8D485fB5E0CE789F38F20fd5562f] = true;
        whitelistAddressMap[0xf230A456EDFd0fe2512909A9D6DB4E0D5BaB40bf] = true;
        whitelistAddressMap[0x858e9387089E882F383E8B4b338b266a1d422CD9] = true;
        whitelistAddressMap[0x3E53b87BC8d86D0983921Ff2e4336044d063f745] = true;
        whitelistAddressMap[0x4e8DB76952BFDA859545d399f54c15E6b14607D5] = true;
        whitelistAddressMap[0xA16878Bb974e7E0a9a1eeAe45aF80991a2a7800d] = true;
        whitelistAddressMap[0xe9Ea8C61C4901f570ED0909356748da5c43Cd915] = true;
        whitelistAddressMap[0x7b73a820927a768954938DB29D787F4B655107B0] = true;
        whitelistAddressMap[0x7b73a820927a768954938DB29D787F4B655107B0] = true;
        whitelistAddressMap[0x1B34A8A6445D0A1b5E279469c11cceb9eb131DFC] = true;
        whitelistAddressMap[0x8A81ff495B09dd173372B1df2cFEF6eC0f2832Fa] = true;
        whitelistAddressMap[0x24eC805cA60187a46d95027B224cD27D3c36e48a] = true;
        whitelistAddressMap[0x02a4C00Fb549aF9D7D999787B130f1D3c03087F0] = true;
        whitelistAddressMap[0x18f6de4643248aa65a090C1D3546ec7a9eB5cdC6] = true;
        whitelistAddressMap[0xd63fC5Ac96BFfFF69bB2CcD6b85983093802c249] = true;
        whitelistAddressMap[0xB51ab6743C20F9d434BA4BaCC6CcFc3f9f0bb5Fe] = true;
        whitelistAddressMap[0x254fF55eBF502fA8306a2F255E966ea1708EF134] = true;
        whitelistAddressMap[0x783255a509d007D2036F11d6BA53E162bd7a67C1] = true;
        whitelistAddressMap[0x4f767B1ea9620e31844126A6B94eC069e327F01c] = true;
        whitelistAddressMap[0x4D9F0933647d9846010ff534381e8e6005f16E9b] = true;
        whitelistAddressMap[0xB415541f923905B36B174A7ABf03Ad00539508A1] = true;
        whitelistAddressMap[0x9f1192009D492E3739F40FD461612659109e0178] = true;
        whitelistAddressMap[0x86D75B45B14b91d4098E3a2f13C89A1344F2Bdd6] = true;
        whitelistAddressMap[0xfCc703cc9D0b36668ae1530A30f2c4da57Bb91b3] = true;
        whitelistAddressMap[0x136e409d3C13DbF044d8eCa5e6c22cb0a7915500] = true;
        whitelistAddressMap[0xF60721905a8e8b88a470f3cE23893cbEbA567458] = true;
        whitelistAddressMap[0x00734C35781e874D565e45154Ce86f7c30055842] = true;
        whitelistAddressMap[0x1ec64f674f32307373E24d629062c966a4a74552] = true;
        whitelistAddressMap[0xa28ef9AB58Ae6d14C23f8855852346C9510e49a3] = true;
        whitelistAddressMap[0x3B3e2D5825774162761842a0524907e1EdfFbefa] = true;
        whitelistAddressMap[0x56F4c5d870bB5De432A0E56c47272cc8638655b4] = true;
        whitelistAddressMap[0x947a518695f63096650E7bFD421fd9be8b38be3A] = true;
        whitelistAddressMap[0xAB9DA90677da892a50767354422Dd259Be4eF687] = true;
        whitelistAddressMap[0x511f044217eBC1B173ac2569A4DA056cADC5ae6c] = true;
        whitelistAddressMap[0xf77bB93D483b991a3bcb72e8D17F619774582944] = true;
        whitelistAddressMap[0xe403C8BE3730f62547C2a61B4c6F6d002e5Fd355] = true;
        whitelistAddressMap[0xA0bE1D03e53f43f67d6637A4Fa0CA98e66a25Fce] = true;
        whitelistAddressMap[0x51a4ec173A20f1ff15832D221022D45E98981E03] = true;
        whitelistAddressMap[0x94b6e0Cf808871df9960Be19dcfDCdD9cCc27e62] = true;
        whitelistAddressMap[0xA941600923bA1E68036D9b71c0376f10Efe9ebFd] = true;
        whitelistAddressMap[0x84467fb16Ec9E6c8BEaAd05ce5c1b4c82775a7c1] = true;
        whitelistAddressMap[0xD568A8E5889f9ed2ef6AceBfA6f3F789640Ae951] = true;
        whitelistAddressMap[0x00000084B1B0bCDd18D99eD57469A508C751b055] = true;
        whitelistAddressMap[0xAeD884B7533351fC93668A18DB765668305c6f84] = true;
        whitelistAddressMap[0x9EF8286006D73A5d687eE10675BD84853a406f4c] = true;
        whitelistAddressMap[0x33333333392b691AA2cE6D9fE3D2E5dCF779098C] = true;
        whitelistAddressMap[0xe19843E8eC8Ee6922731801Cba48E2dE6813963A] = true;
        whitelistAddressMap[0x70f71535500674312c92f9c8a7fE28b088D0F96C] = true;
        whitelistAddressMap[0xDd4efC1D0e40BfAF51dB0cA84ea6a8e49C685b2f] = true;
        whitelistAddressMap[0x9D79E24A158A4b2957b1Fb208a9e6d705a3531F5] = true;
        whitelistAddressMap[0x978DC1A5978BBeD895B5d01BF82FB5229d31185b] = true;
        whitelistAddressMap[0xAeE8212c786C724D5682735D906a7b1E459fEF3f] = true;
        whitelistAddressMap[0x5748561B457b76D9E873c5D34df4D0dA2c119cF8] = true;
        whitelistAddressMap[0x3596dfC666002218dE69c1331Ec3772B26FED1CE] = true;
        whitelistAddressMap[0xce5B30FDFbb67b4868ABA01754298067fF658778] = true;
        whitelistAddressMap[0xc6579463baB5BCB90a9635bef91CcAa78fFFD7b1] = true;
        whitelistAddressMap[0xDf087C9FE7f42e45b66Fa22BE028AD50E4C90234] = true;
        whitelistAddressMap[0xFECEA928a996918DFE3242E7580bA3288d4CCD2C] = true;
        whitelistAddressMap[0xF3a9008f4219B5F9B73844D00d6649c4705e9A67] = true;
        whitelistAddressMap[0x4F6E4EDD7A845618B4a0A3F63347D85e6bF47853] = true;
        whitelistAddressMap[0x2AD2fBFd490883769F030CBDFE75AA7e86f74236] = true;
        whitelistAddressMap[0x07967E4637056c5f1781104ac00cDA3B2C8478c0] = true;
        whitelistAddressMap[0x723a42724CA4171CD8E58cBB58c5556755bC0C48] = true;
        whitelistAddressMap[0x325b8ECB5d7EBAaE0811A848F3730c66A03ED610] = true;
        whitelistAddressMap[0xd68E70e207EE9326a0C4E8eef1c342981790BA3E] = true;
        whitelistAddressMap[0x516D8741F7A3cCF96F2C2e6516805913741bEeC3] = true;
        whitelistAddressMap[0xC42434a20907e6DBE8eA46CfB22310B0D567F626] = true;
        whitelistAddressMap[0xe6384B0800a242654f7C6fb221CC37A58d5e0A0A] = true;
        whitelistAddressMap[0x94F58628F644753f56C955637afB33Cf0b33EA1F] = true;
        whitelistAddressMap[0x691c31F25382f6248d9179a09f566013944D126D] = true;
        whitelistAddressMap[0x4f22eCb1CF3c37cacB215C5884E74cB5bba425B7] = true;
        whitelistAddressMap[0x2105d66926a88E240e132d5452dE6A9518e742Db] = true;
        whitelistAddressMap[0x672B251834E1616ab8269096bD06840875DEB4CF] = true;
        whitelistAddressMap[0x1bA1e53FfDF291D16a2A9AD7f30008B4916F93a0] = true;
        whitelistAddressMap[0x808cb2d92E6C3410C611960f8F44246Fd9928902] = true;
        whitelistAddressMap[0x792F3305f1D006e55596cbe94E4191360CFDa38E] = true;
        whitelistAddressMap[0x749de39c297821f01f595fcefBE1F8946F5a07B6] = true;
        whitelistAddressMap[0x4469C84FeEBfd722BB014aEF08277dE6cFF9703F] = true;
        whitelistAddressMap[0xB3543A0a7786d72B89A4B2BAA8Ff9A2eb73ee0e5] = true;
        whitelistAddressMap[0x4dD6cB67852d2155fE30bd1d7481eeE52C56b082] = true;
        whitelistAddressMap[0x04B75af9Cb2612aDec5d1D776B164eD4B864850B] = true;
        whitelistAddressMap[0xB0C09248cdA7a4398bacE802b8B2b9a74F1D9739] = true;
        whitelistAddressMap[0x08BD425B30A2CeEA091F9C360A1d60f82C9a8ce3] = true;
        whitelistAddressMap[0x52b1Ba83f78fa4f9759e7eC2AF94575Eef6E06F2] = true;
        whitelistAddressMap[0xe51c036af38ad391De9741Da73d88ee0AC63CA2D] = true;
        whitelistAddressMap[0x12bed0d3a71484f011947Eda206d9bd847faC47E] = true;
        whitelistAddressMap[0xb085F541951eF85DaAD1Ff444b7588e68e729b2F] = true;
        whitelistAddressMap[0xcdfE1b9873c22bbF66B2e5Bf8b2E9b4f5825fc18] = true;
        whitelistAddressMap[0x854f8d4930C838A24e9AF8E5c665b44597aEf15B] = true;
        whitelistAddressMap[0xaDf31A0Ed9cEAef4CaB6a910eA65Ce2A5370dab2] = true;
        whitelistAddressMap[0x82224D5ea1Db1A8507e4fFe25353B28B50e4D2ed] = true;
        whitelistAddressMap[0x39CA85b8055e3aE4063624e704f0a45aBe5c327B] = true;
        whitelistAddressMap[0x7420f408BB680036c33404f7471388fD07A159D1] = true;
        whitelistAddressMap[0x37d7716e10bAEDDb1b30b233774f0E14b05F9af1] = true;
        whitelistAddressMap[0x34e535662270D8B4aae7C6f78C8E68C3A7ccF944] = true;
        whitelistAddressMap[0xbCfA62cb2c603A3abC0ce0B368D0834e1883edA8] = true;
        whitelistAddressMap[0x5aF688cC1F3Ad924d50163D8a8cc52663B499F0B] = true;
        whitelistAddressMap[0x67B40fE9C56a6bB0B8312D8D1F6F9209D5D9F235] = true;
        whitelistAddressMap[0x70197B92164C7349adf93568457b57aa1c440741] = true;
        whitelistAddressMap[0x432A5Cb15930a3DBA1af2dab9981B22CB7Ca5A77] = true;
        whitelistAddressMap[0xA47e0A26A9783e1Aea2BBAd29a93DCC44F36cCF3] = true;
        whitelistAddressMap[0xfD4F38cfDF78bc7E8BCBa0d22cd1100101ada175] = true;
        whitelistAddressMap[0xa0996658F2ddE70b259fEF07e97c033FE6a6aFBb] = true;
        whitelistAddressMap[0xe9Ea8C61C4901f570ED0909356748da5c43Cd915] = true;
        whitelistAddressMap[0x4b393c6C0d308e20352c154605f73464475663CB] = true;
        whitelistAddressMap[0xdE401a40A010a0fba1404B8f976871A0eB65aDe9] = true;
    }

    /* ========== MODIFIER FUNCTIONS ========== */

    modifier checkTime(uint256 _amount) {
        if (
            block.timestamp >= startTime - 300 &&
            block.timestamp <= startTime &&
            whitelistAddressMap[msg.sender]
        ) {
            require(buyCountMap[msg.sender] == 0 && _amount == 1, "limited");
            _;
        } else {
            require(block.timestamp >= startTime, "sale has not start");
            require(block.timestamp < endTime, "sale ended");
            _;
        }
    }

    /* ========== READ FUNCTIONS ========== */

    function getMockTs(uint256 startSeconds, uint256 endSeconds)
        external
        view
        returns (uint256, uint256)
    {
        if (startSeconds == 0) {
            startSeconds = 60 * 2;
        }
        if (endSeconds == 0) {
            endSeconds = startSeconds + 600;
        }
        return (block.timestamp + startSeconds, block.timestamp + endSeconds);
    }

    function getBoxPrice(uint256 _boxType) public view returns (uint256) {
        return boxPriceMap[_boxType];
    }

    function getBoxStock(uint256 _boxType)
        public
        view
        returns (uint256, uint256)
    {
        return (boxStockMap[_boxType], boxTotalMap[_boxType]);
    }

    function getSaleTime() public view returns (uint256, uint256) {
        return (startTime, endTime);
    }

    function isInWhitelist(address _to) public view returns (bool) {
        return whitelistAddressMap[_to];
    }

    function getBuyCountMap(address _to) public view returns (uint256) {
        return buyCountMap[_to];
    }

    /* ========== WRITE FUNCTIONS ========== */

    function setSaleTime(uint256 _startTime, uint256 _endTime)
        external
        onlyOwner
    {
        require(_startTime > 0 && _endTime > 0);

        startTime = _startTime;
        endTime = _endTime;
    }

    function setNewReceiver(address _new) external onlyOwner {
        require(_new != address(0), "zero address");
        receiver = _new;
    }

    function setNewPlatformReceiver(address _new) external onlyOwner {
        require(_new != address(0), "zero address");
        platformReceiver = _new;
    }

    function setBUSDAddress(address _new) external onlyOwner {
        require(_new != address(0), "zero address");
        BUSDAddress = _new;
    }

    function setNFTBoxAddress(address _new) external onlyOwner {
        require(_new != address(0), "zero address");
        NFTBoxAddress = _new;
    }

    function decreaseBoxStock(uint256 _boxType, uint256 _stock)
        external
        onlyOwner
    {
        boxStockMap[_boxType] -= _stock;
    }

    function decreaseBoxTotal(uint256 _boxType, uint256 _stock)
        external
        onlyOwner
    {
        boxTotalMap[_boxType] -= _stock;
    }

    function increaseBoxStock(uint256 _boxType, uint256 _stock)
        external
        onlyOwner
    {
        boxStockMap[_boxType] += _stock;
        boxTotalMap[_boxType] += _stock;
    }

    function setMaxBuyAmount(uint256 _new) external onlyOwner {
        maxBuyAmount = _new;
    }

    function setBoxPrice(uint256 _boxType, uint256 _new) external onlyOwner {
        boxPriceMap[_boxType] = _new;
    }

    function setWhitelist(address _to, bool _new) external onlyOwner {
        whitelistAddressMap[_to] = _new;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function buyBox(uint256 boxType, uint256 amount)
        external
        whenNotPaused
        checkTime(amount)
    {
        require(amount > 0, "invalid amount");
        require(boxStockMap[boxType] >= amount, "insufficient stock");
        require(amount <= maxBuyAmount, "maxBuyAmount limit");

        uint256 totalBoxPrice = boxPriceMap[boxType] * amount;
        IERC20 paymentToken = IERC20(BUSDAddress);
        uint256 allowToPayAmount = paymentToken.allowance(
            msg.sender,
            address(this)
        );
        require(allowToPayAmount >= totalBoxPrice, "invalid token allowance");

        // transfer token from user to contract
        paymentToken.safeTransferFrom(msg.sender, address(this), totalBoxPrice);

        // transfer token from contract to platformReceiver

        if (address(this) != receiver) {
            // transfer token from contract to receiver
            paymentToken.safeTransfer(receiver, totalBoxPrice);
        }

        // mint box
        IERC721YULIBOX nftBoxToken = IERC721YULIBOX(NFTBoxAddress);
        for (uint256 i = 0; i < amount; i++) {
            nftBoxToken.safeMint(msg.sender, boxType, 4);
        }

        boxStockMap[boxType] -= amount;
        buyCountMap[msg.sender] += amount;

        emit BuyLog(msg.sender, boxType, amount, totalBoxPrice);
    }

    function withdrawToken(
        address erc20Contract,
        address _receiver,
        uint256 amount
    ) external onlyOwner {
        require(amount > 0, "invalid amount");
        require(erc20Contract != address(0), "ERC20: zero address");
        require(_receiver != address(0), "zero address");

        IERC20 paymentToken = IERC20(erc20Contract);

        uint256 balance = paymentToken.balanceOf(address(this));
        require(balance >= amount, "insufficient balance");

        // transfer token from contract to receiver
        paymentToken.safeTransfer(_receiver, amount);
    }

    /* ========== Platform functions ========== */
}