/**
 *Submitted for verification at Etherscan.io on 2019-08-14
*/

pragma solidity ^ 0.4.4;

/*
This is the smart contract for the ERC 20 standard Tratok token.
During the development of the smart contract, active attention was paid to make the contract as simple as possible.
As the majority of functions are simple addition and subtraction of existing balances, we have been able to make the contract very lightweight.
This has the added advantage of reducing gas costs and ensuring that transaction fees remain low.
The smart contract has been made publically available, keeping with the team's philosophy of transparency.
This is an update on the second generation smart contract which can be found at 0x0cbc9b02b8628ae08688b5cc8134dc09e36c443b.
The contract has been updated to match a change in project philosophy and enhance distribution and widespread adoption of the token via free airdrops.
Further enhancements have been made for this third-generation:
A.) Enhanced anti-fraud measures.
B.) A Contingency plan to ensure that in the event of an exchange being compromised, that there is a facility to prevent the damage hurting the Tratok ecosystem.
C.) More efficient gas usage (e.g. Use of External instead of public).


@version "1.2"
@developer "Tratok Team"
@date "25 June 2019"
@thoughts "307 lines that will change the travel and tourism industry! Good luck!"
*/

/*
 * Use of the SafeMath Library prevents malicious input. For security consideration, the
 * smart contract makes use of .add() and .sub() rather than += and -=
 */

