/**
 *Submitted for verification at Etherscan.io on 2020-12-25
*/

// File: contracts/SafeMath.sol
pragma solidity ^0.4.8;
contract SafeMath {
    function safeAdd(uint256 _x, uint256 _y) internal returns(uint256) {
      uint256 z = _x + _y;
      assert((z >= _x) && (z >= _y));
      return z;
    }
    function safeSub(uint256 _x, uint256 _y) internal returns (uint256) {
        assert(_x >= _y);
        return _x - _y;
    }
}
// File: contracts/ERC20Interface.sol
pragma solidity ^0.4.8;
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/issues/20
contract ERC20Interface {
    /* -------------Function----------------------------*/
    // Get the total token supply
    function totalSupply() public constant returns (uint256 _totalSupply);
     // Get the account balance of another account with address _owner
    function balanceOf(address _owner) public constant returns (uint256 balance);
     // Send _value amount of tokens to address _to
    function transfer(address _to, uint256 _value) public returns (bool success);
     // Send _value amount of tokens from address _from to address _to
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
     // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    // this function is required for some DEX functionality
    function approve(address _spender, uint256 _value) public returns (bool success);
     // Returns the amount which _spender is still allowed to withdraw from _owner
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    /* -------------Event----------------------------*/
     // Triggered when tokens are transferred.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
     // Triggered whenever approve(address _spender, uint256 _value) is called.
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
// File: contracts/StandardToken.sol
pragma solidity ^0.4.8;
contract StandardToken is ERC20Interface, SafeMath{
    /* Public variables of the token */
    string  public name;
    string  public symbol;
    uint8   public decimals;
    uint256 internal total;
    /* This creates an array with all balances */
    mapping (address => uint256) balances;
    /* This creates an array with all allowance */
    mapping (address => mapping (address => uint256)) allowed;
    //
    function totalSupply() public constant returns (uint256 _totalSupply) {
        _totalSupply = total;
    }
    // @_owner
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        balance = balances[_owner];
    }
    /// @notice Send `_value` tokens to `_to` from your account
    /// @param _to The address of the recipient
    /// @param _value the amount to send
    function transfer(address _to, uint256 _value) public returns (bool success){
        if (
            balances[msg.sender] >= _value &&
            _value > 0 &&
            balances[_to] + _value > balances[_to]
        ) {
            //
            balances[msg.sender] = safeSub(balances[msg.sender],_value);
            balances[_to] = safeAdd(balances[_to], _value);
            // Event
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }
    /// @notice Send `_value` tokens to `_to` in behalf of `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value the amount to send
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (balances[_from] >= _value
            && allowed[_from][msg.sender] >= _value
            && _value > 0
            && balances[_to] + _value > balances[_to]) {
            //
            balances[_from] = safeSub(balances[_from],_value);
            allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender],_value);
            balances[_to] = safeAdd(balances[_to],_value);
            // Event
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }
    /// @notice Allows `_spender` to spend no more than `_value` tokens in your behalf
    /// @param _spender The address authorized to spend
    /// @param _value the max amount they can spend
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        // Event
        Approval(msg.sender, _spender, _value);
        return true;
    }
    // @notice
    // @param _owner
    // @param _spender
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}
// File: contracts/ICO_Token.sol
pragma solidity ^0.4.8;
contract ICO_Token is StandardToken {
    /* Initializes contract with initial supply tokens to the creator of the contract */
    function ICO_Token (
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
        ) public {
        balances[msg.sender] = initialSupply;              // Give the creator all initial tokens
        total = initialSupply;                        // Update total supply
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = decimalUnits;                            // Amount of decimals for display purposes
    }
}