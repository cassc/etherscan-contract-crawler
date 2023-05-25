/**
 *Submitted for verification at Etherscan.io on 2021-01-25
*/

pragma solidity 0.5.17;

 library SafeMath256 {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if(a==0 || b==0)
        return 0;  
    uint256 c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b>0);
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
   require( b<= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }
  
}


contract ERC20 {
	   event Transfer(address indexed from, address indexed to, uint256 tokens);
       event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);

   	   function totalSupply() public view returns (uint256);
       function balanceOf(address tokenOwner) public view returns (uint256 balance);
       function allowance(address tokenOwner, address spender) public view returns (uint256 remaining);

       function transfer(address to, uint256 tokens) public returns (bool success);
       
       function approve(address spender, uint256 tokens) public returns (bool success);
       function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
       

}

contract StandarERC20 is ERC20{
     using SafeMath256 for uint256; 
     
     mapping (address => uint256) balance;
     mapping (address => mapping (address=>uint256)) allowed;


      event Transfer(address indexed from,address indexed to,uint256 value);
      event Approval(address indexed owner,address indexed spender,uint256 value);


     function balanceOf(address _walletAddress) public view returns (uint256){
        return balance[_walletAddress]; 
     }


     function allowance(address _owner, address _spender) public view returns (uint256){
          return allowed[_owner][_spender];
        }

     function transfer(address _to, uint256 _value) public returns (bool){
        require(_value <= balance[msg.sender],"In sufficial Balance");
        require(_to != address(0),"Can't transfer To Address 0");

        balance[msg.sender] = balance[msg.sender].sub(_value);
        balance[_to] = balance[_to].add(_value);
        emit Transfer(msg.sender,_to,_value);
        
        return true;

     }

     function approve(address _spender, uint256 _value)
            public returns (bool){
            allowed[msg.sender][_spender] = _value;

            emit Approval(msg.sender, _spender, _value);
            return true;
            }

      function transferFrom(address _from, address _to, uint256 _value)
            public returns (bool){
               require(_value <= balance[_from]);
               require(_value <= allowed[_from][msg.sender]); 
               require(_to != address(0));

              balance[_from] = balance[_from].sub(_value);
              balance[_to] = balance[_to].add(_value);
              allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
              emit Transfer(_from, _to, _value);
              return true;
      }
}

contract SZOWRAPTOKEN is StandarERC20{
  string public name = "Wrapped SZO";
  string public symbol = "WSZO"; 
  uint256 public decimals = 18;

  ERC20 public szoToken;
  
  mapping(address=>bool) public poolsAutoKYC;
  
  constructor() public {
      szoToken = ERC20(0x6086b52Cab4522b4B0E8aF9C3b2c5b8994C36ba6);
  }
  
  function deposit(uint256 _amount) public  {
        require(szoToken.balanceOf(msg.sender) >= _amount,"Out of fund");
        szoToken.transferFrom(msg.sender,address(this),_amount);
        balance[msg.sender] += _amount;
        emit Transfer(msg.sender,address(this),_amount);
    }
    
  //Please Ensure that you've submitted and your KYC has been approved before you swap to SZO 
  //ShuttleOne is undergoing regulatory compliance in the Republic of Singapore and we seek your kind understanding. 
  //Please ignore this advisory if you have successfully passed KYC

   function withdraw(uint256 _amount) public {
        require(balance[msg.sender] >= _amount);
        balance[msg.sender] -= _amount;
        szoToken.transfer(msg.sender,_amount);
        emit Transfer(address(this),msg.sender,_amount);
   }
    
   function totalSupply() public view returns (uint256){
       return szoToken.balanceOf(address(this)); 
    }
    
    

}