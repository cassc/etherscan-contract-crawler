/**
 *Submitted for verification at Etherscan.io on 2019-09-07
*/

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

pragma solidity ^0.4.24;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/BasicToken.sol

pragma solidity ^0.4.24;




/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.4.24;



/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol

pragma solidity ^0.4.24;




/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.4.24;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: contracts/base/MintableToken.sol

pragma solidity ^0.4.24;



/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address _to,
    uint256 _amount
  )
    public
    hasMintPermission
    canMint
    returns (bool)
  {
    return _mint(_to, _amount);
  }

   /**
   * @dev Internal Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function _mint(
    address _to,
    uint256 _amount
  ) 
    internal
    returns (bool) 
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() public onlyOwner canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

// File: openzeppelin-solidity/contracts/lifecycle/Destructible.sol

pragma solidity ^0.4.24;



/**
 * @title Destructible
 * @dev Base contract that can be destroyed by owner. All funds in contract will be sent to the owner.
 */
contract Destructible is Ownable {
  /**
   * @dev Transfers the current balance to the owner and terminates the contract.
   */
  function destroy() public onlyOwner {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) public onlyOwner {
    selfdestruct(_recipient);
  }
}

// File: openzeppelin-solidity/contracts/lifecycle/Pausable.sol

pragma solidity ^0.4.24;



/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/BurnableToken.sol

pragma solidity ^0.4.24;



/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
    // no need to require value <= totalSupply, since that would imply the
    // sender's balance is greater than the totalSupply, which *should* be an assertion failure

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/DetailedERC20.sol

pragma solidity ^0.4.24;



/**
 * @title DetailedERC20 token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

// File: openzeppelin-solidity/contracts/access/rbac/Roles.sol

pragma solidity ^0.4.24;


/**
 * @title Roles
 * @author Francisco Giordano (@frangio)
 * @dev Library for managing addresses assigned to a Role.
 * See RBAC.sol for example usage.
 */
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an address access to this role
   */
  function add(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = true;
  }

  /**
   * @dev remove an address' access to this role
   */
  function remove(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = false;
  }

  /**
   * @dev check if an address has this role
   * // reverts
   */
  function check(Role storage _role, address _addr)
    internal
    view
  {
    require(has(_role, _addr));
  }

  /**
   * @dev check if an address has this role
   * @return bool
   */
  function has(Role storage _role, address _addr)
    internal
    view
    returns (bool)
  {
    return _role.bearer[_addr];
  }
}

// File: openzeppelin-solidity/contracts/access/rbac/RBAC.sol

pragma solidity ^0.4.24;



/**
 * @title RBAC (Role-Based Access Control)
 * @author Matt Condon (@Shrugs)
 * @dev Stores and provides setters and getters for roles and addresses.
 * Supports unlimited numbers of roles and addresses.
 * See //contracts/mocks/RBACMock.sol for an example of usage.
 * This RBAC method uses strings to key roles. It may be beneficial
 * for you to write your own implementation of this interface using Enums or similar.
 */
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address indexed operator, string role);
  event RoleRemoved(address indexed operator, string role);

  /**
   * @dev reverts if addr does not have role
   * @param _operator address
   * @param _role the name of the role
   * // reverts
   */
  function checkRole(address _operator, string _role)
    public
    view
  {
    roles[_role].check(_operator);
  }

  /**
   * @dev determine if addr has role
   * @param _operator address
   * @param _role the name of the role
   * @return bool
   */
  function hasRole(address _operator, string _role)
    public
    view
    returns (bool)
  {
    return roles[_role].has(_operator);
  }

  /**
   * @dev add a role to an address
   * @param _operator address
   * @param _role the name of the role
   */
  function addRole(address _operator, string _role)
    internal
  {
    roles[_role].add(_operator);
    emit RoleAdded(_operator, _role);
  }

  /**
   * @dev remove a role from an address
   * @param _operator address
   * @param _role the name of the role
   */
  function removeRole(address _operator, string _role)
    internal
  {
    roles[_role].remove(_operator);
    emit RoleRemoved(_operator, _role);
  }

  /**
   * @dev modifier to scope access to a single role (uses msg.sender as addr)
   * @param _role the name of the role
   * // reverts
   */
  modifier onlyRole(string _role)
  {
    checkRole(msg.sender, _role);
    _;
  }

  /**
   * @dev modifier to scope access to a set of roles (uses msg.sender as addr)
   * @param _roles the names of the roles to scope access to
   * // reverts
   *
   * @TODO - when solidity supports dynamic arrays as arguments to modifiers, provide this
   *  see: https://github.com/ethereum/solidity/issues/2467
   */
  // modifier onlyRoles(string[] _roles) {
  //     bool hasAnyRole = false;
  //     for (uint8 i = 0; i < _roles.length; i++) {
  //         if (hasRole(msg.sender, _roles[i])) {
  //             hasAnyRole = true;
  //             break;
  //         }
  //     }

  //     require(hasAnyRole);

  //     _;
  // }
}

