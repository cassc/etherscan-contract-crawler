// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ERC20 {

    uint internal _totalSupply;
    mapping(address => uint) internal _balanceOf;
    mapping(address => mapping(address => uint)) internal _allowance;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function _mint(address to, uint value) internal {
        _totalSupply += value;
        _balanceOf[to] += value;
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        _balanceOf[from] -= value;
        _totalSupply -= value;
        emit Transfer(from, address(0), value);
    }

    function _approve(
        address owner,
        address spender,
        uint value
    ) internal virtual {
        _allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint value
    ) internal virtual {
        _balanceOf[from] -= value;
        _balanceOf[to] += value;
        emit Transfer(from, to, value);
    }

    function allowance(address owner, address spender) external view virtual returns (uint) {
        return _allowance[owner][spender];
    }

    function _spendAllowance(address owner, address spender, uint value) internal virtual {
        if (_allowance[owner][spender] != type(uint256).max) {
            require(_allowance[owner][spender] >= value, "ERC20: insufficient allowance");
            _allowance[owner][spender] -= value;
        }
    }

    function totalSupply() external view virtual returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address owner) external view virtual returns (uint) {
        return _balanceOf[owner];
    }

    function approve(address spender, uint value) external virtual returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external virtual returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(
        address from,
        address to,
        uint value
    ) external virtual returns (bool) {
        _spendAllowance(from, msg.sender, value);
        _transfer(from, to, value);
        return true;
    }
}