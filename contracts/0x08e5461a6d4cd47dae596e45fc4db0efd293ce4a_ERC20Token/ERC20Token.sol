/**
 *Submitted for verification at Etherscan.io on 2023-10-05
*/

pragma solidity ^0.5.16;

contract ERC20Token {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply
    ) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _initialSupply * (10**uint256(_decimals));
        
        balances[msg.sender] = totalSupply;
        
        emit Transfer(address(0), msg.sender, totalSupply);
    }

   function balanceOf(address account) external view returns (uint256) {
       return balances[account];
   }

   function transfer(address recipient, uint256 amount) external returns (bool) {
       require(amount <= balances[msg.sender], "Insufficient balance");

       balances[msg.sender] -= amount;
       balances[recipient] += amount;

       emit Transfer(msg.sender, recipient, amount);
       
       return true;
   }

   function approve(address spender, uint256 amount) external returns (bool) {
       allowances[msg.sender][spender] = amount;

       emit Approval(msg.sender, spender, amount);
       
       return true;
   }

   function transferFrom(
      address sender,
      address recipient,
      uint256 amount
  ) external returns (bool) {
      require(amount <= balances[sender], "Insufficient balance");
      require(amount <= allowances[sender][msg.sender], "Insufficient allowance");

      balances[sender] -= amount;
      balances[recipient] += amount;
      
      allowances[sender][msg.sender] -= amount;

      emit Transfer(sender, recipient, amount);

      return true; 
  }

  function allowance(
     address owner,
     address spender
 ) external view returns (uint256) {
     return allowances[owner][spender];
 }
}