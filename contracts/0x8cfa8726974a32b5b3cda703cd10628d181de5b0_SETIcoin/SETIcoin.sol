/**
 *Submitted for verification at Etherscan.io on 2019-12-03
*/

pragma solidity 0.5.11; /*

  ___________________________________________________________________
    _      _                                        ______
    |  |  /          /                                /
  --|-/|-/-----__---/----__----__---_--_----__-------/-------__------
    |/ |/    /___) /   /   ' /   ) / /  ) /___)     /      /   )
  __/__|____(___ _/___(___ _(___/_/_/__/_(___ _____/______(___/__o_o_



  ███████╗███████╗████████╗██╗     ██████╗ ██████╗ ██╗███╗   ██╗
  ██╔════╝██╔════╝╚══██╔══╝██║    ██╔════╝██╔═══██╗██║████╗  ██║
  ███████╗█████╗     ██║   ██║    ██║     ██║   ██║██║██╔██╗ ██║
  ╚════██║██╔══╝     ██║   ██║    ██║     ██║   ██║██║██║╚██╗██║
  ███████║███████╗   ██║   ██║    ╚██████╗╚██████╔╝██║██║ ╚████║
  ╚══════╝╚══════╝   ╚═╝   ╚═╝     ╚═════╝ ╚═════╝ ╚═╝╚═╝  ╚═══╝



----------------------------------------------------------------------------
 'SETI' Token contract with following features
    => ERC20 Compliance
    => Higher degree of control by owner - safeguard functionality
    => SafeMath implementation
    => Burnable
    => air drop

 Name        : South East Trading Investment
 Symbol      : SETI
 Total supply: 600,000,000 (600 Million)
 Decimals    : 18


------------------------------------------------------------------------------------
 Copyright (c) 2019 onwards South East Trading Investment. ( http://seti.network )
-----------------------------------------------------------------------------------
*/


//*******************************************************************//
//------------------------ SafeMath Library -------------------------//
//*******************************************************************//
/* Safemath library */
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
    require(b <= a, "SafeMath: subtraction overflow");
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
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
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
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}

//*******************************************************************//
//------------------ Contract to Manage Ownership -------------------//
//*******************************************************************//

// Owner Handler
contract owned {
  address payable public owner;

    constructor () public {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner, 'not the owner');
    _;
  }

  function transferOwnership(address payable newOwner) public onlyOwner {
    owner = newOwner;
  }
}

//*****************************************************************//
//------------------ SETI Coin main code starts -------------------//
//*****************************************************************//

contract SETIcoin is owned {
  // Public variables of the token
  using SafeMath for uint256;
  string public name = "South East Trading Investment";
  string public symbol = "SETI";
  uint256 public decimals = 18; // 18 decimals is the strongly suggested default, avoid changing it
  uint256 public totalSupply = 600000000 * (10 ** decimals) ; // 600 Million with 18 decimal points
  bool public safeguard; // putting safeguard on will halt all non-owner functions


  // This creates an array with all balances
  mapping (address => uint256) public balanceOf;
  mapping (address => mapping (address => uint256)) public allowance;
  mapping (address => bool) public frozenAccount;


  /* This generates a public event on the blockchain that will notify clients */
  event FrozenAccounts(address target, bool frozen);

  // This generates a public event on the blockchain that will notify clients
  event Transfer(address indexed from, address indexed to, uint256 value);

  // This notifies clients about the amount burnt
  event Burn(address indexed from, uint256 value);

  // Approval
  event Approval(address indexed tokenOwner, address indexed spender, uint256 indexed tokenAmount);


  /**
    * Constrctor function
    *
    * Initializes contract with initial supply tokens to the creator of the contract
    */
  constructor () public {

    //sending all the tokens to Owner
    balanceOf[owner] = totalSupply;

    emit Transfer(address(0), msg.sender, totalSupply);

  }

  /**
    * Internal transfer, only can be called by this contract
    */
  function _transfer(address _from, address _to, uint _value) internal {
    require(!safeguard, 'safeguard is active');
    // Prevent transfer to 0x0 address. Use burn() instead
    require(_to != address(0x0), 'zero address');

    uint previousBalances = balanceOf[_from].add(balanceOf[_to]);
    balanceOf[_from] = balanceOf[_from].sub(_value);
    balanceOf[_to] = balanceOf[_to].add(_value);

    assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);

    emit Transfer(_from, _to, _value);
  }

  /**
    * Transfer tokens
    *
    * Send `_value` tokens to `_to` from your account
    *
    * @param _to The address of the recipient
    * @param _value the amount to send
    */
  function transfer(address _to, uint256 _value) public returns (bool success) {
    _transfer(msg.sender, _to, _value);
    return true;
  }

  /**
    * Transfer tokens from other address
    *
    * Send `_value` tokens to `_to` in behalf of `_from`
    *
    * @param _from The address of the sender
    * @param _to The address of the recipient
    * @param _value the amount to send
    */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
    _transfer(_from, _to, _value);
    return true;
  }

  /**
    * Set allowance for other address
    *
    * Allows `_spender` to spend no more than `_value` tokens in your behalf
    *
    * @param _spender The address authorized to spend
    * @param _value the max amount they can spend
    */
  function approve(address _spender, uint256 _value) public returns (bool success) {
    require(!safeguard, 'safeguard is active');
    allowance[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }


  /**
    * Destroy tokens
    *
    * Remove `_value` tokens from the system irreversibly
    *
    * @param _value the amount of money to burn
    */
  function burn(uint256 _value) public returns (bool success) {
    require(!safeguard, 'safeguard is active');
    balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
    totalSupply = totalSupply.sub(_value);
    emit Burn(msg.sender, _value);
    emit Transfer(msg.sender, address(0), _value);
    return true;
  }


  /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
  /// @param target Address to be frozen
  /// @param freeze either to freeze it or not
  function freezeAccount(address target, bool freeze) public onlyOwner {
    frozenAccount[target] = freeze;
    emit FrozenAccounts(target, freeze);
  }



  // Just in rare case, owner wants to transfer Ether from contract to owner address
  function manualWithdrawEther() public onlyOwner {
    address(owner).transfer(address(this).balance);
  }

  function manualWithdrawTokens(uint256 tokenAmount) public onlyOwner {
    // no need for overflow checking as that will be done in transfer function
    _transfer(address(this), owner, tokenAmount);
  }



  /**
    * Change safeguard status on or off
    *
    * When safeguard is true, then all the non-owner functions will stop working.
    * When safeguard is false, then all the functions will resume working back again!
    */
  function changeSafeguardStatus() public onlyOwner {
    if (safeguard == false) {
      safeguard = true;
    }
    else {
      safeguard = false;
    }
  }

  /********************************/
  /*    Code for the Air drop     */
  /********************************/

  /**
    * Run an Air-Drop
    *
    * It requires an array of all the addresses and amount of tokens to distribute
    * It will only process first 150 recipients. That limit is fixed to prevent gas limit
    */
  function airdrop(address[] memory recipients, uint[] memory tokenAmount) public onlyOwner {
    uint256 addressCount = recipients.length;
    require(addressCount <= 150, 'address count over 150');
    for(uint i = 0; i < addressCount; i++) {
      // This will loop through all the recipients and send them the specified tokens
      _transfer(address(this), recipients[i], tokenAmount[i]);
    }
  }
}