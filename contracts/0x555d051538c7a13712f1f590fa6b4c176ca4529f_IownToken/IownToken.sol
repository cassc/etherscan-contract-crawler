/**
 *Submitted for verification at Etherscan.io on 2019-10-06
*/

// ERC20/ERC223 Token for iOWN

// File: contracts/math/SafeMath.sol

pragma solidity ^0.5.11;

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
     * - Subtraction cannot overflow.
     *
     * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
     * @dev Get it via `npm install @openzeppelin/[email protected]`.
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
     * - The divisor cannot be zero.

     * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
     * @dev Get it via `npm install @openzeppelin/[email protected]`.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
     * @dev Get it via `npm install @openzeppelin/[email protected]`.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.11;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

// File: contracts/token/ERC223/IERC223.sol

pragma solidity ^0.5.11;

/**
 * @dev Extension interface for IERC20 which defines logic specific to ERC223
 */
interface IERC223 {

	/**
	 * Events are actually ERC20 compatible, since etherscan/exhcanges don't support the newer event
	 */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
	 * Events are actually ERC20 compatible, since etherscan/exhcanges don't support the newer event
	 */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function approve(address spender, uint256 amount, bytes calldata data) external returns (bool);

    function transfer(address to, uint value, bytes calldata data) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount, bytes calldata data) external returns (bool);

}

// File: contracts/token/ERC223/ERC223Detailed.sol

pragma solidity ^0.5.11;



/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC223Detailed is IERC20, IERC223 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

// File: contracts/GSN/Context.sol

pragma solidity ^0.5.11;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts/utils/Address.sol

pragma solidity ^0.5.11;

/**
 * @dev Collection of functions related to the address type
 * Orginally https://github.com/Dexaran/ERC223-token-standard/blob/development/utils/Address.sol
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
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
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
}

// File: contracts/token/ERC223/IERC223Extras.sol

pragma solidity ^0.5.11;

/**
 * @dev Extension interface for IERC223 which idenfies agent like behaviour
 */
interface IERC223Extras {
    function transferFor(address beneficiary, address recipient, uint256 amount, bytes calldata data) external returns (bool);

    function approveFor(address beneficiary, address spender, uint256 amount, bytes calldata data) external returns (bool);
}

// File: contracts/token/ERC223/IERC223Recipient.sol

pragma solidity ^0.5.11;

 /**
 * @title Contract that will work with ERC223 tokens.
 * Originally https://github.com/Dexaran/ERC223-token-standard/blob/development/token/ERC223/IERC223Recipient.sol
 */
interface IERC223Recipient {
    /**
    * @dev Standard ERC223 function that will handle incoming token transfers.
    *
    * @param _from  Token sender address.
    * @param _value Amount of tokens.
    * @param _data  Transaction metadata.
    */
    function tokenFallback(address _from, uint _value, bytes calldata _data) external;
}

// File: contracts/token/ERC223/IERC223ExtendedRecipient.sol

pragma solidity ^0.5.11;

 /**
 * @title Contract that will work with ERC223 tokens which have extended fallback methods triggered on approve,
 * transferFor and approveFor (which are non standard logic)
 */
interface IERC223ExtendedRecipient {
    /**
    * @dev Extra ERC223 like function that will handle incoming approvals.
    *
    * @param _from  Token sender address.
    * @param _value Amount of tokens.
    * @param _data  Transaction metadata.
    */
    function approveFallback(address _from, uint _value, bytes calldata _data) external;

    /**
    * @dev ERC223 like function that will handle incoming token transfers for someone else
    *
    * @param _from  Token sender address.
    * @param _beneficiary Token beneficiary.
    * @param _value Amount of tokens.
    * @param _data  Transaction metadata.
    */
    function tokenForFallback(address _from, address _beneficiary, uint _value, bytes calldata _data) external;

    /**
    * @dev Extra ERC223 like function that will handle incoming approvals.
    *
    * @param _from  Token sender address.
    * @param _beneficiary Token beneficiary.
    * @param _value Amount of tokens.
    * @param _data  Transaction metadata.
    */
    function approveForFallback(address _from, address _beneficiary, uint _value, bytes calldata _data) external;
}

