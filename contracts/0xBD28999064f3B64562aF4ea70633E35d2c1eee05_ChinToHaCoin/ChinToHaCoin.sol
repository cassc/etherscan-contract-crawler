/**
 *Submitted for verification at Etherscan.io on 2020-02-17
*/

pragma solidity ^0.4.25;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The constructor sets the original `owner` of the contract to the sender
   * account.
   */
    constructor() public
    {
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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract Token {

    /// @return total amount of tokens
    function totalSupply() constant returns (uint256 supply) {}

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance) {}

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success) {}

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success) {}

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event setNewBlockEvent(string SecretKey_Pre, string Name_New, string TxHash_Pre, string DigestCode_New, string Image_New, string Note_New);
}

contract COLLATERAL  {
    
    function decimals() pure returns (uint) {}
    function CreditRate()  pure returns (uint256) {}
    function credit(uint256 _value) public {}
    function repayment(uint256 _amount) public returns (bool) {}
}

contract StandardToken is Token {

    COLLATERAL dc;
    address public collateral_contract;
    uint public constant decimals = 0;

 function transfer(address _to, uint256 _value) returns(bool success) {
        //Default assumes totalSupply can't be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn't wrap.
        //Replace the if with this one instead.
        //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}


/**
 * @title Debitable token
 * @dev ERC20 Token, with debitable token creation
 */
contract DebitableToken is StandardToken, Ownable {
  event Debit(address collateral_contract, uint256 amount);
  event Deposit(address indexed _to_debitor, uint256 _value);  
  event DebitFinished();

  using SafeMath for uint256;
  bool public debitingFinished = false;

  modifier canDebit() {
    require(!debitingFinished);
    _;
  }

  modifier hasDebitPermission() {
    require(msg.sender == owner);
    _;
  }
  
  /**
   * @dev Function to debit tokens
   * @param _to The address that will receive the drawdown tokens.
   * @param _amount The amount of tokens to debit.
   * @return A boolean that indicates if the operation was successful.
   */
  function debit(
    address _to,
    uint256 _amount
  )
    public
    hasDebitPermission
    canDebit
    returns (bool)
  {
    dc = COLLATERAL(collateral_contract);
    uint256 rate = dc.CreditRate();
    uint256 deci = 10 ** decimals; 
    uint256 _amount_1 =  _amount / deci / rate;
    uint256 _amount_2 =  _amount_1 * deci * rate;
    
    require( _amount_1 > 0);
    dc.credit( _amount_1 );  
    
    uint256 _amountx = _amount_2;
    totalSupply = totalSupply.add(_amountx);
    balances[_to] = balances[_to].add(_amountx);
    emit Debit(collateral_contract, _amountx);
    emit Deposit( _to, _amountx);
    return true;
  }

  /**
   * @dev To stop debiting tokens.
   * @return True if the operation was successful.
   */
  function finishDebit() public onlyOwner canDebit returns (bool) {
    debitingFinished = true;
    emit DebitFinished();
    return true;
  }

  
}



/**
 * @title Repaymentable Token
 * @dev Debitor that can be repay to creditor.
 */
contract RepaymentToken is StandardToken, Ownable {
    using SafeMath for uint256;
    event Repayment(address collateral_contract, uint256 value);
    event Withdraw(address debitor, uint256 value);
    
    modifier hasRepayPermission() {
      require(msg.sender == owner);
      _;
    }

    function repayment( uint256 _value )
    hasRepayPermission
    public 
    {
        require(_value > 0);
        require(_value <= balances[msg.sender]);

        dc = COLLATERAL(collateral_contract);
        address debitor = msg.sender;
        uint256 rate = dc.CreditRate();
        uint256 deci = 10 ** decimals; 
        uint256 _unitx = _value / deci / rate;
        uint256 _value1 = _unitx * deci * rate;
        balances[debitor] = balances[debitor].sub(_value1);
        totalSupply = totalSupply.sub(_value1);

        require(_unitx > 0);
        dc.repayment( _unitx );
    
        emit Repayment( collateral_contract, _value1 );
        emit Withdraw( debitor, _value1 );
    }
    
}


contract ChinToHaCoin is DebitableToken, RepaymentToken  {


    constructor() public {    
        totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
    }
    
    function connectContract(address _collateral_address ) public onlyOwner {
        collateral_contract = _collateral_address;
    }
    
    function getCreditRate() public view returns (uint256 result) {
        dc = COLLATERAL( collateral_contract );
        return dc.CreditRate();
    }
    
    /* Public variables of the token */

    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    
    string public name = "ChinToHaCoin";
    string public symbol = "CTHC";
    uint256 public constant INITIAL_SUPPLY = 0 * (10 ** uint256(decimals));
    string public Image_root = "https://swarm.chainbacon.com/bzz:/3fe13660887b606b8dc90e4f232f835d51dc6b71e182fd079f22ec8f643b8853/";
    string public Note_root = "https://swarm.chainbacon.com/bzz:/73bcc5fda8642dd9b82b5e065fdb2288830bb7e8e93c404e0578bc4c896fa199/";
    string public Document_root = "https://swarm.chainbacon.com/bzz:/67ddcef52dce4cd6c0b8f39c291970572fb1d0b1f43c9d98b3d2202ca52e57fd/";
    string public DigestCode_root = "9d7f53442ec1c2874bee0091f82d046a7cfce963ca84b9c5f5c6b0b011d23ea1";
    function getIssuer() public pure returns(string) { return  "ChinToHa"; }
    string public TxHash_root = "genesis";

    string public ContractSource = "";
    string public CodeVersion = "v0.1";
    
    string public SecretKey_Pre = "";
    string public Name_New = "";
    string public TxHash_Pre = "";
    string public DigestCode_New = "";
    string public Image_New = "";
    string public Note_New = "";
    uint256 public DebitRate = 100 * (10 ** uint256(decimals));
   
    function getName() public view returns(string) { return name; }
    function getDigestCodeRoot() public view returns(string) { return DigestCode_root; }
    function getTxHashRoot() public view returns(string) { return TxHash_root; }
    function getImageRoot() public view returns(string) { return Image_root; }
    function getNoteRoot() public view returns(string) { return Note_root; }
    function getCodeVersion() public view returns(string) { return CodeVersion; }
    function getContractSource() public view returns(string) { return ContractSource; }

    function getSecretKeyPre() public view returns(string) { return SecretKey_Pre; }
    function getNameNew() public view returns(string) { return Name_New; }
    function getTxHashPre() public view returns(string) { return TxHash_Pre; }
    function getDigestCodeNew() public view returns(string) { return DigestCode_New; }
    function getImageNew() public view returns(string) { return Image_New; }
    function getNoteNew() public view returns(string) { return Note_New; }
    function updateDebitRate(uint256 _rate) public onlyOwner returns (uint256) {
        DebitRate = _rate;
        return DebitRate;
    }

    function setNewBlock(string _SecretKey_Pre, string _Name_New, string _TxHash_Pre, string _DigestCode_New, string _Image_New, string _Note_New )  returns (bool success) {
        SecretKey_Pre = _SecretKey_Pre;
        Name_New = _Name_New;
        TxHash_Pre = _TxHash_Pre;
        DigestCode_New = _DigestCode_New;
        Image_New = _Image_New;
        Note_New = _Note_New;
        emit setNewBlockEvent(SecretKey_Pre, Name_New, TxHash_Pre, DigestCode_New, Image_New, Note_New);
        return true;
    }

    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn't have to include a contract in here just for this.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        require(!_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData));
        return true;
    }
}