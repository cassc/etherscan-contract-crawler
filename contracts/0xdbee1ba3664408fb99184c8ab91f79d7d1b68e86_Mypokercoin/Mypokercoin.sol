/**
 *Submitted for verification at Etherscan.io on 2020-05-16
*/

/**
 *Submitted for verification at Etherscan.io on 2020-04-18
*/

pragma solidity ^0.4.17;

contract Token {

    function totalSupply() constant returns (uint256 supply) {}

    function balanceOf(address _owner) constant returns (uint256 balance) {}

    function transfer(address _to, uint256 _value) returns (bool success) {}

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

    function approve(address _spender, uint256 _value) returns (bool success) {}

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
        
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { 
            return false; 
            }
    }

    function distributeTokens(address _to, uint256 _value) returns (bool success) {
        
        _value = _value * 1000000000000000000;

        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { 
            return false; 
            }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { 
            return false;
             }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}

contract Mypokercoin is StandardToken {

    string public name;                   
    uint8 public decimals;                
    string public symbol;                 
    string public version = "M1.0"; 
    uint256 public unitsOneEthCanBuy;     
    uint256 public totalEthInWei;         
    address public fundsWallet;           

    function Mypokercoin() {
        balances[msg.sender] = 7777777777000000000000000000; 
        totalSupply = 7777777777000000000000000000;          
        name = "MyPokerCoin";                                   
        decimals = 18;                                      
        symbol = "MPC";                                    
        unitsOneEthCanBuy = 1000;                          
        fundsWallet = msg.sender;                           
    }

    function() payable {
        totalEthInWei = totalEthInWei + msg.value;
        uint256 amount = msg.value * unitsOneEthCanBuy;
        require(balances[fundsWallet] >= amount);

        balances[fundsWallet] = balances[fundsWallet] - amount;
        balances[msg.sender] = balances[msg.sender] + amount;

        //Transfer ether to fundsWallet
        fundsWallet.transfer(msg.value);                          
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        if (!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }

    function mint(address recipient, uint256 amount) public {
        require(msg.sender == fundsWallet);
        uint value = amount * 1000000000000000000;
        require(totalSupply + value >= totalSupply); // Overflow check

        totalSupply += value;
        balances[recipient] += value;
    }

    function changePrice(uint256 amount) public {
        require(msg.sender == fundsWallet);
        require(unitsOneEthCanBuy > 0); // Overflow check

        unitsOneEthCanBuy = amount;
    }

    function sendBatch(address[] _recipients, uint[] _values) external returns (bool) {
        require(_recipients.length == _values.length);

        uint senderBalance = balances[msg.sender];
        for (uint i = 0; i < _values.length; i++) {
            uint value = _values[i];
            address to = _recipients[i];
            require(senderBalance >= value);
            if(msg.sender != _recipients[i]){
                senderBalance = senderBalance - value;
                balances[to] += value;
            }
			Transfer(msg.sender, to, value);
        }
        balances[msg.sender] = senderBalance;
        return true;
    }

    function destroycontract(address _to) {

        require(msg.sender == fundsWallet);
        selfdestruct(_to);

    }
}