// File: contracts/token/ERC223/ERC223.sol

pragma solidity ^0.5.11;








/**
 * @dev Implementation of the {IERC223} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC223-approve}.
 */
contract ERC223 is Context, IERC20, IERC223, IERC223Extras {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC223-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC223-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC223-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        bytes memory _empty = hex"00000000";
        _transfer(_msgSender(), recipient, amount, _empty);
        return true;
    }

    /**
     * @dev See {IERC223-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC223-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC2223-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC223};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     *
     * Has non-standard implementation: approval and transfer trigger fallback on special conditions
     */
    function transferFrom(address sender, address recipient, uint256 amount, bytes memory data) public returns (bool) {
        _transfer(sender, recipient, amount, data); //has fallback if recipient isn't msg.sender
         //has fallback if not msg sender:
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC223: transfer amount exceeds allowance"), data);
        return true;
    }

    /**
     * @dev See {IERC223-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC223};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     *
     * Has standard implementation where no approveFallback is triggered
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        bytes memory _empty = hex"00000000";
        _transfer(sender, recipient, amount, _empty); //Has standard ERC223 fallback
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC223: transfer amount exceeds allowance")); //no fallback
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC223-approve}.
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
     * problems described in {IERC223-approve}.
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Transfer the specified amount of tokens to the specified address.
     *      Invokes the `tokenFallback` function if the recipient is a contract.
     *      The token transfer fails if the recipient is a contract
     *      but does not implement the `tokenFallback` function
     *      or the fallback function to receive funds.
     *
     * @param recipient    Receiver address.
     * @param amount Amount of tokens that will be transferred.
     * @param data Transaction metadata.
     */
    function transfer(address recipient, uint256 amount, bytes memory data) public returns (bool success){
        _transfer(_msgSender(), recipient, amount, data);
        return true;
    }

    /**
     * @dev See {IERC223-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount, bytes memory data) public returns (bool) {
        _approve(_msgSender(), spender, amount, data);
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
    function _transfer(address sender, address recipient, uint256 amount, bytes memory data) internal {
        require(sender != address(0), "ERC223: transfer from the zero address");
        require(recipient != address(0), "ERC223: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC223: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        //ERC223 logic:
        // No fallback if there's a transfer initiated by a contract to itself (transferFrom)
        if(Address.isContract(recipient) && _msgSender() != recipient) {
            IERC223Recipient receiver = IERC223Recipient(recipient);
            receiver.tokenFallback(sender, amount, data);
        }
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
        require(account != address(0), "ERC223: mint to the zero address");

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
        require(account != address(0), "ERC223: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC223: burn amount exceeds balance");
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
     *
     * This Function is non-standard to ERC223, and been modified to reflect same behaviour as _transfer with regards to fallback
     */
    function _approve(address owner, address spender, uint256 amount, bytes memory data) internal {
        require(owner != address(0), "ERC223: approve from the zero address");
        require(spender != address(0), "ERC223: approve to the zero address");

        _allowances[owner][spender] = amount;
        // ERC223 Extra logic:
        // No fallback when msg.sender is triggering this transaction (transferFrom) which it is also receiving
        if(Address.isContract(spender) && _msgSender() != spender) {
            IERC223ExtendedRecipient receiver = IERC223ExtendedRecipient(spender);
            receiver.approveFallback(owner, amount, data);
        }
        emit Approval(owner, spender, amount);
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
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC223: approve from the zero address");
        require(spender != address(0), "ERC223: approve to the zero address");
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
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC223: burn amount exceeds allowance"));
    }

    /**
     * @dev Special extended functionality: Allows transferring tokens to a contract for the benefit of someone else
     * Non-standard to ERC20 or ERC223
     */
    function transferFor(address beneficiary, address recipient, uint256 amount, bytes memory data) public returns (bool) {
        address sender = _msgSender();
        require(beneficiary != address(0), "ERC223E: transfer for the zero address");
        require(recipient != address(0), "ERC223: transfer to the zero address");
        require(beneficiary != sender, "ERC223: sender and beneficiary cannot be the same");

        _balances[sender] = _balances[sender].sub(amount, "ERC223: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        //ERC223 Extra logic:
        if(Address.isContract(recipient) && _msgSender() != recipient) {
            IERC223ExtendedRecipient receiver = IERC223ExtendedRecipient(recipient);
            receiver.tokenForFallback(sender, beneficiary, amount, data);
        }
        emit Transfer(sender, recipient, amount);
        return true;
    }

    /**
     * @dev  Special extended functionality: Allows approving tokens to a contract but for the benefit of someone else,
     * transferFrom logic that follows doesn't change, but the spender here can track that the amount is deduced from someone for
     * the benefit of someone else, thus allowing refunds to original sender, while giving service/utility being paid for to beneficiary
     */
    function approveFor(address beneficiary, address spender, uint256 amount, bytes memory data) public returns (bool) {
        address agent = _msgSender();
        require(agent != address(0), "ERC223: approve from the zero address");
        require(spender != address(0), "ERC223: approve to the zero address");
        require(beneficiary != agent, "ERC223: sender and beneficiary cannot be the same");

        _allowances[agent][spender] = amount;
        //ERC223 Extra logic:
        if(Address.isContract(spender) && _msgSender() != spender) {
            IERC223ExtendedRecipient receiver = IERC223ExtendedRecipient(spender);
            receiver.approveForFallback(agent, beneficiary, amount, data);
        }
        emit Approval(agent, spender, amount);
        return true;
    }
}

