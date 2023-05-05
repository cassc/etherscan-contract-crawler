/**
 *Submitted for verification at BscScan.com on 2023-05-05
*/

/**
 *Submitted for verification at BscScan.com on 2023-04-17
*/

/**
 *Submitted for verification at BscScan.com on 2023-04-17
*/

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^ 0.6.0;
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
    function add(uint256 a, uint256 b) internal pure returns(uint256) {
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
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns(uint256) {
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
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
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
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns(uint256) {
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
    function mod(uint256 a, uint256 b) internal pure returns(uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns(uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/libs/IBEP20.sol

pragma solidity >= 0.6.4;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns(uint256);

/**
 * @dev Returns the token decimals.
 */
function decimals() external view returns(uint8);

/**
 * @dev Returns the token symbol.
 */
function symbol() external view returns(string memory);

/**
 * @dev Returns the token name.
 */
function name() external view returns(string memory);

/**
 * @dev Returns the bep token owner.
 */
function getOwner() external view returns(address);

/**
 * @dev Returns the amount of tokens owned by `account`.
 */
function balanceOf(address account) external view returns(uint256);

/**
 * @dev Moves `amount` tokens from the caller's account to `recipient`.
 *
 * Returns a boolean value indicating whether the operation succeeded.
 *
 * Emits a {Transfer} event.
 */
function transfer(address recipient, uint256 amount)
external
returns(bool);

/**
 * @dev Returns the remaining number of tokens that `spender` will be
 * allowed to spend on behalf of `owner` through {transferFrom}. This is
 * zero by default.
 *
 * This value changes when {approve} or {transferFrom} are called.
 */
function allowance(address _owner, address spender)
external
view
returns(uint256);

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
function approve(address spender, uint256 amount) external returns(bool);

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
) external returns(bool);

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
    event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
);
}

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^ 0.6.2;

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
    function isContract(address account) internal view returns(bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size:= extcodesize(account)
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount } ("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
    internal
    returns(bytes memory)
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
    ) internal returns(bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns(bytes memory) {
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
    ) internal returns(bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns(bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue } (
            data
        );
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size:= mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: contracts/libs/SafeBEP20.sol

pragma solidity >= 0.6.0 < 0.8.0;

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

            function safeTransfer(
                IBEP20 token,
                address to,
                uint256 value
            ) internal {
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(token.transfer.selector, to, value)
            );
        }

    function safeTransferFrom(
        IBEP20 token,
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
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
        value
    );
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
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
        value,
        "SafeBEP20: decreased allowance below zero"
    );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
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

        bytes memory returndata = address(token).functionCall(
        data,
        "SafeBEP20: low-level call failed"
    );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeBEP20: BEP20 operation did not succeed"
            );
        }
    }
}



