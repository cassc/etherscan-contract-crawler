/**
 *Submitted for verification at Etherscan.io on 2019-12-16
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
  //address public txsender;
  
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The constructor sets the original `owner` of the contract to the sender
   * account.
   */
    constructor() public
    {
       owner = msg.sender;
     //  txsender = tx.origin;
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

contract StandardToken is Token {

    address public note_contract;
    
    function transfer(address _to, uint256 _value) returns (bool success) {
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
 * @title Mintable token
 * @dev ERC20 mintable token creation
 */
contract StockMintToken is StandardToken, Ownable {
  event StockMint(address indexed to, uint256 amount);
  event Burn(address indexed burner, uint256 value);
  event MintFinished();
  using SafeMath for uint256;
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
   * @dev Function STORAGE stock-in and mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function stockmint(
    address _to,
    uint256 _amount
  )
    public
    hasMintPermission
    canMint
    returns (bool)
  {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit StockMint(_to, _amount);
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
  
  /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) 
    public 
    {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(burner, _value);
    }
}

/**
 * @title Repayment token
 * @dev ERC20  with Repay Tokens
 */
contract RepaymentToken is StandardToken, Ownable {
  event Repayment(address indexed _debit_contract, uint256 amount);
  using SafeMath for uint256;
  
  modifier hasRepaymentPermission() {
    require(msg.sender == note_contract);
    _;
  }
  
  /**
   * @dev Function to repayment tokens
   * @param _amount The amount of tokens to repay.
   * @return A boolean that indicates if the operation was successful.
   */

  function repayment(
    uint256 _amount
  )
    public
    hasRepaymentPermission
    returns (bool)
  {
    totalSupply = totalSupply.add(_amount);
    balances[owner] = balances[owner].add(_amount);
    emit Repayment(msg.sender, _amount);
    emit Paidto(owner, _amount);
    return true;
  }

  event Paidto(address indexed _to_creditor, uint256 _value);
    
}

/**
 * @title Creditable Token
 * @dev Token that can be credit.
 */
contract CreditableToken is StandardToken, Ownable {
    using SafeMath for uint256;
    event Credit(address indexed _debit_contract, uint256 value);

    function credit(uint256 _value) 
    public
    {
        require(_value > 0);
        require(_value <= balances[owner]);
        require(msg.sender == note_contract);
        // no need to require value <= totalSupply, since that would imply the
        // sender's balance is greater than the totalSupply, which *should* be an assertion failure

        //address _creditor = owner;
        balances[owner] = balances[owner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Credit(msg.sender, _value);
        emit Drawdown(owner, _value);
    }
    
    event Drawdown(address indexed _from_creditor, uint256 _value);
}


contract yuyourencoin is CreditableToken, RepaymentToken, StockMintToken {

    constructor() public {
        totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
    }

    function connectContract(address _note_address ) public onlyOwner {
        note_contract = _note_address;
    }
    
    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name = "yuyourencoin";
    string public symbol = "yuyr";
    uint public constant decimals = 0;
    uint256 public constant INITIAL_SUPPLY = 360 * (10 ** uint256(decimals));
    string public Image_root = "https://swarm.chainbacon.com/bzz:/838dcd59f0095e1b40dd6d4934e852d11fbe5faad1cdf6b5700ae1dcd4e1ba69/";
    string public Note_root = "https://swarm.chainbacon.com/bzz:/38b685e9b26348120b6bb887c2906714dbfac79f48472e87347b63399b089f21/";
    string public Document_root = "https://swarm.chainbacon.com/bzz:/431a4d00af6b1421ffcb95764bcd82c55a6443099f4c17344de573ed52af2ba8/";
    string public DigestCode_root = "3d17d4134a44ceca7dec3230cc9b7d972d30ba231cb2c74793208633bbd67f78";
    function getIssuer() public pure returns(string) { return  "Stark"; }
    function getTrustee() public pure returns(string) { return  "Private_warehousing"; }
    string public TxHash_root = "genesis";

    string public ContractSource = "";
    string public CodeVersion = "v0.1";
    
    string public SecretKey_Pre = "";
    string public Name_New = "";
    string public TxHash_Pre = "";
    string public DigestCode_New = "";
    string public Image_New = "";
    string public Note_New = "";
    string public Document_New = "";
    uint256 public CreditRate = 100 * (10 ** uint256(decimals));

    function getName() public view returns(string) { return name; }
    function getDigestCodeRoot() public view returns(string) { return DigestCode_root; }
    function getTxHashRoot() public view returns(string) { return TxHash_root; }
    function getImageRoot() public view returns(string) { return Image_root; }
    function getNoteRoot() public view returns(string) { return Note_root; }
    function getDocumentRoot() public view returns(string) { return Document_root; }
    function getCodeVersion() public view returns(string) { return CodeVersion; }
    function getContractSource() public view returns(string) { return ContractSource; }

    function getSecretKeyPre() public view returns(string) { return SecretKey_Pre; }
    function getNameNew() public view returns(string) { return Name_New; }
    function getTxHashPre() public view returns(string) { return TxHash_Pre; }
    function getDigestCodeNew() public view returns(string) { return DigestCode_New; }
    function getImageNew() public view returns(string) { return Image_New; }
    function getNoteNew() public view returns(string) { return Note_New; }
    function getDocumentNew() public view returns(string) { return Document_New; }
    function updateCreditRate(uint256 _rate) public onlyOwner returns (uint256) {
        CreditRate = _rate;
        return CreditRate;
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