// File: openzeppelin-solidity/contracts/access/Whitelist.sol

pragma solidity ^0.4.24;




/**
 * @title Whitelist
 * @dev The Whitelist contract has a whitelist of addresses, and provides basic authorization control functions.
 * This simplifies the implementation of "user permissions".
 */
contract Whitelist is Ownable, RBAC {
  string public constant ROLE_WHITELISTED = "whitelist";

  /**
   * @dev Throws if operator is not whitelisted.
   * @param _operator address
   */
  modifier onlyIfWhitelisted(address _operator) {
    checkRole(_operator, ROLE_WHITELISTED);
    _;
  }

  /**
   * @dev add an address to the whitelist
   * @param _operator address
   * @return true if the address was added to the whitelist, false if the address was already in the whitelist
   */
  function addAddressToWhitelist(address _operator)
    public
    onlyOwner
  {
    addRole(_operator, ROLE_WHITELISTED);
  }

  /**
   * @dev getter to determine if address is in whitelist
   */
  function whitelist(address _operator)
    public
    view
    returns (bool)
  {
    return hasRole(_operator, ROLE_WHITELISTED);
  }

  /**
   * @dev add addresses to the whitelist
   * @param _operators addresses
   * @return true if at least one address was added to the whitelist,
   * false if all addresses were already in the whitelist
   */
  function addAddressesToWhitelist(address[] _operators)
    public
    onlyOwner
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      addAddressToWhitelist(_operators[i]);
    }
  }

  /**
   * @dev remove an address from the whitelist
   * @param _operator address
   * @return true if the address was removed from the whitelist,
   * false if the address wasn't in the whitelist in the first place
   */
  function removeAddressFromWhitelist(address _operator)
    public
    onlyOwner
  {
    removeRole(_operator, ROLE_WHITELISTED);
  }

  /**
   * @dev remove addresses from the whitelist
   * @param _operators addresses
   * @return true if at least one address was removed from the whitelist,
   * false if all addresses weren't in the whitelist in the first place
   */
  function removeAddressesFromWhitelist(address[] _operators)
    public
    onlyOwner
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      removeAddressFromWhitelist(_operators[i]);
    }
  }

}

// File: openzeppelin-solidity/contracts/ECRecovery.sol

pragma solidity ^0.4.24;


/**
 * @title Elliptic curve signature operations
 * @dev Based on https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
 * TODO Remove this library once solidity supports passing a signature to ecrecover.
 * See https://github.com/ethereum/solidity/issues/864
 */

library ECRecovery {

  /**
   * @dev Recover signer address from a message by using their signature
   * @param _hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
   * @param _sig bytes signature, the signature is generated using web3.eth.sign()
   */
  function recover(bytes32 _hash, bytes _sig)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

    // Check the signature length
    if (_sig.length != 65) {
      return (address(0));
    }

    // Divide the signature in r, s and v variables
    // ecrecover takes the signature parameters, and the only way to get them
    // currently is to use assembly.
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      r := mload(add(_sig, 32))
      s := mload(add(_sig, 64))
      v := byte(0, mload(add(_sig, 96)))
    }

    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }

    // If the version is correct return the signer address
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      // solium-disable-next-line arg-overflow
      return ecrecover(_hash, v, r, s);
    }
  }

  /**
   * toEthSignedMessageHash
   * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
   * and hash the result
   */
  function toEthSignedMessageHash(bytes32 _hash)
    internal
    pure
    returns (bytes32)
  {
    // 32 is the length in bytes of hash,
    // enforced by the type signature above
    return keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
    );
  }
}

// File: contracts/SilverToken.sol

pragma solidity ^0.4.24;








interface ASilverDollar {
  function purchaseWithSilverToken(address, uint256) external returns(bool);
}

