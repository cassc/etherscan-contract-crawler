// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MockLP {
    using SafeMath for uint256;
    string public name;
    string public symbol;
    uint256 public decimals;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowances;
    uint256 public totalSupply;
    address public minter;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor(string memory _name, string memory _symbol, uint256 _decimal, uint256 _supply) {
        uint256 initSupply = _supply.mul(10 ** _decimal);
        name = _name;
        symbol = _symbol;
        decimals = _decimal;
        balanceOf[msg.sender] = initSupply;
        totalSupply = initSupply;
        minter = msg.sender;

        emit Transfer(address(0), msg.sender, initSupply);
    }

    function setMinter(address _minter) external {
        minter = _minter;
    }

    function allowance(address _owner, address _spender) external view returns (uint256) {
        return allowances[_owner][_spender];
    }

    function transfer(address _to, uint256 _value) external returns (bool) {
        require(_to != address(0), "zero address");
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(_from != address(0), "zero address");
        require(_to != address(0), "zero address");
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);

        if (msg.sender != minter) {
            allowances[_from][msg.sender] = allowances[_from][msg.sender].sub(_value);
        }
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        allowances[msg.sender][_spender] = _value;
        return true;
    }

    function mint(address _to, uint256 _value) external {
        assert(msg.sender == minter);
        assert(_to != address(0));

        totalSupply = totalSupply.add(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(address(0), _to, _value);
    }

    function _burn(address _to, uint256 _value) internal {
        assert(_to != address(0));

        totalSupply = totalSupply.sub(_value);
        balanceOf[_to] = balanceOf[_to].sub(_value);
        emit Transfer(_to, address(0), _value);
    }

    function burn(uint256 _value) external {
        require(msg.sender == minter, "only minter is allowed to burn");
        _burn(msg.sender, _value);
    }

    function burnFrom(address _to, uint256 _value) external {
        require(msg.sender == minter, "only minter is allowed to burn");
        _burn(_to, _value);
    }
}