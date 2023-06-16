/**
 *Submitted for verification at Etherscan.io on 2021-01-06
*/

pragma solidity 0.4.26;

/* 
 * 
 * BOWHEAD HEALTH
 * ERC20 AHT Token Contract
 * Updated : 31-May-2018
 * Saravana Malaichami 
 *
 */ 


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}



/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}




/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

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


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
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
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


 /* 
 * AHT Token Contract
 * 
 */ 

contract AHTToken is StandardToken {

    string  public constant name    = "BOWHEAD TOKEN";
    string  public constant symbol  = "AHT";
    uint256 public constant decimals= 18;   


   /* 
   * team classification flag
   * for defining the lock period 
   */ 

    uint constant tokensLock   = 1;   
    uint constant tokensNoLock = 2;
    uint public lockUntil      = 1535846399;   // 01-Sep-2018 23:59:59 GMT  
   

    // flag for emergency stop or start 
    bool public halted = false;              
    
    uint  public tokensICOPublic     =    32183484198 * (10 ** uint256(decimals-4));      // ( 3,218,348.4198 ) 
    uint  public tokensReserve       =   367816515802 * (10 ** uint256(decimals-4));      // ( 36,781,651.5802 )
    uint  public tokensAPData        =   40000000 * (10 ** uint256(decimals));      // ( 40M )
    uint  public tokensNodes         =    5000000 * (10 ** uint256(decimals));      // ( 5M )
    uint  public tokensDoctors       =    5000000 * (10 ** uint256(decimals));      // ( 5M ) 
    uint  public tokensLabs          =    5000000 * (10 ** uint256(decimals));      // ( 5M )
    uint  public tokensManagment     =    5000000 * (10 ** uint256(decimals));      // ( 5M )

    /*  
    *  Addresses  
    */

    address public addressICOManager   = 0xF03dB6434F2c5273bc315d645D914F394f7886CD;   
    address public addressReserve      = 0x2c7C0aAA99a4C4155E134a70200ED50DDB4f517b;  
    address public addressAPData       = 0xA13b2a723d74Ea5e1FE1B8E8ECd7AB4d4967281e;  
    address public addressNodes        = 0x707a4ABe2b7b872964A759EB2dd22d427a93264a;  
    address public addressDoctors      = 0xbc0f73321f9D010e753b5CbD7213F2C4C3B5BD6b;  
    address public addressLabs         = 0xe1A992b1fB0920267E20393517fA7c7d935A0C0a;     
    address public addressManagment    = 0x88FC1B7944496D6C3d96A7d7570e2061c873FE75;


    /*
    * Contract Constructor
    */

     constructor() public {
            
                     totalSupply_ = 100000000 * (10 ** uint256(decimals));    // 100M;                 

                     balances[addressICOManager] = tokensICOPublic;
                     balances[addressReserve] = tokensReserve;
                     balances[addressAPData] = tokensAPData;
                     balances[addressNodes] = tokensNodes;
                     balances[addressDoctors] = tokensDoctors;
                     balances[addressLabs] = tokensLabs;
                     balances[addressManagment] = tokensManagment;
                     
                     emit Transfer(this, addressICOManager, tokensICOPublic);
                     emit Transfer(this, addressReserve, tokensReserve);
                     emit Transfer(this, addressAPData, tokensAPData);
                     emit Transfer(this, addressNodes, tokensNodes);
                     emit Transfer(this, addressDoctors, tokensDoctors);
                     emit Transfer(this, addressLabs, tokensLabs);
                     emit Transfer(this, addressManagment, tokensManagment);
                 
    }
    

 /*
  *   Emergency Stop or Start ICO.
  */

  function  halt() onlyManager public{
       require(msg.sender == addressICOManager);
       halted = true;
  }

  function  unhalt() onlyManager public {
      require(msg.sender == addressICOManager);
      halted = false;
  }

  modifier onlyManager() {
      require(msg.sender == addressICOManager);
      _;
  }

 /*
  *   Transfer functions
  */

  function transfer(address _to, uint256 _value) public returns (bool success) 
  {
         if ( msg.sender == addressICOManager) { return super.transfer(_to, _value); }           
           // Reserve, AP Data, Nodes, Doctors, Labs and Management - Lock until 30-Sep-18
         if ( !halted &&  identifyAddress(msg.sender)  == tokensLock &&  now > lockUntil)  { return super.transfer(_to, _value); }         
          // Investors can transfer 
         if ( !halted && identifyAddress(msg.sender) == tokensNoLock ) { return super.transfer(_to, _value); }

        return false;       
  }


  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) 
  {
         if ( msg.sender == addressICOManager) { return super.transferFrom(_from,_to, _value); }           
           // Reserve, AP Data, Nodes, Doctors, Labs and Management - Lock until 30-Sep-18
         if ( !halted &&  identifyAddress(msg.sender)  == tokensLock &&  now > lockUntil)  { return super.transferFrom(_from,_to, _value); }
          // Investors can transfer 
         if ( !halted && identifyAddress(msg.sender) == tokensNoLock ) { return super.transferFrom(_from,_to, _value); }
      
        return false;        
  }

  /*
   *  Identify addresses that are in Lock category      
   */

   function identifyAddress(address _buyer) constant public returns(uint) {
      if (_buyer == addressReserve || _buyer == addressAPData || _buyer == addressNodes )  return tokensLock;
      if (_buyer == addressDoctors || _buyer == addressLabs || _buyer == addressManagment) return tokensLock;
              return tokensNoLock;
    }

   /*
    *  default fall back function      
    */
    function () payable public {
            revert();
    }
}