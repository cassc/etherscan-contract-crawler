/**
 *Submitted for verification at BscScan.com on 2023-01-02
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

contract SUNEBUCKS {

    address public admin;

    string private _name = "SUNEBUCKS";
    string private _symbol = "SUNE";
    uint256 private _totalSupply = 1000000000 * 10 ** 18;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor() {
        admin = msg.sender;
        _balances[msg.sender] = _totalSupply;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(_balances[msg.sender] >= value);
        _balances[msg.sender] -= value;
        _balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns(bool) {
        require(_balances[from] >= value && _allowances[from][msg.sender] >= value);
        _allowances[from][msg.sender] -= value;
        _balances[from] -= value;
        _balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns(bool) {
        require(spender != msg.sender);
        _allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) public view returns(uint256) {
        return _allowances[owner][spender];
    }

    function balanceOf(address owner) public view returns(uint256) {
        return _balances[owner];
    }

    function totalSupply() public view returns(uint256) {
        return _totalSupply;
    }

    function name() public view returns(string memory) {
        return _name;
    }

    function symbol() public view returns(string memory) {
        return _symbol;
    }

    function decimals() public pure returns(uint8) {
        return 18;
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == admin, "only admin");       
        _balances[to] += amount; 
        _totalSupply += amount;   
        emit Transfer(address(0), to, amount);
    }

    function burn(uint amount) external {
       require(_balances[msg.sender] >= amount, "burn amount exceeds balance");
       _balances[msg.sender] -= amount;
       _totalSupply -= amount;
       emit Transfer(msg.sender, address(0), amount);
    }
}