contract SilverToken is Destructible, Pausable, MintableToken, BurnableToken, DetailedERC20("Silvertoken", "SLVT", 8), Whitelist {
  using SafeMath for uint256;
  using ECRecovery for bytes32;

  uint256 public transferFee = 10;//1%
  uint256 public transferDiscountFee = 8;//0.8%
  uint256 public redemptionFee = 40;//4%
  uint256 public convertFee = 10;//1%
  address public feeReturnAddress = 0xE34f13B2dadC938f44eCbC38A8dBe94B8bdB2109;
  uint256 public transferFreeAmount;
  uint256 public transferDiscountAmount;
  address public silverDollarAddress;
  address public SLVTReserve = 0x900122447a2Eaeb1655C99A91E20f506D509711B;
  bool    public canPurchase = true;
  bool    public canConvert = true;

  // Internal features

  uint256 internal multiplier;
  uint256 internal percentage = 1000;

  //ce4385affa8ad2cbec45b1660c6f6afcb691bf0a7a73ebda096ee1dfb670fe6f
  event TokenRedeemed(address from, uint256 amount);
  //3ceffd410054fdaed44f598ff5c1fb450658778e2241892da4aa646979dee617
  event TokenPurchased(address addr, uint256 amount, uint256 tokens);
  //5a56a31cc0c9ebf5d0626c5189b951fe367d953afc1824a8bb82bf168713cc52
  event FeeApplied(string name, address addr, uint256 amount);
  event Converted(address indexed sender, uint256 amountSLVT, uint256 amountSLVD, uint256 amountFee);

  modifier purchasable() {
    require(canPurchase == true, "can't purchase");
    _;
  }

  modifier onlySilverDollar() {
    require(msg.sender == silverDollarAddress, "not silverDollar");
    _;
  }
  
  modifier isConvertible() {
    require(canConvert == true, "SLVT conversion disabled");
    _;
  }


  constructor () public {
    multiplier = 10 ** uint256(decimals);
    transferFreeAmount = 2 * multiplier;
    transferDiscountAmount = 500 * multiplier;
    owner = msg.sender;
    super.mint(msg.sender, 1 * 1000 * 1000 * multiplier);
  }

  // Settings begin

  function setTransferFreeAmount(uint256 value) public onlyOwner      { transferFreeAmount = value; }
  function setTransferDiscountAmount(uint256 value) public onlyOwner  { transferDiscountAmount = value; }
  function setRedemptionFee(uint256 value) public onlyOwner           { redemptionFee = value; }
  function setFeeReturnAddress(address value) public onlyOwner        { feeReturnAddress = value; }
  function setCanPurchase(bool value) public onlyOwner                { canPurchase = value; }
  function setSilverDollarAddress(address value) public onlyOwner     { silverDollarAddress = value; }
  function setCanConvert(bool value) public onlyOwner                 { canConvert = value; }
  function setConvertFee(uint256 value) public onlyOwner              { convertFee = value; }


  function increaseTotalSupply(uint256 value) public onlyOwner returns (uint256) {
    super.mint(owner, value);
    return totalSupply_;
  }

  // Settings end

  // ERC20 re-implementation methods begin

  function transfer(address to, uint256 amount) public whenNotPaused returns (bool) {
    uint256 feesPaid = payFees(address(0), to, amount);
    require(super.transfer(to, amount.sub(feesPaid)), "failed transfer");

    return true;
  }

  function transferFrom(address from, address to, uint256 amount) public whenNotPaused returns (bool) {
    uint256 feesPaid = payFees(from, to, amount);
    require(super.transferFrom(from, to, amount.sub(feesPaid)), "failed transferFrom");

    return true;
  }

  // ERC20 re-implementation methods end

  // Silvertoken methods end

  function payFees(address from, address to, uint256 amount) private returns (uint256 fees) {
    if (msg.sender == owner || hasRole(from, ROLE_WHITELISTED) || hasRole(msg.sender, ROLE_WHITELISTED) || hasRole(to, ROLE_WHITELISTED))
        return 0;
    fees = getTransferFee(amount);
    if (from == address(0)) {
      require(super.transfer(feeReturnAddress, fees), "transfer fee payment failed");
    }
    else {
      require(super.transferFrom(from, feeReturnAddress, fees), "transferFrom fee payment failed");
    }
    emit FeeApplied("Transfer", to, fees);
  }

  function getTransferFee(uint256 amount) internal view returns(uint256) {
    if (transferFreeAmount > 0 && amount <= transferFreeAmount) return 0;
    if (transferDiscountAmount > 0 && amount >= transferDiscountAmount) return amount.mul(transferDiscountFee).div(percentage);
    return amount.mul(transferFee).div(percentage);
  }

  function transferTokens(address from, address to, uint256 amount) internal returns (bool) {
    require(balances[from] >= amount, "balance insufficient");

    balances[from] = balances[from].sub(amount);
    balances[to] = balances[to].add(amount);

    emit Transfer(from, to, amount);

    return true;
  }

  function purchase(uint256 tokens, uint256 fee, uint256 timestamp, bytes signature) public payable purchasable whenNotPaused {
    require(
      isSignatureValid(
        msg.sender, msg.value, tokens, fee, timestamp, signature
      ),
      "invalid signature"
    );
    require(tokens > 0, "invalid number of tokens");
    
    emit TokenPurchased(msg.sender, msg.value, tokens);
    transferTokens(owner, msg.sender, tokens);

    feeReturnAddress.transfer(msg.value);
    if (fee > 0) {
      emit FeeApplied("Purchase", msg.sender, fee);
    }       
  }

  function purchasedSilverDollar(uint256 amount) public onlySilverDollar purchasable whenNotPaused returns (bool) {
    require(super._mint(SLVTReserve, amount), "minting of slvT failed");
    
    return true;
  }

  function purchaseWithSilverDollar(address to, uint256 amount) public onlySilverDollar purchasable whenNotPaused returns (bool) {
    require(transferTokens(SLVTReserve, to, amount), "failed transfer of slvT from reserve");

    return true;
  }

  function redeem(uint256 tokens) public whenNotPaused {
    require(tokens > 0, "amount of tokens redeemed must be > 0");

    uint256 fee = tokens.mul(redemptionFee).div(percentage);

    _burn(msg.sender, tokens.sub(fee));
    if (fee > 0) {
      require(super.transfer(feeReturnAddress, fee), "token transfer failed");
      emit FeeApplied("Redeem", msg.sender, fee);
    }
    emit TokenRedeemed(msg.sender, tokens);
  }

  function isSignatureValid(
    address sender, uint256 amount, uint256 tokens, 
    uint256 fee, uint256 timestamp, bytes signature
  ) public view returns (bool) 
  {
    if (block.timestamp > timestamp + 10 minutes) return false;
    bytes32 hash = keccak256(
      abi.encodePacked(
        address(this),
        sender, 
        amount, 
        tokens,
        fee,
        timestamp
      )
    );
    return hash.toEthSignedMessageHash().recover(signature) == owner;
  }

  function isConvertSignatureValid(
    address sender, uint256 amountSLVT, uint256 amountSLVD, 
    uint256 timestamp, bytes signature
  ) public view returns (bool) 
  {
    if (block.timestamp > timestamp + 10 minutes) return false;
    bytes32 hash = keccak256(
      abi.encodePacked(
        address(this),
        sender, 
        amountSLVT, 
        amountSLVD,
        timestamp
      )
    );
    return hash.toEthSignedMessageHash().recover(signature) == owner;
  }

  function convertToSLVD(
    uint256 amountSLVT, uint256 amountSLVD,
    uint256 timestamp, bytes signature
  ) public isConvertible whenNotPaused returns (bool) {
    require(
      isConvertSignatureValid(
        msg.sender, amountSLVT, 
        amountSLVD, timestamp, signature
      ), 
      "convert failed, invalid signature"
    );

    uint256 fees = amountSLVT.mul(convertFee).div(percentage);
    if (whitelist(msg.sender) && Whitelist(silverDollarAddress).whitelist(msg.sender))
      fees = 0;

    super.transfer(SLVTReserve, amountSLVT.sub(fees));
    require(super.transfer(feeReturnAddress, fees), "transfer fee payment failed");
    require(
      ASilverDollar(silverDollarAddress).purchaseWithSilverToken(msg.sender, amountSLVD), 
      "failed purchase of silverdollar with silvertoken"
    );
    
    emit Converted(msg.sender, amountSLVD, amountSLVD, fees);
    return true;
  }
}

