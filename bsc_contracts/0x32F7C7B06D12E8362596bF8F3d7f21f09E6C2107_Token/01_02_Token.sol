//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "hardhat/console.sol";

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value)
        external
        returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external returns (bool success);

    function approve(address _spender, uint256 _amount)
        external
        returns (bool success);

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _amount
    );
}

contract Token is IERC20 {
    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    uint8 private _decimals;

    mapping(address => uint256) private _balanceOf;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 _initialSupply
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _mint(msg.sender, _initialSupply * 10**uint256(decimals_));
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public view override returns (uint256) {
        return _balanceOf[_owner];
    }

    function allowance(address _owner, address _spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[_owner][_spender];
    }

    function transfer(address _to, uint256 _amount)
        public
        override
        returns (bool)
    {
        _transfer(msg.sender, _to, _amount);

        return true;
    }

    function approve(address _spender, uint256 _amount)
        public
        override
        returns (bool)
    {
        _allowances[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public override returns (bool) {
        require(
            _amount <= _allowances[_from][msg.sender],
            "Amount exceeds allowance"
        );

        _allowances[_from][msg.sender] -= _amount;

        _transfer(_from, _to, _amount);

        return true;
    }

    function _mint(address _account, uint256 _amount) internal {
        _totalSupply += _amount;
        _balanceOf[_account] += _amount;
        emit Transfer(address(0), _account, _amount);
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        require(_amount > 0, "Amount must be greater than zero");
        require(
            _amount <= _balanceOf[_from],
            "Transfer amount exceeds balance"
        );
        require(_from != address(0), "Not valid address");
        require(_to != address(0), "Not valid address");

        _balanceOf[_from] -= _amount;
        _balanceOf[_to] += _amount;

        emit Transfer(_from, _to, _amount);
    }
}