/**
 *Submitted for verification at Etherscan.io on 2020-12-08
*/

pragma solidity ^0.5.0;

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
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
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
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


pragma solidity ^0.5.0;

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


pragma solidity ^0.5.0;

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

// File: contracts\roles\MinterRole.sol

pragma solidity 0.5.17;


contract MinterRole
{
  using Roles for Roles.Role;

  Roles.Role private _minters;

  event MinterAdded(address indexed account);
  event MinterRemoved(address indexed account);


  modifier onlyMinter()
  {
    require(isMinter(msg.sender), "!minter");
    _;
  }

  constructor () internal
  {
    _minters.add(msg.sender);
    emit MinterAdded(msg.sender);
  }

  function isMinter(address account) public view returns (bool)
  {
    return _minters.has(account);
  }

  function addMinter(address account) public onlyMinter
  {
    _minters.add(account);
    emit MinterAdded(account);
  }

  function renounceMinter() public
  {
    _minters.remove(msg.sender);
    emit MinterRemoved(msg.sender);
  }
}


pragma solidity 0.5.17;


contract Token is IERC20, MinterRole
{
  using SafeMath for uint;

  string public name;
  string public symbol;
  uint8 public decimals;
  uint public totalSupply;

  mapping(address => uint) public balanceOf;
  mapping(address => mapping(address => uint)) public allowance;


  constructor (string memory _name, string memory _symbol, uint8 _decimals) public
  {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;

    _mint(msg.sender, 450000 * 1e18);
    _mint(0xb5b93f7396af7e85353d9C4d900Ccbdbdac6a658, 75000 * 1e18);
  }

  function transfer(address _recipient, uint _amount) public returns (bool)
  {
    _transfer(msg.sender, _recipient, _amount);

    return true;
  }

  function transferFrom(address _sender, address _recipient, uint _amount) public returns (bool)
  {
    _transfer(_sender, _recipient, _amount);
    _approve(_sender, msg.sender, allowance[_sender][msg.sender].sub(_amount, "ERC20: tx qty > allowance"));

    return true;
  }

  function _transfer(address _sender, address _recipient, uint _amount) internal
  {
    require(_sender != address(0), "ERC20: tx from 0 addy");
    require(_recipient != address(0), "ERC20: tx to 0 addy");

    balanceOf[_sender] = balanceOf[_sender].sub(_amount, "ERC20: tx qty > balance");
    balanceOf[_recipient] = balanceOf[_recipient].add(_amount);

    emit Transfer(_sender, _recipient, _amount);
  }

  function approve(address _spender, uint _amount) public returns (bool)
  {
    _approve(msg.sender, _spender, _amount);

    return true;
  }

  function _approve(address _owner, address _spender, uint _amount) internal
  {
    require(_owner != address(0), "ERC20: approve from 0 addy");
    require(_spender != address(0), "ERC20: approve to 0 addy");

    allowance[_owner][_spender] = _amount;

    emit Approval(_owner, _spender, _amount);
  }

  function increaseAllowance(address _spender, uint _addedValue) public returns (bool)
  {
    _approve(msg.sender, _spender, allowance[msg.sender][_spender].add(_addedValue));

    return true;
  }

  function decreaseAllowance(address _spender, uint _subtractedValue) public returns (bool)
  {
    _approve(msg.sender, _spender, allowance[msg.sender][_spender].sub(_subtractedValue, "ERC20: decreased allowance < 0"));

    return true;
  }

  function mint(address _account, uint256 _amount) public onlyMinter returns (bool)
  {
    _mint(_account, _amount);
    return true;
  }

  function _mint(address _account, uint _amount) internal
  {
    require(_account != address(0), "ERC20: mint to 0 addy");

    totalSupply = totalSupply.add(_amount);
    balanceOf[_account] = balanceOf[_account].add(_amount);

    emit Transfer(address(0), _account, _amount);
  }

  function burn(uint _amount) public onlyMinter
  {
    _burn(msg.sender, _amount);
  }

  function burnFrom(address _account, uint _amount) public onlyMinter
  {
    _burn(_account, _amount);
    _approve(_account, msg.sender, allowance[_account][msg.sender].sub(_amount, "ERC20: burn qty > allowance"));
  }

  function _burn(address _account, uint _amount) internal
  {
    require(_account != address(0), "ERC20: burn from 0 addy");

    balanceOf[_account] = balanceOf[_account].sub(_amount, "ERC20: burn qty > balance");
    totalSupply = totalSupply.sub(_amount);

    emit Transfer(_account, address(0), _amount);
  }
}