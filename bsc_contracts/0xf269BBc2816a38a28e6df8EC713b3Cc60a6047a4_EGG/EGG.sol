/**
 *Submitted for verification at BscScan.com on 2023-05-16
*/

pragma solidity ^0.8.7;

contract EGG {
    string public name = "EGG";
    string public symbol = "EGG";
    uint8 public decimals = 9;
    uint256 public totalSupply = 8000000000000 * 10**9 ;
    uint256 public maxSupply = 8000000000000 * 10**9 ;
    uint256 public tradeLimit = 8000000000000 * 10**9 ;
    address public owner = 0x79F4c9817c4B93D2dBA4EF0D260C88D0845f8A6a;
    address public developer = 0x79F4c9817c4B93D2dBA4EF0D260C88D0845f8A6a;
    
    mapping(address => uint256) public balanceOf;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    constructor() {
        balanceOf[owner] = totalSupply;
    }
    
    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(_to != address(0));
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        require(_value <= tradeLimit);
        
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success) {
        require(_to != address(0));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        require(_value <= tradeLimit);
        
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        
        emit Transfer(_from, _to, _value);
        return true;
    }
}