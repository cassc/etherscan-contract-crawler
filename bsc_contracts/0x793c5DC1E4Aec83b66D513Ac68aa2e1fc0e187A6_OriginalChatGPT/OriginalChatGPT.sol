/**
 *Submitted for verification at BscScan.com on 2023-02-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract OriginalChatGPT {
    string public name = "Original ChatGPT";
    string public symbol = "OCGPT";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000 * (10**uint256(decimals));
    mapping(address => uint256) public balances;
    uint256 public ownerBalance = 50000 * 10 ** uint256(decimals); // added owner balance
    //uint256 public cost = 0.0001 ether;
    mapping(address => uint256) public balanceOf;
    
    //mapping(address => mapping(address => uint256)) public allowances;
    address public owner;

    //Events
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    constructor() {
        owner = msg.sender; 


        //owner = payable(msg.sender);
        //balanceOf[msg.sender] = totalSupply;
        balanceOf[owner] = ownerBalance;
               
    }
   
    function buy(uint256 _value) public payable {
            require(msg.value >= _value * 0.0001 ether, "BNB value is less than required");
            require(_value <= totalSupply, "Value is greater than total supply");
            //require(balances[msg.sender] + _value <= balances[msg.sender] + _value, "Uint256 overflow");
            
            balances[msg.sender] += _value;            
            totalSupply -= _value;
            //balanceOf[owner] -= amount;
            //totalSupply -= amount;
            //ownerBalance = 100000 * 10 ** uint256(decimals);

            emit Transfer(address(0), msg.sender, _value);
        } 
   
    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != address(0), "Cannot approve address(0)"); 
        require(_value <= balances[msg.sender], "Value is greater than the sender's");

        balances[msg.sender] -= _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    //function transferFrom(address _from, address _to, uint256 _amount) public {
       // require(_from != address(0), "Cannot transfer from address");
     //   require(_to != address(0), "Cannot transfer from address");
      //  require(_value <= balances[_from], "Value is greater");

     //   balances[_from] -= _value;
     //   balances[_to] += _value;
    //    emit Transfer(_from, _to, _value);
    //    return true;
//}
//

    function transferFrom(address _from, address _to, uint256 _amount) public {
        require(_from != address(0), "Cannot transfer from address 0x0");
        require(_to != address(0), "Cannot transfer to address 0x0");
        require(_amount > 0, "Amount must be greater than zero");
        require(_amount <= balances[_from], "Insufficient balance");

        balances[_from] -= _amount;
        balances[_to] += _amount;
        emit Transfer(_from, _to, _amount);
    }

    function withdrawBNB() public {
        require(msg.sender == owner, "Only owner can call this function");
        payable(owner).transfer(address(this).balance);
    }
    
}