/**
 *Submitted for verification at Etherscan.io on 2021-01-15
*/

pragma solidity >=0.4.22 <0.6.0;

  // ----------------------------------------------------------------------------------------------
  // UCoin Token Contract
  // UNIVERSAL COIN INTERNATIONAL INC
  // V.1.4 Fixed (FINAL)
  // ----------------------------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract Owned {
    
    address public owner;
    
    function owned() public  {
        owner = msg.sender;

    }
    constructor() payable public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData)  external; }

contract TokenERC20 is SafeMath{
    // Public variables of the token
    string public name  ;
    string public symbol  ;
    uint8 public decimals = 18;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply ;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        emit Transfer(address(0), msg.sender, totalSupply);

    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `to` from your account
     *
     * @param to The address of the recipient
     * @param tokens the amount to send
     */
  
    function transfer(address to, uint tokens) payable public returns (bool success) {
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], tokens);
        balanceOf[to] = safeAdd(balanceOf[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    
    /**
     * Transfer tokens from other address
     *
     * Send `tokens` tokens to `to` in behalf of `from`
     *
     * @param from The address of the sender
     * @param to The address of the recipient
     * @param tokens the amount to send
     */

    function transferFrom(address from, address to, uint tokens) payable public returns (bool success) {
        balanceOf[from] = safeSub(balanceOf[from], tokens);
        allowance[from][msg.sender] = safeSub(allowance[from][msg.sender], tokens);
        balanceOf[to] = safeAdd(balanceOf[to], tokens);
        emit Transfer(from, to, tokens);
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
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
 
}

contract UCoinToken is Owned, TokenERC20 {

    mapping (address => bool) public frozenAccount;

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function UCoinToken(

    ) 

    TokenERC20(5000000000, "UCoin", "UCoin") public {}

    
    /// @notice Will cause a certain `_value` of coins minted for `_to`.
    /// @param _to The address that will receive the coin.
     /// @param _value The amount of coin they will receive.
    function mint(address _to, uint _value) payable public {
        require(msg.sender == owner); // assuming you have a contract owner
        mintToken(_to, _value);
    }
 
    function mintToken(address target, uint256 mintedAmount) internal {
        //balanceOf[target] += mintedAmount;
        balanceOf[target] = safeAdd(balanceOf[target], mintedAmount);
        
    }
    
    /// @notice Will allow multiple minting within a single call to save gas.
    /// @param _to_list A list of addresses to mint for.
    /// @param _values The list of values for each respective `_to` address.
    function airdropMinting(address[] _to_list, uint[] _values) payable public  {
        require(msg.sender == owner); // assuming you have a contract owner
        require(_to_list.length == _values.length);
        for (uint i = 0; i < _to_list.length; i++) {
            mintToken(_to_list[i], _values[i]);
        }
    }

    function  freezeAccount(address target, bool freeze) payable public {
        require(msg.sender == owner); // assuming you have a contract owner
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) payable public  returns (bool success) {
        require(msg.sender == owner); // assuming you have a contract owner
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value);  // Subtract from the sender
        totalSupply = safeSub(totalSupply, _value);   // Updates totalSupply
        emit Burn(msg.sender, _value); //event
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) payable public returns (bool success) {
        require(msg.sender == owner); // assuming you have a contract owner
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] = safeSub(balanceOf[_from], _value); // Subtract from the targeted balance
        allowance[_from][msg.sender] = safeSub(allowance[_from][msg.sender], _value); // Subtract from the sender's allowance  
        totalSupply = safeSub(totalSupply, _value);  // Update totalSupply
        emit Burn(_from, _value); //event
        return true;
    }

}