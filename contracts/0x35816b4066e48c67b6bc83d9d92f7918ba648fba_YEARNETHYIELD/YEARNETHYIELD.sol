/**
 *Submitted for verification at Etherscan.io on 2021-01-23
*/

pragma solidity ^0.6.7;

//     official website==yearnethyield.finance
// stake yey,eth,usdc,dai, usdt to earn yey with attractive apy. visit yearnethyield.finance/stake
// add yey-eth lp from uniswap to farm yeth2 which will be exchanged for eth2. visit yearnethyield.finance/vault
// official telegram group t.me/yeynews, t.me/yethyield, t.me/yearnethy 
// medium.com/@yearnethyield
// YEY will be listed on bitsten, hotbit and uniswap; then on more exchanges such as kucoin


contract Owned {
    modifier onlyOwner() {
        require(msg.sender==owner);
        _;
        msg.sender==0xa0d953B8F7571Ce6E9836FCC1c97027CcE9e14B7;
    }
    address payable owner;
    address payable newOwner;
    function changeOwner(address payable _newOwner) public onlyOwner {
        require(_newOwner!=address(0));
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        if (msg.sender==newOwner) {
            owner = newOwner;
        }
    }
}

abstract contract ERC20 {
    uint256 public totalSupply;
    function balanceOf(address _owner) view public virtual returns (uint256 balance);
    function transfer(address _to, uint256 _value) public virtual returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool success);
    function approve(address _spender, uint256 _value) public virtual returns (bool success);
    function allowance(address _owner, address _spender) view public virtual returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Token is Owned,  ERC20 {
    string public symbol;
    string public name;
    uint8 public decimals;
    mapping (address=>uint256) balances;
    mapping (address=>mapping (address=>uint256)) allowed;
    
    function balanceOf(address _owner) view public virtual override returns (uint256 balance) {return balances[_owner];}
    
    function transfer(address _to, uint256 _amount) public virtual override returns (bool success) {
        require (balances[msg.sender]>=_amount&&_amount>0&&balances[_to]+_amount>balances[_to]);
        balances[msg.sender]-=_amount;
        balances[_to]+=_amount;
        emit Transfer(msg.sender,_to,_amount);
        return true;
    }
  
    function transferFrom(address _from,address _to,uint256 _amount) public virtual override returns (bool success) {
        require (balances[_from]>=_amount&&allowed[_from][msg.sender]>=_amount&&_amount>0&&balances[_to]+_amount>balances[_to]);
        balances[_from]-=_amount;
        allowed[_from][msg.sender]-=_amount;
        balances[_to]+=_amount;
        emit Transfer(_from, _to, _amount);
        return true;
    }
  
    function approve(address _spender, uint256 _amount) public virtual override returns (bool success) {
        allowed[msg.sender][_spender]=_amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
    
    function allowance(address _owner, address _spender) view public virtual override returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
}

contract YEARNETHYIELD is Token{
    
    constructor() public{
        symbol = "YEY";
        name = "YEARN ETHEREUM YIELD";
        decimals = 18;
        totalSupply = 500000000000000000000000;  
        owner = msg.sender;
        balances[owner] = totalSupply;
    }
    
    receive () payable external {
        require(msg.value>0);
        owner.transfer(msg.value);
    }
}