/**
 *Submitted for verification at Etherscan.io on 2023-08-15
*/

// SPDX-License-Identifier: MIT

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

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
pragma solidity 0.8.18;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function INIT_CODE_PAIR_HASH() external view returns (bytes32);
}

interface IGemAntiBot {
    function setTokenOwner(address owner) external;

    function onPreTransferCheck(
        address from,
        address to,
        uint256 amount
    ) external;
}
interface IUniswapV2Caller {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        address router,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint256 deadline
    ) external;
}
interface IFee {
    function payFee(
        uint256 _tokenType
    ) external payable;
}
contract StandardTokenWithAntibot is ERC20, Ownable {
    using SafeERC20 for IERC20;
    uint256 private constant MAX = ~uint256(0);
    IUniswapV2Caller public constant uniswapV2Caller =
        IUniswapV2Caller(0x1CcFE8c40eF259566433716002E379dFfFbf5a3e);
    IFee public constant feeContract = IFee(0xfd6439AEfF9d2389856B7486b9e74a6DacaDcDCe);
    address public gemAntiBot;
    bool public antiBotEnabled;
    uint8 private _decimals;
    ///////////////////////////////////////////////////////////////////////////
    address public baseTokenForPair;
    bool private inSwapAndLiquify;
    uint16 public sellLiquidityFee;
    uint16 public buyLiquidityFee;

    uint16 public sellMarketingFee;
    uint16 public buyMarketingFee;

    address public marketingWallet;
    bool public isMarketingFeeBaseToken;

    uint256 public minAmountToTakeFee;
    uint256 public maxWallet;
    uint256 public maxTransactionAmount;

    IUniswapV2Router02 public mainRouter;
    address public mainPair;

    mapping(address => bool) public isExcludedFromMaxTransactionAmount;
    mapping(address => bool) public isExcludedFromFee;
    mapping(address => bool) public automatedMarketMakerPairs;

    uint256 private _liquidityFeeTokens;
    uint256 private _marketingFeeTokens;

    event UpdateLiquidityFee(
        uint16 newSellLiquidityFee,
        uint16 newBuyLiquidityFee,
        uint16 oldSellLiquidityFee,
        uint16 oldBuyLiquidityFee
    );
    event UpdateMarketingFee(
        uint16 newSellMarketingFee,
        uint16 newBuyMarketingFee,
        uint16 oldSellMarketingFee,
        uint16 oldBuyMarketingFee
    );
    event UpdateMarketingWallet(
        address indexed newMarketingWallet,
        bool newIsMarketingFeeBaseToken,
        address indexed oldMarketingWallet,
        bool oldIsMarketingFeeBaseToken
    );
    event ExcludedFromMaxTransactionAmount(address indexed account, bool isExcluded);
    event UpdateMinAmountToTakeFee(uint256 newMinAmountToTakeFee, uint256 oldMinAmountToTakeFee);
    event SetAutomatedMarketMakerPair(address indexed pair, bool value);  
    event ExcludedFromFee(address indexed account, bool isEx);
    event SwapAndLiquify(
        uint256 tokensForLiquidity,
        uint256 baseTokenForLiquidity
    );
    event MarketingFeeTaken(
        uint256 marketingFeeTokens,
        uint256 marketingFeeBaseTokenSwapped
    );
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldRouter);
    event UpdateMaxWallet(uint256 newMaxWallet, uint256 oldMaxWallet);
    event UpdateMaxTransactionAmount(uint256 newMaxTransactionAmount, uint256 oldMaxTransactionAmount);
    ///////////////////////////////////////////////////////////////////////////////
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 __decimals,
        uint256 _totalSupply,
        uint256 _maxWallet,
        uint256 _maxTransactionAmount,
        address[4] memory _accounts,
        bool _isMarketingFeeBaseToken,
        uint16[4] memory _fees
    ) payable ERC20(_name, _symbol) {
        feeContract.payFee{value: msg.value}(1);   
        _decimals = __decimals;
        _mint(msg.sender, _totalSupply);
        baseTokenForPair = _accounts[2];
        require(_accounts[0] != address(0), "marketing wallet can not be 0");
        require(_accounts[1] != address(0), "Router address can not be 0");
        require(_fees[0] + (_fees[2]) <= 200, "sell fee <= 20%");
        require(_fees[1] + (_fees[3]) <= 200, "buy fee <= 20%");
        gemAntiBot = _accounts[3];
        IGemAntiBot(gemAntiBot).setTokenOwner(msg.sender);
        antiBotEnabled = true;
        marketingWallet = _accounts[0];
        isMarketingFeeBaseToken = _isMarketingFeeBaseToken;
        emit UpdateMarketingWallet(
            marketingWallet,
            isMarketingFeeBaseToken,
            address(0),
            false
        );
        mainRouter = IUniswapV2Router02(_accounts[1]);
        if(baseTokenForPair != mainRouter.WETH()){            
            IERC20(baseTokenForPair).approve(address(mainRouter), MAX);            
        }
        _approve(address(this), address(uniswapV2Caller), MAX);
        _approve(address(this), address(mainRouter), MAX);
        emit UpdateUniswapV2Router(address(mainRouter), address(0));
        mainPair = IUniswapV2Factory(mainRouter.factory()).createPair(
            address(this),
            baseTokenForPair
        );
        require(_maxTransactionAmount>=_totalSupply / 10000, "maxTransactionAmount >= total supply / 10000");
        require(_maxWallet>=_totalSupply / 10000, "maxWallet >= total supply / 10000");
        maxWallet = _maxWallet;
        emit UpdateMaxWallet(maxWallet, 0);
        maxTransactionAmount=_maxTransactionAmount;
        emit UpdateMaxTransactionAmount(maxTransactionAmount, 0);        
        sellLiquidityFee = _fees[0];
        buyLiquidityFee = _fees[1];
        emit UpdateLiquidityFee(sellLiquidityFee, buyLiquidityFee, 0, 0);        
        sellMarketingFee=_fees[2];
        buyMarketingFee=_fees[3];
        emit UpdateMarketingFee(
            sellMarketingFee,
            buyMarketingFee,
            0,
            0
        );
        minAmountToTakeFee = _totalSupply / 10000;
        emit UpdateMinAmountToTakeFee(minAmountToTakeFee, 0);
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[marketingWallet] = true;
        isExcludedFromFee[_msgSender()] = true;
        isExcludedFromFee[address(0xdead)] = true;
        isExcludedFromMaxTransactionAmount[address(0xdead)] = true;
        isExcludedFromMaxTransactionAmount[address(this)] = true;
        isExcludedFromMaxTransactionAmount[marketingWallet] = true;
        isExcludedFromMaxTransactionAmount[_msgSender()] = true;
        _setAutomatedMarketMakerPair(mainPair, true);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function setUsingAntiBot(bool enabled_) external onlyOwner {
        antiBotEnabled = enabled_;
    }

    function updateUniswapV2Pair(address _baseTokenForPair) external onlyOwner {
        baseTokenForPair = _baseTokenForPair;
        mainPair = IUniswapV2Factory(mainRouter.factory()).createPair(
            address(this),
            baseTokenForPair
        );
        if(baseTokenForPair != mainRouter.WETH()){
            IERC20(baseTokenForPair).approve(address(mainRouter), MAX);            
        }
        _setAutomatedMarketMakerPair(mainPair, true);
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(
            newAddress != address(mainRouter),
            "The router already has that address"
        );
        emit UpdateUniswapV2Router(newAddress, address(mainRouter));
        mainRouter = IUniswapV2Router02(newAddress);
        _approve(address(this), address(mainRouter), MAX);
        if(baseTokenForPair != mainRouter.WETH()){
            IERC20(baseTokenForPair).approve(address(mainRouter), MAX);            
        }   
        address _mainPair = IUniswapV2Factory(mainRouter.factory()).createPair(
            address(this),
            baseTokenForPair
        );
        mainPair = _mainPair;
        _setAutomatedMarketMakerPair(mainPair, true);
    }

    function updateMaxWallet(uint256 _maxWallet) external onlyOwner {
        require(_maxWallet>=totalSupply() / 10000, "maxWallet >= total supply / 10000");
        emit UpdateMaxWallet(_maxWallet, maxWallet);
        maxWallet = _maxWallet;
    }

    function updateMaxTransactionAmount(uint256 _maxTransactionAmount)
        external
        onlyOwner
    {
        require(_maxTransactionAmount>=totalSupply() / 10000, "maxTransactionAmount >= total supply / 10000");
        emit UpdateMaxTransactionAmount(_maxTransactionAmount, maxTransactionAmount);
        maxTransactionAmount = _maxTransactionAmount;
    }

    /////////////////////////////////////////////////////////////////////////////////
    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    function updateLiquidityFee(
        uint16 _sellLiquidityFee,
        uint16 _buyLiquidityFee
    ) external onlyOwner {
        require(
            _sellLiquidityFee + (sellMarketingFee) <= 200,
            "sell fee <= 20%"
        );
        require(_buyLiquidityFee + (buyMarketingFee) <= 200, "buy fee <= 20%");
        emit UpdateLiquidityFee(
            _sellLiquidityFee,
            _buyLiquidityFee,
            sellLiquidityFee,
            buyLiquidityFee
        );
        sellLiquidityFee = _sellLiquidityFee;
        buyLiquidityFee = _buyLiquidityFee;   
    }

    function updateMarketingFee(
        uint16 _sellMarketingFee,
        uint16 _buyMarketingFee
    ) external onlyOwner {
        require(
            _sellMarketingFee + (sellLiquidityFee) <= 200,
            "sell fee <= 20%"
        );
        require(_buyMarketingFee + (buyLiquidityFee) <= 200, "buy fee <= 20%");
        emit UpdateMarketingFee(
            _sellMarketingFee,
            _buyMarketingFee,
            sellMarketingFee,
            buyMarketingFee
        );
        sellMarketingFee = _sellMarketingFee;
        buyMarketingFee = _buyMarketingFee;     
    }

    function updateMarketingWallet(
        address _marketingWallet,
        bool _isMarketingFeeBaseToken
    ) external onlyOwner {
        require(_marketingWallet != address(0), "marketing wallet can't be 0");
        emit UpdateMarketingWallet(_marketingWallet, _isMarketingFeeBaseToken,
            marketingWallet, isMarketingFeeBaseToken);
        marketingWallet = _marketingWallet;
        isMarketingFeeBaseToken = _isMarketingFeeBaseToken;
        isExcludedFromFee[_marketingWallet] = true;
        isExcludedFromMaxTransactionAmount[_marketingWallet] = true;
    }

    function updateMinAmountToTakeFee(uint256 _minAmountToTakeFee)
        external
        onlyOwner
    {
        require(_minAmountToTakeFee > 0, "minAmountToTakeFee > 0");
        emit UpdateMinAmountToTakeFee(_minAmountToTakeFee, minAmountToTakeFee);
        minAmountToTakeFee = _minAmountToTakeFee;     
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(
            automatedMarketMakerPairs[pair] != value,
            "Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[pair] = value;
        isExcludedFromMaxTransactionAmount[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function excludeFromFee(address account, bool isEx) external onlyOwner {
        require(isExcludedFromFee[account] != isEx, "already");
        isExcludedFromFee[account] = isEx;
        emit ExcludedFromFee(account, isEx);
    }

    function excludeFromMaxTransactionAmount(address account, bool isEx)
        external
        onlyOwner
    {
        require(isExcludedFromMaxTransactionAmount[account]!=isEx, "already");
        isExcludedFromMaxTransactionAmount[account] = isEx;
        emit ExcludedFromMaxTransactionAmount(account, isEx);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (
            !inSwapAndLiquify &&
            antiBotEnabled &&
            !isExcludedFromFee[from] &&
            !isExcludedFromFee[to]
        ) {
            IGemAntiBot(gemAntiBot).onPreTransferCheck(from, to, amount);
        }
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >=
            minAmountToTakeFee;

        // Take Fee
        if (
            !inSwapAndLiquify &&
            balanceOf(mainPair) > 0 &&
            overMinimumTokenBalance &&
            automatedMarketMakerPairs[to]
        ) {
            takeFee();
        }

        uint256 _liquidityFee;
        uint256 _marketingFee;
        // If any account belongs to isExcludedFromFee account then remove the fee
        if (
            !inSwapAndLiquify &&
            !isExcludedFromFee[from] &&
            !isExcludedFromFee[to]
        ) {
            // Buy
            if (automatedMarketMakerPairs[from]) {
                _liquidityFee = (amount * (buyLiquidityFee)) / (1000);
                _marketingFee = (amount * (buyMarketingFee)) / (1000);
            }
            // Sell
            else if (automatedMarketMakerPairs[to]) {
                _liquidityFee = (amount * (sellLiquidityFee)) / (1000);
                _marketingFee = (amount * (sellMarketingFee)) / (1000);
            }
            uint256 _feeTotal = _liquidityFee + (_marketingFee);
            if (_feeTotal > 0) super._transfer(from, address(this), _feeTotal);
            amount = amount - (_liquidityFee) - (_marketingFee);
            _liquidityFeeTokens = _liquidityFeeTokens + (_liquidityFee);
            _marketingFeeTokens = _marketingFeeTokens + (_marketingFee);
        }
        super._transfer(from, to, amount);
        if (!inSwapAndLiquify) {
            if (!isExcludedFromMaxTransactionAmount[from]) {
                require(
                    amount < maxTransactionAmount,
                    "ERC20: exceeds transfer limit"
                );
            }
            if (!isExcludedFromMaxTransactionAmount[to]) {
                require(
                    balanceOf(to) < maxWallet,
                    "ERC20: exceeds max wallet limit"
                );
            }
        }
    }

    function takeFee() private lockTheSwap {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensTaken = _liquidityFeeTokens + _marketingFeeTokens;
        if (totalTokensTaken == 0 || contractBalance < totalTokensTaken) {
            return;
        }

        // Halve the amount of liquidity tokens
        uint256 tokensForLiquidity = _liquidityFeeTokens / 2;
        uint256 initialBaseTokenBalance = baseTokenForPair==mainRouter.WETH() ? address(this).balance
            : IERC20(baseTokenForPair).balanceOf(address(this));
        uint256 baseTokenForLiquidity;
        if (isMarketingFeeBaseToken) {
            uint256 tokensForSwap=tokensForLiquidity+_marketingFeeTokens;
            if(tokensForSwap>0)
                swapTokensForBaseToken(tokensForSwap);
            uint256 baseTokenBalance = baseTokenForPair==mainRouter.WETH() ? address(this).balance - initialBaseTokenBalance
                : IERC20(baseTokenForPair).balanceOf(address(this)) - initialBaseTokenBalance;
            uint256 baseTokenForMarketing = (baseTokenBalance *
                _marketingFeeTokens) / tokensForSwap;
            baseTokenForLiquidity = baseTokenBalance - baseTokenForMarketing;
            if(baseTokenForMarketing>0){
                if(baseTokenForPair==mainRouter.WETH()){                
                    (bool success, )=address(marketingWallet).call{value: baseTokenForMarketing}("");
                    if(success){                        
                        emit MarketingFeeTaken(0, baseTokenForMarketing);
                    }
                }else{
                    IERC20(baseTokenForPair).safeTransfer(
                        marketingWallet,
                        baseTokenForMarketing
                    );
                    emit MarketingFeeTaken(0, baseTokenForMarketing);
                }                   
            }  
        } else {
            if(tokensForLiquidity>0)
                swapTokensForBaseToken(tokensForLiquidity);
            baseTokenForLiquidity = baseTokenForPair==mainRouter.WETH() ? address(this).balance - initialBaseTokenBalance
                : IERC20(baseTokenForPair).balanceOf(address(this)) - initialBaseTokenBalance;
            if(_marketingFeeTokens>0){
                _transfer(address(this), marketingWallet, _marketingFeeTokens);
                emit MarketingFeeTaken(_marketingFeeTokens, 0);
            }   
        }

        if (tokensForLiquidity > 0 && baseTokenForLiquidity > 0) {
            addLiquidity(tokensForLiquidity, baseTokenForLiquidity);
            emit SwapAndLiquify(tokensForLiquidity, baseTokenForLiquidity);
        }
        _marketingFeeTokens = 0;
        _liquidityFeeTokens = 0;
        if(owner()!=address(0))
            _transfer(address(this), owner(), balanceOf(address(this))); 
    }

    function swapTokensForBaseToken(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = baseTokenForPair;        
        if (path[1] == mainRouter.WETH()){
            mainRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
                tokenAmount,
                0, // accept any amount of BaseToken
                path,
                address(this),
                block.timestamp
            );
        }else{
            uniswapV2Caller.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    address(mainRouter),
                    tokenAmount,
                    0, // accept any amount of BaseToken
                    path,
                    block.timestamp
                );
        }
    }

    function addLiquidity(uint256 tokenAmount, uint256 baseTokenAmount)
        private
    {
        if (baseTokenForPair == mainRouter.WETH()) 
            mainRouter.addLiquidityETH{value: baseTokenAmount}(
                address(this),
                tokenAmount,
                0, // slippage is unavoidable
                0, // slippage is unavoidable
                address(0xdead),
                block.timestamp
            );
        else{
            mainRouter.addLiquidity(
                address(this),
                baseTokenForPair,
                tokenAmount,
                baseTokenAmount,
                0,
                0,
                address(0xdead),
                block.timestamp
            );
        }            
    }
    function withdrawETH() external onlyOwner {
        (bool success, )=address(owner()).call{value: address(this).balance}("");
        require(success, "Failed in withdrawal");
    }
    function withdrawToken(address token) external onlyOwner{
        require(address(this) != token, "Not allowed");
        IERC20(token).safeTransfer(owner(), IERC20(token).balanceOf(address(this)));
    }
    receive() external payable {}
}