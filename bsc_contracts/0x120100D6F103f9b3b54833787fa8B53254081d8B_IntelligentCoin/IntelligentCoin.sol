/**
 *Submitted for verification at BscScan.com on 2023-05-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract IntelligentCoin {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    string public logoUrl;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor() {
        name = "IntelligentCoin";
        symbol = "INTC";
        decimals = 18;
        totalSupply = 10000000 * (10 ** uint256(decimals));
        balanceOf[msg.sender] = totalSupply;
        logoUrl = "https://www.linkpicture.com/view.php?img=LPic646a58926a26a101326861";
    }
    
    function transfer(address _to, uint256 _value) external returns (bool) {
        require(_value <= balanceOf[msg.sender], "Insufficient balance");
        require(_to != address(0), "Invalid address");
        
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }
    
    function approve(address _spender, uint256 _value) external returns (bool) {
        require(_spender != address(0), "Invalid address");
        
        allowance[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender, _spender, _value);
        
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(_value <= balanceOf[_from], "Insufficient balance");
        require(_value <= allowance[_from][msg.sender], "Insufficient allowance");
        require(_to != address(0), "Invalid address");
        
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        
        emit Transfer(_from, _to, _value);
        
        return true;
    }
    
    function getLogoUrl() external view returns (string memory) {
        return logoUrl;
    }
}