library SafeMath {
    
//Ensures that b is greater than a to handle negatives.
    function sub(uint256 a, uint256 b) internal returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    //Ensure that the sum of two values is greater than the initial value.
    function add(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

/*
 * ERC20 Standard will be used
 * see https://github.com/ethereum/EIPs/issues/20
 */

contract ERC20 {
    //the total supply of tokens 
    uint public totalSupply;

    //@return Returns the total amount of Tratok tokens in existence. The amount remains capped at the pre-created 100 Billion.  
    function totalSupply() constant returns(uint256 supply){}

    /* 
      @param _owner The address of the wallet which needs to be queried for the amount of Tratok held. 
      @return Returns the balance of Tratok tokens for the relevant address.
      */
    function balanceOf(address who) constant returns(uint);

    /* 
       The transfer function which takes the address of the recipient and the amount of Tratok needed to be sent and complete the transfer
       @param _to The address of the recipient (usually a "service provider") who will receive the Tratok.
       @param _value The amount of Tratok that needs to be transferred.
       @return Returns a boolean value to verify the transaction has succeeded or failed.
      */
    function transfer(address to, uint value) returns(bool ok);

    /*
       This function will, conditional of being approved by the holder, send a determined amount of tokens to a specified address
       @param _from The address of the Tratok sender.
       @param _to The address of the Tratok recipient.
       @param _value The volume (amount of Tratok which will be sent).
       @return Returns a boolean value to verify the transaction has succeeded or failed.
      */
    function transferFrom(address from, address to, uint value) returns(bool ok);

    /*
      This function approves the transaction and costs
      @param _spender The address of the account which is able to transfer the tokens
      @param _value The amount of wei to be approved for transfer
      @return Whether the approval was successful or not
     */
    function approve(address spender, uint value) returns(bool ok);

    /*
    This function determines how many Tratok remain and how many can be spent.
     @param _owner The address of the account owning the Tratok tokens
     @param _spender The address of the account which is authorized to spend the Tratok tokens
     @return Amount of Tratok tokens which remain available and therefore, which can be spent
    */
    function allowance(address owner, address spender) constant returns(uint);


    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

}

/*
 *This is a basic contract held by one owner and prevents function execution if attempts to run are made by anyone other than the owner of the contract
 */

contract Ownable {
    address public owner;

    function Ownable() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
    
    function owner() public view returns (address) {
        return owner;
    }

}


contract StandardToken is ERC20, Ownable {

event FrozenAccount(address indexed _target);
event UnfrozenAccount(address indexed _target);    

using SafeMath for uint256;
    function transfer(address _to, uint256 _value) returns(bool success) {
        require(!frozenAccounts[msg.sender]);
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns(bool success) {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] = balances[_to].add(_value);
            balances[_from] = balances[_from].sub(_value);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }
     
    function balanceOf(address _owner) constant returns(uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns(bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns(uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    
     /*
This function determines distributes tratok to multiple addresses and is designed for the airdrop.
     @param _destinations The address of the accounts which will be sent Tratok tokens.
     @param _values The amount of the Tratok tokens to be sent.
     @return The number of loop cycles
     */        
    
    function airDropTratok(address[] _destinations, uint256[] _values) external onlyOwner
    returns (uint256) {
        uint256 i = 0;
        while (i < _destinations.length) {
           transfer(_destinations[i], _values[i]);
           i += 1;
        }
        return(i);
    }

    /*
This function determines distributes tratok to multiple addresses and is designed for the ecosystem. It is the same as the airDropTratok method but differs in that it can be run by all accounts, not just the Owner account.

     @param _destinations The address of the accounts which will be sent Tratok tokens.
     @param _values The amount of the Tratok tokens to be sent.
     @return The number of loop cycles
     */        
    
    function distributeTratok(address[] _destinations, uint256[] _values)
    returns (uint256) {
        uint256 i = 0;
        while (i < _destinations.length) {
           transfer(_destinations[i], _values[i]);
           i += 1;
        }
        return(i);
    }
    
       /*
This function locks the account  from sending Tratok. This measure is taken to prevent fraud and to recover Tratok in the event that an exchange is hacked.
     @param _target The address of the accounts which will be locked.
     @return The number of loop cycles
     */    
     
   function lockAccountFromSendingTratok(address _target) external onlyOwner returns(bool){
   
   	//Ensure that the target address is not left blank to prevent errors.
   	  require(_target != address(0));
	//ensure the account is not already frozen.	  
      require(!frozenAccounts[_target]);
      frozenAccounts[_target] = true;
      emit FrozenAccount(_target);
      return true;
  }
    
    /*
This function unlocks accounts tratok to allow them to send Tratok.
     @param _target The address of the accounts which will be sent Tratok tokens.
     @return The number of loop cycles
     */    
      function unlockAccountFromSendingTratok(address _target) external onlyOwner returns(bool){
      require(_target != address(0));
      require(frozenAccounts[_target]);
      delete frozenAccounts[_target];
      emit UnfrozenAccount(_target);
      return true;
  }
     
    /*
This function is an emergency failsafe that allows Tratok to be reclaimed in the event of an exchange or partner hack. This contingency is meant as a last resort to protect the integrity of the ecosystem in the event of a security breach. It can only be executed by the holder of the custodian keys.
     @param _from The address of the Tratok tokens will be seized.
	 @param _to The address where the Tratok tokens will be sent.
     @param _value The amount of Tratok tokens that will be transferred.
     */    
       
     function confiscate(address _from, address _to, uint256 _value) external onlyOwner{
     	balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        return (Transfer(_from, _to, _value));
}     
    

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    mapping(address => bool) internal frozenAccounts;
    
    uint256 public totalSupply;
}

contract Tratok is StandardToken {

    function() {
        revert();
        
    }

    /* 
     * The public variables of the token. Including the name, the symbol and the number of decimals.
     */
    string public name;
    uint8 public decimals;
    string public symbol;
    string public version = 'H1.0';

    /*
     * Declaring the customized details of the token. The token will be called Tratok, with a total supply of 100 billion tokens.
     * It will feature five decimal places and have the symbol TRAT.
     */

    function Tratok() {

        //we will create 100 Billion utility tokens and send them to the creating wallet.
        balances[msg.sender] = 10000000000000000;
        totalSupply = 10000000000000000;
        name = "Tratok";
        decimals = 5;
        symbol = "TRAT";
    }

    /*
     *Approve and enact the contract.
     *
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns(bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        //If the call fails, result to "vanilla" approval.
        if (!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) {
            revert();
        }
        return true;
    }
}