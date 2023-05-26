//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./ownership/Ownable.sol";
import "./utils/SafeMath.sol";

contract SLSToken is IERC20, Ownable {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) internal _allowed;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor () {
        symbol = 'SLS';
        name = 'SLS Connect Token';
        decimals = 18;
        totalSupply = 900 * 10**6 * 10**18;
        _balances[msg.sender] = totalSupply;
    }

    function transfer(
        address _to, 
        uint256 _value
    ) external override returns (bool) {
        require(_to != address(0), 'SLSToken: to address is not valid');
        require(_value <= _balances[msg.sender], 'SLSToken: insufficient balance');

        _balances[msg.sender] = _balances[msg.sender].sub(_value);
        _balances[_to] =  _balances[_to].add(_value);
        
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }

   function balanceOf(
       address _owner
    ) external override view returns (uint256 balance) {
        return _balances[_owner];
    }

    function approve(
       address _spender, 
       uint256 _value
    ) external override returns (bool) {
        _allowed[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender, _spender, _value);
        
        return true;
   }

   function transferFrom(
        address _from, 
        address _to, 
        uint256 _value
    ) external override returns (bool) {
        require(_from != address(0), 'SLSToken: from address is not valid');
        require(_to != address(0), 'SLSToken: to address is not valid');
        require(_value <= _balances[_from], 'SLSToken: insufficient balance');
        require(_value <= _allowed[_from][msg.sender], 'SLSToken: transfer from value not allowed');

        _allowed[_from][msg.sender] = _allowed[_from][msg.sender].sub(_value);
        _balances[_from] = _balances[_from].sub(_value);
        _balances[_to] = _balances[_to].add(_value);
        
        emit Transfer(_from, _to, _value);
        
        return true;
   }

    function allowance(
        address _owner, 
        address _spender
    ) external override view returns (uint256) {
        return _allowed[_owner][_spender];
    }

    function increaseApproval(
        address _spender, 
        uint256 _addedValue
    ) external returns (bool) {
        _allowed[msg.sender][_spender] = _allowed[msg.sender][_spender].add(_addedValue);

        emit Approval(msg.sender, _spender, _allowed[msg.sender][_spender]);
        
        return true;
    }

    function decreaseApproval(
        address _spender, 
        uint256 _subtractedValue
    ) external returns (bool) {
        uint256 oldValue = _allowed[msg.sender][_spender];
        
        if (_subtractedValue > oldValue) {
            _allowed[msg.sender][_spender] = 0;
        } else {
            _allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        
        emit Approval(msg.sender, _spender, _allowed[msg.sender][_spender]);
        
        return true;
   }

    function burn(
        uint256 _amount
    ) external returns (bool) {
        require(_balances[msg.sender] >= _amount, 'SLSToken: insufficient balance');

        _balances[msg.sender] = _balances[msg.sender].sub(_amount);
        totalSupply = totalSupply.sub(_amount);

        emit Transfer(msg.sender, address(0), _amount);

        return true;
    }

    function burnFrom(
        address _from,
        uint256 _amount
    ) external returns (bool) {
        require(_from != address(0), 'SLSToken: from address is not valid');
        require(_balances[_from] >= _amount, 'SLSToken: insufficient balance');
        require(_amount <= _allowed[_from][msg.sender], 'SLSToken: burn from value not allowed');
        
        _allowed[_from][msg.sender] = _allowed[_from][msg.sender].sub(_amount);
        _balances[_from] = _balances[_from].sub(_amount);
        totalSupply = totalSupply.sub(_amount);

        emit Transfer(_from, address(0), _amount);

        return true;
    }

}