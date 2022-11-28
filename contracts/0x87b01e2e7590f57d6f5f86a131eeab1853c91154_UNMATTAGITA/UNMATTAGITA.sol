/**
 *Submitted for verification at Etherscan.io on 2022-11-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title UNMATTAGĪTĀ
/// @author Luca Tarondi
/// @notice ITI
/// @custom:website www.unmattagita.com
/// @custom:email [email protected]
/// @custom:phone +393714344476
contract UNMATTAGITA {
    string private _name;
    string private _symbol;
    uint8 immutable _decimals;
    uint256 immutable _totalSupply;
    address immutable _author;
    string private _clue;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    event Transfer(address indexed _from, address indexed _to, uint256 _value); // IERC20
    event Approval(address indexed _owner, address indexed _spender, uint256 _value); // IERC20

    constructor() {
        _name = unicode"UNMATTAGĪTĀ";
        _symbol = "ITI";
        _decimals = 0;
        _totalSupply = 1808;
        _author = payable(msg.sender);
        _clue = unicode"𑀉𑀦𑁆𑀫𑀢𑁆𑀢𑀕𑀻𑀢𑀸";

        _balances[_author] = _totalSupply;
        emit Transfer(address(0), _author, _totalSupply);
    }

    modifier author() {
        require(msg.sender == _author, _clue);
        _;
    }

    modifier unburnable(address _address) {
        require(_address != address(0), _clue);
        _;
    }

    function name() public view returns (string memory) { // IERC20
        return _name;
    }

    function symbol() public view returns (string memory) { // IERC20
        return _symbol;
    }

    function decimals() public view returns (uint8) { // IERC20
        return _decimals;
    }
    
    function totalSupply() public view returns (uint256) { // IERC20
        return _totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) { // IERC20
        return _balances[_owner];
    }

    function getClue() public view returns (string memory) {
        return _clue;
    }

    function transfer(address _to, uint256 _value) public unburnable(_to) returns (bool success) { // IERC20
        _balances[msg.sender] -= _value;
        _balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public unburnable(_to) returns (bool success) { // IERC20
        _allowances[_from][msg.sender] -= _value;
        _balances[_from] -= _value;
        _balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) { // IERC20
        _allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) { // IERC20
        return _allowances[_owner][_spender];
    }

    function setClue(string memory _newClue) public author returns (bool success) {
        _clue = _newClue;
        return true;
    }
}