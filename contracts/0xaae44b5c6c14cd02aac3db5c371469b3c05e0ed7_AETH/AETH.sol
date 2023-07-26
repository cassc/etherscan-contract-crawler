/**
 *Submitted for verification at Etherscan.io on 2023-07-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract AETH {
    string public name;
    string public symbol;
    uint256 public totalSupply;
		
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address deployer;
   

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Burn(address sender, uint256 value);


    constructor() {
        name = "AETH";
        symbol = "AETH";
        totalSupply = 175000000001 * 10 ** 18; // Updated total supply
        balanceOf[msg.sender] = totalSupply;
        deployer = msg.sender;

        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address _to, uint256 _value) external returns (bool) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        require(_to != address(0), "Dead Wallet Transfer");

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool) {
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(_to != address(0), "Dead Wallet Transfer");

        require(
            allowance[_from][msg.sender] >= _value,
            "Not allowed to transfer this much"
        );

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) external {
        require(balanceOf[msg.sender] >= _value, "Insufficient Balance");
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
    }
}