/**
 *Submitted for verification at Etherscan.io on 2023-05-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ELGATO {
    string public name;
    string public symbol;
    uint8 public decimals; // Number of decimal places
    uint256 public totalSupply;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipRenounced(address indexed previousOwner);
    event TokensBurned(address indexed burner, uint256 value);
    event Paused();
    event Unpaused();
    
    address private owner;
    bool private paused;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }
    
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }
    
    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _totalSupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply * 10**uint256(decimals); // Adjust total supply with decimals
        balanceOf[msg.sender] = totalSupply;
        owner = msg.sender;
        paused = false; // Contract is not paused
        emit Paused();
    }
    
    function transfer(address _to, uint256 _value) external whenNotPaused returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        _transfer(msg.sender, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) external whenNotPaused returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) external whenNotPaused returns (bool success) {
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "Allowance exceeded");
        _transfer(_from, _to, _value);
        _approve(_from, msg.sender, allowance[_from][msg.sender] - _value);
        return true;
    }
    
    function _transfer(address _from, address _to, uint256 _value) internal {
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
    }
    
    function _approve(address _owner, address _spender, uint256 _value) internal {
        allowance[_owner][_spender] = _value;
        emit Approval(_owner, _spender, _value);
    }
    
    function isHolder(address _address) external view returns (bool) {
        return balanceOf[_address] > 0;
    }
    
    function renounceOwnership() external onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }
    
    function burn(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Invalid amount to burn");
        require(_amount <= balanceOf[owner], "Insufficient balance to burn");
        
        balanceOf[owner] -= _amount;
        totalSupply -= _amount;
        emit Transfer(owner, address(0), _amount);
        emit TokensBurned (owner, _amount);
    }

    function pause() external onlyOwner {
    require(!paused, "Contract is already paused");
    paused = true;
    emit Paused();
    }

    function unpause() external onlyOwner {
        require(paused, "Contract is not paused");
        paused = false;
        emit Unpaused();
    }

    function isPaused() external view returns (bool) {
        return paused;
    }
}