// File: contracts/access/Roles.sol

pragma solidity ^0.5.11;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

// File: contracts/access/roles/PauserRole.sol

pragma solidity ^0.5.11;

contract PauserRole is Context {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(_msgSender());
    }

    modifier onlyPauser() {
        require(isPauser(_msgSender()), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(_msgSender());
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

// File: contracts/lifecycle/Pausable.sol

pragma solidity ^0.5.11;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context, PauserRole {
    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state. Assigns the Pauser role
     * to the deployer.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: contracts/token/ERC223/ERC223Pausable.sol

pragma solidity ^0.5.11;

/**
 * @title Pausable token
 * @dev ERC223 an extension of ERC20Pausable which applies to ERC223 functions
 *
 */
contract ERC223Pausable is ERC223, Pausable {
    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint256 addedValue) public whenNotPaused returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public whenNotPaused returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
    }

    /**
     * ERC223
     */
    function transfer(address recipient, uint256 amount, bytes memory data) public whenNotPaused returns (bool success) {
        return super.transfer(recipient, amount, data);
    }

	/**
     * ERC223
     */
    function approve(address spender, uint256 amount, bytes memory data) public whenNotPaused returns (bool) {
        return super.approve(spender, amount, data);
    }

    /**
     * ERC223Extra
     */
    function transferFor(address beneficiary, address recipient, uint256 amount, bytes memory data) public whenNotPaused returns (bool) {
        return super.transferFor(beneficiary, recipient, amount, data);
    }

    /**
     * ERC223Extra
     */
    function approveFor(address beneficiary, address spender, uint256 amount, bytes memory data) public whenNotPaused returns (bool) {
        return super.approveFor(beneficiary, spender, amount, data);
    }
}

// File: contracts/ownership/Ownable.sol

pragma solidity ^0.5.11;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
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
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/access/roles/MinterRole.sol

pragma solidity ^0.5.11;

/**
 * @dev MinterRole inherites from openzeppelin.
 */
contract MinterRole is Context {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(_msgSender());
    }

    modifier onlyMinter() {
        require(isMinter(_msgSender()), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(_msgSender());
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

// File: contracts/token/ERC223/ERC223Mintable.sol

pragma solidity ^0.5.11;

/**
 * @dev Extension of {ERC20} that adds a set of accounts with the {MinterRole},
 * which have permission to mint (create) new tokens as they see fit.
 *
 * At construction, the deployer of the contract is the only minter.
 */
contract ERC223Mintable is ERC223, MinterRole {
    /**
     * @dev See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the {MinterRole}.
     */
    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }
}

// File: contracts/token/ERC223/ERC223Capped.sol

pragma solidity ^0.5.11;

/**
 * @dev Extension of {ERC223Mintable} that adds a cap to the supply of tokens.
 */
contract ERC223Capped is ERC223Mintable {
    uint256 private _cap;

    /**
     * @dev Sets the value of the `cap`. This value is immutable, it can only be
     * set once during construction.
     */
    constructor (uint256 cap) public {
        require(cap > 0, "ERC223Capped: cap is 0");
        _cap = cap;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view returns (uint256) {
        return _cap;
    }

    /**
     * @dev See {ERC223Mintable-mint}.
     *
     * Requirements:
     *
     * - `value` must not cause the total supply to go over the cap.
     */
    function _mint(address account, uint256 value) internal {
        require(totalSupply().add(value) <= _cap, "ERC223Capped: cap exceeded");
        super._mint(account, value);
    }
}

// File: contracts/token/ERC223/ERC223Burnable.sol

pragma solidity ^0.5.11;

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
contract ERC223Burnable is Context, ERC223 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev See {ERC20-_burnFrom}.
     */
    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }
}

// File: contracts/token/ERC223/ERC223UpgradeAgent.sol

pragma solidity ^0.5.11;

/**
 * @dev Upgrade agent interface inspired by Lunyr.
 *
 * Upgrade agent transfers tokens to a new contract.
 * Upgrade agent itself can be the token contract, or just a middle man contract doing the heavy lifting.
 * Originally https://github.com/TokenMarketNet/smart-contracts/blob/master/contracts/UpgradeAgent.sol
 */
contract ERC223UpgradeAgent {

	/** Original supply of token*/
    uint public originalSupply;

    /** Interface marker */
    function isUpgradeAgent() public pure returns (bool) {
        return true;
    }

    /**
     * @dev Upgrade a set of tokens
     */
    function upgradeFrom(address from, uint256 value) public;

}

// File: contracts/token/ERC223/ERC223Upgradeable.sol

pragma solidity ^0.5.11;

/**
 * @dev A capped burnable token which can be upgraded to a newer version of its self.
 */
contract ERC223Upgradeable is ERC223Capped, ERC223Burnable, Ownable {

	/** The next contract where the tokens will be migrated. */
    address private _upgradeAgent;

    /** How many tokens we have upgraded by now. */
    uint256 private _totalUpgraded = 0;

    /** Set to true if we have an upgrade agent and we're ready to update tokens */
    bool private _upgradeReady = false;

    /** Somebody has upgraded some of his tokens. */
    event Upgrade(address indexed _from, address indexed _to, uint256 _amount);

    /** New upgrade agent available. */
    event UpgradeAgentSet(address agent);

    /** New token information was set */
    event InformationUpdate(string name, string symbol);

    /**
    * @dev Modifier to check if upgrading is allowed
    */
    modifier upgradeAllowed() {
        require(_upgradeReady == true, "Upgrade not allowed");
        _;
    }

    /**
     * @dev Modifier to check if setting upgrade agent is allowed for owner
     */
    modifier upgradeAgentAllowed() {
        require(_totalUpgraded == 0, "Upgrade is already in progress");
        _;
    }

    /**
     * @dev Returns the upgrade agent
     */
    function upgradeAgent() public view returns (address) {
        return _upgradeAgent;
    }

    /**
     * @dev Allow the token holder to upgrade some of their tokens to a new contract.
     * @param amount An amount to upgrade to the next contract
     */
    function upgrade(uint256 amount) public upgradeAllowed {
        require(amount > 0, "Amount should be greater than zero");
        require(balanceOf(msg.sender) >= amount, "Amount exceeds tokens owned");
        //Burn user's tokens:
        burn(amount);
        _totalUpgraded = _totalUpgraded.add(amount);
        // Upgrade agent reissues the tokens in the new contract
        ERC223UpgradeAgent(_upgradeAgent).upgradeFrom(msg.sender, amount);
        emit Upgrade(msg.sender, _upgradeAgent, amount);
    }

    /**
     * @dev Set an upgrade agent that handles transition of tokens from this contract
     * @param agent Sets the address of the ERC223UpgradeAgent (new token)
     */
    function setUpgradeAgent(address agent) external onlyOwner upgradeAgentAllowed {
        require(agent != address(0), "Upgrade agent can not be at address 0");
        ERC223UpgradeAgent target = ERC223UpgradeAgent(agent);
        // Basic validation for target contract
        require(target.isUpgradeAgent() == true, "Address provided is an invalid agent");
        require(target.originalSupply() == cap(), "Upgrade agent should have the same cap");
        _upgradeAgent = agent;
        _upgradeReady = true;
        emit UpgradeAgentSet(agent);
    }

}

// File: contracts/iown/OdrToken.sol

pragma solidity ^0.5.11;

/**
 * @title Odr
 * @dev ODR (On Demand Release) is a contract which holds tokens to be released for special purposes only,
 *  from a token perspective, the ODR is an adress which receives all remainder of token cap
 */
contract OdrToken is ERC223Upgradeable {

 	/** Holds the ODR address: where remainder of hard cap goes*/
    address private _odrAddress;

    /** The date before which release must be triggered or token MUST be upgraded. */
    uint private _releaseDate;

    /** Token release switch. */
    bool private _released = false;

    constructor(uint releaseDate) public {
        _releaseDate = releaseDate;
    }

    /**
     * @dev Modifier for checked whether the token has not been released yet
     */
    modifier whenNotReleased() {
        require(_released == false, "Not allowed after token release");
        _;
    }

    /**
     * @dev Releases the token by marking it as released after minting all tokens to ODR
     */
    function releaseToken() external onlyOwner returns (bool isSuccess) {
        require(_odrAddress != address(0), "ODR Address must be set before releasing token");
        uint256 remainder = cap().sub(totalSupply());
        if(remainder > 0) mint(_odrAddress, remainder); //Mint remainder of tokens to ODR wallet
        _released = true;
        return _released;
    }

    /**
     * @dev Allows Owner to set the ODR address which will hold the remainder of the tokens on release
     * @param odrAddress The address of the ODR wallet
     */
    function setODR(address odrAddress) external onlyOwner returns (bool isSuccess) {
        require(odrAddress != address(0), "Invalid ODR address");
        require(Address.isContract(odrAddress), "ODR address must be a contract");
        _odrAddress = odrAddress;
        return true;
    }

    /**
     * @dev Is token released yet
     * @return true if released
     */
    function released() public view returns (bool) {
        return _released;
    }

    /**
     * @dev Getter for ODR address
     * @return address of ODR
     */
    function odr() public view returns (address) {
        return _odrAddress;
    }
}

// File: contracts/iown/IownToken.sol

pragma solidity ^0.5.11;

/**
 * @title IownToken
 * @dev iOWN Token is an ERC223 Token for iOWN Project, intended to allow users to access iOWN Services
 */
contract IownToken is OdrToken, ERC223Pausable, ERC223Detailed {
    using SafeMath for uint256;

    constructor(
        string memory name,
        string memory symbol,
        uint totalSupply,
        uint8 decimals,
        uint releaseDate,
        address managingWallet
    )
        Context()
        ERC223Detailed(name, symbol, decimals)
        Ownable()
        PauserRole()
        Pausable()
        MinterRole()
        ERC223Capped(totalSupply)
        OdrToken(releaseDate)
        public
    {
        transferOwnership(managingWallet);
    }

    /**
     * @dev Function to transfer ownership of contract to another address
     * Guarantees newOwner has also minter and pauser roles
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid new owner address");
        address oldOwner = owner();
        _addMinter(newOwner);
        _addPauser(newOwner);
        super.transferOwnership(newOwner);
        if(oldOwner != address(0)) {
            _removeMinter(oldOwner);
            _removePauser(oldOwner);
        }
    }
}