pragma solidity >= 0.6.0 < 0.8.0;

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

    constructor() internal {
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


// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^ 0.6.0;

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
    function _msgSender() internal view virtual returns(address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns(bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity ^ 0.6.0;

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

    event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns(address) {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/libs/BEP20.sol

// SPDX-License-Identifier: MIT

pragma solidity >= 0.4.0;

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
    function getOwner() external view override returns(address) {
        return owner();
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view override returns(string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view override returns(string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     */
    function decimals() public view override returns(uint8) {
        return _decimals;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() public view override returns(uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account) public view override returns(uint256) {
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
    function transfer(address recipient, uint256 amount)
    public
    override
    returns(bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(address owner, address spender)
    public
    view
    override
    returns(uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
    public
    override
    returns(bool)
    {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns(bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "BEP20: transfer amount exceeds allowance"
            )
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
    function increaseAllowance(address spender, uint256 addedValue)
    public
    returns(bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    returns(bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "BEP20: decreased allowance below zero"
            )
        );
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
    function mint(uint256 amount) public onlyOwner returns(bool) {
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(
            amount,
            "BEP20: transfer amount exceeds balance"
        );
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
        require(account != address(0), "BEP20: mint to the zero address");

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
        require(account != address(0), "BEP20: burn from the zero address");

        _balances[account] = _balances[account].sub(
            amount,
            "BEP20: burn amount exceeds balance"
        );
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

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
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(
                amount,
                "BEP20: burn amount exceeds allowance"
            )
        );
    }
}

abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(
            _initializing || !_initialized,
            "Initializable: contract is already initialized"
        );

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer { }

    function _msgSender() internal view virtual returns(address) {
        return msg.sender;
    }

    function _msgData() internal pure virtual returns(bytes calldata) {
        return msg.data;
    }

    uint256[50] private __gap;
}

abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address public _owner;

    event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns(address) {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

    uint256[49] private __gap;
}

contract DefiQ is Initializable, OwnableUpgradeable {
    event regLevelEvent(
    address indexed _user,
    address indexed _referrer,
    uint256 _time
);
    event buyLevelEvent(address indexed _user, uint256 _level, uint256 _time);
    using SafeBEP20 for IBEP20;
    mapping(uint256 => uint256) public LEVEL_PRICE;
    uint256 REFERRER_1_LEVEL_LIMIT;
    uint256 public royalityAmount;
    uint256 public globalroyalityAmountA;

    address[] public royalparticipants;
    address[] public globalparticipants1;

    address[] public joinedAddress;
    address[] public planBRefAmount;
    uint256 public JoinAmount;
    IBEP20 public BusdAddress;
    IBEP20 public DefiQToken;
    uint256 public tokenbusdprice;
    mapping(address => uint256) public totalearnedAmount;
    mapping(address => uint256) public totalearnedToken;
    mapping(address => uint256) public upgradematrixIncome;
    mapping(address => uint256) public generationIncome;

    struct UserStruct {
        bool isExist;
        uint256 id;
        uint256 referrerID;
        uint256 currentLevel;
        uint256 earnedAmount;
        uint256 lockedTokenAmount;
        uint256 royalityincome;
        uint256 globalroyality1income;
        uint256 globalroyality2income;
        address[] referral;
        mapping(uint256 => uint256) levelEarningmissed;
        uint256 upgradeAmount;
        uint256 upgradePending;
        uint256 investmentDate;

    }

    struct PlanBStruct {
        bool isExist;
        uint256 id;
        uint256 referrerID;
        address[] referral;
    }

    mapping(address => UserStruct) public users;
    mapping(address => PlanBStruct) public planB;
    mapping(uint256 => address) public userList;
    mapping(uint256 => address) public planBuserList;
    mapping(uint256 => bool) public userRefComplete;
    mapping(address => bool) public manualTeamUser;
    mapping(address => bool) public manualGlobalUser;
    uint256 public currUserID;
    uint256 refCompleteDepth;
    bool public isAutodistribute;
    uint256 public lastRewardTimestamp;
    address public ownerWallet;
    uint256 public totalUsers;
    uint256 public lockdays;
    mapping(address => uint256) public referralIncome;
    bool public claimLock;


    function initialize(address _ownerAddress) public initializer {
        __Ownable_init();
        ownerWallet = _ownerAddress;
        REFERRER_1_LEVEL_LIMIT = 2;
        BusdAddress = IBEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
        DefiQToken = IBEP20(0x866E7B8F76CF2435Fde81DEA9FB4693Ba002DF8F);
        royalityAmount = 0;
        globalroyalityAmountA = 0;
        refCompleteDepth = 1;
        currUserID = 0;
        totalUsers = 1;
        JoinAmount = 50 * 1e18;
        tokenbusdprice = 1000000; // 1 busd = 1000 token  // token 1 = $0.001
        lockdays = 547 days;
        claimLock = false;

        LEVEL_PRICE[1] = 20 * 1e18; // 0.1
        LEVEL_PRICE[2] = LEVEL_PRICE[1] * 2;
        LEVEL_PRICE[3] = LEVEL_PRICE[2] * 2;
        LEVEL_PRICE[4] = LEVEL_PRICE[3] * 2;
        LEVEL_PRICE[5] = LEVEL_PRICE[4] * 2;
        LEVEL_PRICE[6] = LEVEL_PRICE[5] * 2;
        LEVEL_PRICE[7] = LEVEL_PRICE[6] * 2;
        LEVEL_PRICE[8] = LEVEL_PRICE[7] * 2;
        LEVEL_PRICE[9] = LEVEL_PRICE[8] * 2;
        LEVEL_PRICE[10] = LEVEL_PRICE[9] * 2;

        UserStruct memory userStruct;
        PlanBStruct memory planBStruct;
        currUserID = 1000000;
        lastRewardTimestamp = block.timestamp;

        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: 0,
            currentLevel: 10,
            earnedAmount: 0,
            lockedTokenAmount: 0,
            referral: new address[](0),
            royalityincome: 0,
            globalroyality1income: 0,
            globalroyality2income: 0,
            upgradeAmount:0,
            upgradePending : 0,
            investmentDate : block.timestamp
        });

        planBStruct = PlanBStruct({
            isExist: true,
            referrerID: 0,
            id: currUserID,
            referral: new address[](0)
        });
        users[ownerWallet] = userStruct;
        users[ownerWallet].levelEarningmissed[1] = 0;
        users[ownerWallet].levelEarningmissed[2] = 0;
        users[ownerWallet].levelEarningmissed[3] = 0;
        users[ownerWallet].levelEarningmissed[4] = 0;
        users[ownerWallet].levelEarningmissed[5] = 0;
        users[ownerWallet].levelEarningmissed[6] = 0;
        users[ownerWallet].levelEarningmissed[7] = 0;
        users[ownerWallet].levelEarningmissed[8] = 0;
        users[ownerWallet].levelEarningmissed[9] = 0;
        users[ownerWallet].levelEarningmissed[10] = 0;
        planB[ownerWallet] = planBStruct;
        userList[currUserID] = ownerWallet;
        planBuserList[currUserID] = ownerWallet;
        globalparticipants1.push(ownerWallet);
        isAutodistribute = false;
        royalparticipants.push(ownerWallet);
        globalparticipants1.push(ownerWallet);
    }

    function random(uint256 number) public view returns(uint256) {
        return
        uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.difficulty,
                    msg.sender
                )
            )
        ) % number;
    }

    function regUser(address _referrer,uint256 _amount) public  {
        require(!users[msg.sender].isExist, "User exist");
        uint256 _referrerID;
        if (users[_referrer].isExist) {
            _referrerID = users[_referrer].id;
        } else if (_referrer == address(0)) {
            _referrerID = findFirstFreeReferrer();
            refCompleteDepth = _referrerID;
        } else {
            revert("Incorrect referrer");
        }

        require(
            _amount == JoinAmount,
            "Incorrect Value"
        );

        if (
            users[userList[_referrerID]].referral.length >=
            REFERRER_1_LEVEL_LIMIT
        ) {
            _referrerID = users[findFreeReferrer(userList[_referrerID])].id;
        }

        BusdAddress.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 tokenAmount = (_amount * tokenbusdprice)/1000;

        UserStruct memory userStruct;

        currUserID = random(1000000);

        if(users[userList[currUserID]].isExist){
          currUserID = random(10000000);
        }

        totalUsers++;

        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: _referrerID,
            earnedAmount: 0,
            lockedTokenAmount: 0,
            referral: new address[](0),
            currentLevel: 1,
            globalroyality1income: 0,
            globalroyality2income: 0,
            royalityincome: 0,
            upgradeAmount :0,
            upgradePending : 0,
            investmentDate : block.timestamp
        });


        users[msg.sender] = userStruct;
        users[msg.sender].levelEarningmissed[2] = 0;
        users[msg.sender].levelEarningmissed[3] = 0;
        users[msg.sender].levelEarningmissed[4] = 0;
        users[msg.sender].levelEarningmissed[5] = 0;
        users[msg.sender].levelEarningmissed[6] = 0;
        users[msg.sender].levelEarningmissed[7] = 0;
        users[msg.sender].levelEarningmissed[8] = 0;
        users[msg.sender].levelEarningmissed[9] = 0;
        users[msg.sender].levelEarningmissed[10] = 0;

        users[msg.sender].lockedTokenAmount += tokenAmount;
        userList[currUserID] = msg.sender;
        users[userList[_referrerID]].referral.push(msg.sender);

        if (users[userList[_referrerID]].referral.length == 3) {
            userRefComplete[_referrerID] = true;
        }
      //  address uplinerAddress = userList[users[msg.sender].referrerID];
      //  users[uplinerAddress].earnedAmount += LEVEL_PRICE[1]/2;
      //  users[uplinerAddress].upgradeAmount += LEVEL_PRICE[1]/2;
        activatePlanB(_referrer, msg.sender);
        joinedAddress.push(msg.sender);
        emit regLevelEvent(msg.sender, userList[_referrerID], now);
    }

    function activatePlanB(address upliner, address _user) internal {
        PlanBStruct memory planBStruct;
        planBStruct = PlanBStruct({
            isExist: true,
            referrerID: users[upliner].id,
            id: users[_user].id,
            referral: new address[](0)
        });

        planB[_user] = planBStruct;
        planBuserList[planB[_user].id] = _user;
        planB[upliner].referral.push(_user);
        //40% to direct parent
        uint256 directParentIncome = (JoinAmount * 15) / 100;

        if(users[upliner].currentLevel < 10){
          users[upliner].upgradeAmount += directParentIncome/2;
          users[upliner].earnedAmount += directParentIncome/2;
        }else{
          users[upliner].earnedAmount += directParentIncome;
        }
        referralIncome[upliner] += directParentIncome;

        //30% Level Income
        levelincome(upliner, 0);
        payForLevel(1, msg.sender);
        //5% Team Royality;
        uint256 _teamRoyalityTotal = (JoinAmount * 5) / 100;
        royalityAmount += _teamRoyalityTotal;
        globalroyalityAmountA += _teamRoyalityTotal;
    }

    function levelincome(address _parent, uint256 cnt) internal {
        if (cnt < 25 && _parent != 0x0000000000000000000000000000000000000000) {
            uint256 levelIncomePerLevel = (JoinAmount * 1) / 100;
            users[_parent].earnedAmount += levelIncomePerLevel;
            generationIncome[_parent] += levelIncomePerLevel;
            address nextParent = planBuserList[planB[_parent].referrerID];
            cnt++;
            levelincome(nextParent, cnt);
        }
    }

    function upgradeNextLevel() public {
      require(users[msg.sender].isExist, "User Not exist");
      require(users[msg.sender].upgradeAmount > 0,"Insufficient amount");
      uint256 currentLevel = users[msg.sender].currentLevel;
      uint256 nextLevel = currentLevel+1;
      if(nextLevel <= 10){
        users[msg.sender].upgradePending += users[msg.sender].upgradeAmount;
        payForLevel(nextLevel, msg.sender);
      }
    }

    function payForLevel(uint256 _level, address _user) internal {
        address referer;
        address referer1;
        address referer2;
        address referer3;
        address referer4;
        address referer5;
        address referer6;
        address referer7;
        address referer8;
        address referer9;
        if (_level == 1) {
            referer = userList[users[_user].referrerID];
        } else if (_level == 2) {
            referer1 = userList[users[_user].referrerID];
            referer = userList[users[referer1].referrerID];
        } else if (_level == 3) {
            referer1 = userList[users[_user].referrerID];
            referer2 = userList[users[referer1].referrerID];
            referer = userList[users[referer2].referrerID];
        } else if (_level == 4) {
            referer1 = userList[users[_user].referrerID];
            referer2 = userList[users[referer1].referrerID];
            referer3 = userList[users[referer2].referrerID];
            referer = userList[users[referer3].referrerID];
        }else if (_level == 5) {
            referer1 = userList[users[_user].referrerID];
            referer2 = userList[users[referer1].referrerID];
            referer3 = userList[users[referer2].referrerID];
            referer4 = userList[users[referer3].referrerID];
            referer = userList[users[referer4].referrerID];
        }else if (_level == 6) {
            referer1 = userList[users[_user].referrerID];
            referer2 = userList[users[referer1].referrerID];
            referer3 = userList[users[referer2].referrerID];
            referer4 = userList[users[referer3].referrerID];
            referer5 = userList[users[referer4].referrerID];
            referer = userList[users[referer5].referrerID];
        }else if (_level == 7) {
            referer1 = userList[users[_user].referrerID];
            referer2 = userList[users[referer1].referrerID];
            referer3 = userList[users[referer2].referrerID];
            referer4 = userList[users[referer3].referrerID];
            referer5 = userList[users[referer4].referrerID];
            referer6 = userList[users[referer5].referrerID];
            referer = userList[users[referer6].referrerID];
        }else if (_level == 8) {
            referer1 = userList[users[_user].referrerID];
            referer2 = userList[users[referer1].referrerID];
            referer3 = userList[users[referer2].referrerID];
            referer4 = userList[users[referer3].referrerID];
            referer5 = userList[users[referer4].referrerID];
            referer6 = userList[users[referer5].referrerID];
            referer7 = userList[users[referer6].referrerID];
            referer = userList[users[referer7].referrerID];
        }else if (_level == 9) {
            referer1 = userList[users[_user].referrerID];
            referer2 = userList[users[referer1].referrerID];
            referer3 = userList[users[referer2].referrerID];
             referer4 = userList[users[referer3].referrerID];
            referer5 = userList[users[referer4].referrerID];
            referer6 = userList[users[referer5].referrerID];
            referer7 = userList[users[referer6].referrerID];
            referer8 = userList[users[referer7].referrerID];
            referer = userList[users[referer8].referrerID];

        }else if (_level == 10) {
            referer1 = userList[users[_user].referrerID];
            referer2 = userList[users[referer1].referrerID];
            referer3 = userList[users[referer2].referrerID];
             referer4 = userList[users[referer3].referrerID];
            referer5 = userList[users[referer4].referrerID];
            referer6 = userList[users[referer5].referrerID];
            referer7 = userList[users[referer6].referrerID];
            referer8 = userList[users[referer7].referrerID];
            referer9 = userList[users[referer8].referrerID];
            referer = userList[users[referer9].referrerID];
        }
        autoUpgrade(referer,_level);
     }
    function autoUpgrade(address referer,uint _level) internal {
         uint256 upgradedAmount = 0;
         uint256 levelAmount = LEVEL_PRICE[_level];
        if(users[msg.sender].upgradePending >= levelAmount){
            users[msg.sender].currentLevel =  _level;
            if (_level == 3) {
               if(!manualTeamUser[msg.sender]){
                royalparticipants.push(msg.sender);
               }
            } else if (_level == 4) {
                uint256 referralCount = planB[msg.sender].referral.length;
                if(!manualGlobalUser[msg.sender] && referralCount >= 10){
                  globalparticipants1.push(msg.sender);
                }
            }
            uint256 oldupgrade = users[msg.sender].upgradePending - users[msg.sender].upgradeAmount;
            users[msg.sender].upgradeAmount = users[msg.sender].upgradePending - levelAmount;
            users[msg.sender].upgradePending = 0;
            upgradedAmount = levelAmount - oldupgrade;

        }else{
          upgradedAmount = users[msg.sender].upgradeAmount;
          users[msg.sender].upgradeAmount = 0;
        }
        // if (users[msg.sender].levelEarningmissed[_level] > 0 && users[msg.sender].currentLevel >= _level) {
        //     users[msg.sender].earnedAmount += users[msg.sender].levelEarningmissed[_level]/2;
        //     users[msg.sender].upgradeAmount += users[msg.sender].levelEarningmissed[_level]/2;
        //     upgradematrixIncome[msg.sender] += users[msg.sender].levelEarningmissed[_level];
        //     users[msg.sender].levelEarningmissed[_level] = 0;
        // }
        bool isSend = true;
        if (!users[referer].isExist) {
            isSend = false;
        }

        if (isSend) {
            if (users[referer].currentLevel >= _level) {
                if(users[referer].currentLevel < 10){
                  if(_level == 1){
                    users[referer].upgradeAmount += LEVEL_PRICE[_level];
                    upgradematrixIncome[referer] += LEVEL_PRICE[_level];
                  }else{

                    users[referer].upgradeAmount += upgradedAmount/2;
                    users[referer].earnedAmount += upgradedAmount/2;

                    upgradematrixIncome[referer] += upgradedAmount;
                  }
                }else{
                 uint256 missedAmount = (_level == 1) ? levelAmount : upgradedAmount;
                  users[referer].earnedAmount += missedAmount;
                }
            } else {
                users[referer].upgradeAmount += upgradedAmount/2;
                users[referer].earnedAmount += upgradedAmount/2;
                users[referer].levelEarningmissed[_level] += upgradedAmount;
            }
        }else{
         uint256 missedAmount = (_level == 1) ? levelAmount : upgradedAmount;
          users[ownerWallet].earnedAmount += missedAmount;
        }
    }


    function findFreeReferrer(address _user) public view returns(address) {
        if (users[_user].referral.length < REFERRER_1_LEVEL_LIMIT) {
            return _user;
        }
        address[] memory referrals = new address[](600);
        referrals[0] = users[_user].referral[0];
        referrals[1] = users[_user].referral[1];
        address freeReferrer;
        bool noFreeReferrer = true;

        for (uint256 i = 0; i < 600; i++) {
            if (users[referrals[i]].referral.length == REFERRER_1_LEVEL_LIMIT) {
                if (i < 120) {
                    referrals[(i + 1) * 2] = users[referrals[i]].referral[0];
                    referrals[(i + 1) * 2 + 1] = users[referrals[i]].referral[
                        1
                    ];
                }
            } else {
                noFreeReferrer = false;
                freeReferrer = referrals[i];
                break;
            }
        }
        if (noFreeReferrer) {
            freeReferrer = userList[findFirstFreeReferrer()];
            require(freeReferrer != address(0));
        }
        return freeReferrer;
    }

    function getmissedvalue(address _userAddress, uint256 _level)
    public
    view
    returns(uint256)
    {
        return users[_userAddress].levelEarningmissed[_level];
    }

    function findFirstFreeReferrer() public view returns(uint256) {
        for (uint256 i = refCompleteDepth; i < 500 + refCompleteDepth; i++) {
            if (!userRefComplete[i]) {
                return i;
            }
        }
    }

    function safeWithDraw(uint256 _amount, address addr)
    public
    onlyOwner
    {
        BusdAddress.safeTransfer(addr,_amount);
    }

    function safeWithDrawToken(uint256 _amount, address addr)
    public
    onlyOwner
    {
        DefiQToken.safeTransfer(addr,_amount);
    }

    function setTokenPrice(uint256 _price)
    public
    onlyOwner
    {
       tokenbusdprice = _price;
    }

    function claimRewards() public {
          require(!claimLock);
          claimLock = true;
         uint256 claimAmount = users[msg.sender].earnedAmount;
         require(users[msg.sender].isExist, "User Not exist");
        if (claimAmount > 0) {
            require(users[msg.sender].upgradeAmount == 0 || users[msg.sender].currentLevel >= 8,"Upgrade first then process claim");
            uint256 tokenFee = (claimAmount * 10) / 100;
            claimAmount = claimAmount - tokenFee;
            BusdAddress.safeTransfer(msg.sender,claimAmount);
            DefiQToken.safeTransfer(msg.sender,tokenFee);
            totalearnedAmount[msg.sender] += claimAmount;
            totalearnedToken[msg.sender] += tokenFee;
            users[msg.sender].earnedAmount = 0;
            users[msg.sender].royalityincome = 0;
            users[msg.sender].globalroyality1income = 0;
            users[msg.sender].globalroyality2income = 0;
            claimLock = false;
        }
    }

    function claimToken() public {
      require(users[msg.sender].isExist, "User Not exist");
      require(users[msg.sender].lockedTokenAmount > 0,"NO tokens Locked");
      uint256 endDate = users[msg.sender].investmentDate + lockdays;
      require(block.timestamp >= endDate,"Token still Locked.");
      DefiQToken.safeTransfer(msg.sender,users[msg.sender].lockedTokenAmount);
      users[msg.sender].lockedTokenAmount = 0;
    }

    function depositToUpgrade(uint256 _amount) public {
      require(users[msg.sender].isExist, "User Not exist");
      require(_amount > 0,"Not a valid Amount");
      require(users[msg.sender].isExist, "User Not exist");
      BusdAddress.safeTransferFrom(msg.sender, address(this), _amount);
      users[msg.sender].upgradeAmount += _amount;
    }


    function viewUserReferral(address _user)
    public
    view
    returns(address[] memory)
    {
        return users[_user].referral;
    }

    function joinedLength() public view returns(uint256) {
        return joinedAddress.length;
    }

    function viewplanBUserReferral(address _user)
    public
    view
    returns(address[] memory)
    {
        return planB[_user].referral;
    }

    function distributeToRoyal(uint256 _loopcnt, address[] memory _addresses, uint256[] memory _ramount, uint256[] memory _g1amount)
      onlyOwner public
    {
        lastRewardTimestamp = block.timestamp;
        for (uint256 i = 0; i < _loopcnt; i++) {
            users[_addresses[i]].royalityincome += _ramount[i];
            if (_g1amount[i] > 0) {
                users[_addresses[i]].globalroyality1income += _g1amount[i];
            }
            users[_addresses[i]].earnedAmount += (_ramount[i]/2) + (_g1amount[i]/2);
            users[_addresses[i]].upgradeAmount += (_ramount[i]/2) + (_g1amount[i]/2);
        }
        royalityAmount = 0;
        globalroyalityAmountA = 0;
    }

    function addTeamRotalParticipants(address _royal) public onlyOwner {
      royalparticipants.push(_royal);
      manualTeamUser[_royal] = true;
    }

    function addGlobalParticipants(address _address) public onlyOwner {
      globalparticipants1.push(_address);
        manualGlobalUser[_address] = true;
    }

    function updateMissedEarnings() public {
         address pass1 = 0x5F88207498000D85c64EAb3Dc9Ff64C9cD383D64;
         users[pass1].earnedAmount += users[pass1].levelEarningmissed[2] / 2;
         users[pass1].upgradeAmount += users[pass1].levelEarningmissed[2] / 2;
         users[pass1].levelEarningmissed[2] = 0;
    }


    function removeTeamRoyalAddress(address addressToRemove) public onlyOwner {
        uint index;
        for (uint i = 0; i < royalparticipants.length; i++) {
            if (royalparticipants[i] == addressToRemove) {
                index = i;
                break;
            }
        }
        for (uint i = index; i < royalparticipants.length-1; i++){
            royalparticipants[i] = royalparticipants[i+1];
        }
        royalparticipants.pop();
        manualTeamUser[addressToRemove] = false;
    }

    function removeGlobalAddress(address addressToRemove) public onlyOwner {
        uint index;
        for (uint i = 0; i < globalparticipants1.length; i++) {
            if (globalparticipants1[i] == addressToRemove) {
                index = i;
                break;
            }
        }
        for (uint i = index; i < globalparticipants1.length-1; i++){
            globalparticipants1[i] = globalparticipants1[i+1];
        }
        globalparticipants1.pop();
        manualGlobalUser[addressToRemove] = false;
    }

}