// File: contracts/SilverDollar.sol

pragma solidity ^0.4.24;


contract SilverDollar is ASilverDollar, Destructible, Pausable, MintableToken, BurnableToken, DetailedERC20("SilverDollar", "SLVD", 8), Whitelist {
  using SafeMath for uint256;
  using ECRecovery for bytes32;

  SilverToken private silverToken;
  uint256 public transferFee = 45;//0.45%
  address public transferFeesReceiver = 0xEDC9B5b0a8EB9CAC0132d47B6cbACdFa6595b3F7;
  uint256 public multiplier;
  bool public canPurchase = true;
  bool public canConvert = true;

  event TokenPurchased(address indexed addr, uint256 amount, uint256 tokens);
  event TokenConverted(address indexed addr, uint256 slvd, uint slvt);
  event FeePaid(address indexed addr, uint256 amount);

  modifier isPurchasable() {
    require(canPurchase == true, "purchase disabled");
    _;
  }

  modifier isConvertible() {
    require(canConvert == true, "conversion disabled");
    _;
  }

  modifier onlySilverToken() {
    require(msg.sender == address(silverToken), "not silverToken");
    _;
  }

  function setCanPurchase(bool value) public onlyOwner  { canPurchase = value; }
  function setCanConvert(bool value) public onlyOwner   { canConvert = value; }

  constructor (SilverToken _silverToken) public {
    silverToken = _silverToken;
    multiplier = 10 ** uint256(decimals);
  }

  function purchase(uint256 slvdAmount, uint256 slvtAmount, uint256 timestamp, bytes signature) public payable isPurchasable whenNotPaused {
    require(
      isSignatureValidBuy(
        msg.sender, msg.value, slvdAmount, slvtAmount, timestamp, signature
      ),
      "invalid signature"
    );
    require(_mint(msg.sender, slvdAmount), "Minting failed");
    silverToken.purchasedSilverDollar(slvtAmount);
    silverToken.feeReturnAddress().transfer(msg.value);
    emit TokenPurchased(msg.sender, msg.value, slvdAmount);
  }

  function purchaseWithSilverToken(address to, uint256 amount) public onlySilverToken isPurchasable whenNotPaused returns (bool) {
    require(_mint(to, amount), "failed minting of new silverDollar");

    return true;
  }


  function transfer(address to, uint256 amount) public whenNotPaused returns (bool) {
    uint256 fees = payFees(address(0), to, amount);
    require(super.transfer(to, amount.sub(fees)), "transfer Failed");

    return true;
  }

  function transferFrom(address from, address to, uint256 amount) public whenNotPaused returns (bool) {
    uint256 fees = payFees(from, to, amount);
    require(super.transferFrom(from, to, amount.sub(fees)), "transferFrom failed");

    return true;
  }

  function convertToSLVT(
    uint256 amount, uint256 amountSlvt, uint256 timestamp, bytes signature
  ) public isConvertible whenNotPaused returns (bool) 
  {
    require(
      isSignatureValidConvert(
        msg.sender, amount, amountSlvt, timestamp, signature
      ),
      "invalid signature"
    );
    burn(amount);
    require(silverToken.purchaseWithSilverDollar(msg.sender, amountSlvt), "purchased failed");
    emit TokenConverted(msg.sender, amount, amountSlvt);

    return true;
  }

  function payFees(address from, address to, uint256 amount) private returns (uint256 fees) {
    if (hasRole(from, ROLE_WHITELISTED) || hasRole(msg.sender, ROLE_WHITELISTED) || hasRole(to, ROLE_WHITELISTED))
      return 0;
    fees = amount.mul(transferFee).div(10000);//45 / 10000 = 0.0045 = 0.45%
    if (from == 0x0) {
      require(super.transfer(transferFeesReceiver, fees), "transfer fees Failed");
    }
    else {
      require(super.transferFrom(from, transferFeesReceiver, fees), "transferFrom fees Failed");
    }
    emit FeePaid(transferFeesReceiver, fees);
  }

  function isSignatureValidBuy(
    address sender, uint256 amount, uint256 slvdAmount, 
    uint256 slvtAmount, uint256 timestamp, bytes signature
  ) public view returns (bool) 
  {
    if (block.timestamp > timestamp + 10 minutes) return false;
    bytes32 hash = keccak256(
      abi.encodePacked(
        address(this),
        sender, 
        amount, 
        slvdAmount,
        slvtAmount,
        timestamp
      )
    );
    return hash.toEthSignedMessageHash().recover(signature) == owner;
  }

  function isSignatureValidConvert(
    address sender, uint256 slvdAmount, 
    uint256 slvtAmount, uint256 timestamp, bytes signature
  ) public view returns (bool) 
  {
    if (block.timestamp > timestamp + 10 minutes) return false;
    bytes32 hash = keccak256(
      abi.encodePacked(
        address(this),
        sender,  
        slvdAmount,
        slvtAmount,
        timestamp
      )
    );
    return hash.toEthSignedMessageHash().recover(signature) == owner;
  }
}