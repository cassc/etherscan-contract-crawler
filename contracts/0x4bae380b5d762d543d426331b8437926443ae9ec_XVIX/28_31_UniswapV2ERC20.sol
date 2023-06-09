//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import '../interfaces/IUniswapV2ERC20.sol';
import '../libraries/math/SafeMath.sol';

contract UniswapV2ERC20 is IUniswapV2ERC20 {
    using SafeMath for uint;

    string public constant override name = 'Uniswap V2';
    string public constant override symbol = 'UNI-V2';
    uint8 public constant override decimals = 18;
    uint private _totalSupply;
    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowances;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor() public {}

    function _mint(address to, uint value) internal {
        _totalSupply = _totalSupply.add(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        _balances[from] = _balances[from].sub(value);
        _totalSupply = _totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _account) public view override returns (uint256) {
        return _balances[_account];
    }

    function allowance(address _owner, address _spender) public view override returns (uint256) {
        return _allowances[_owner][_spender];
    }

    function approve(address spender, uint value) external virtual override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external virtual override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external virtual override returns (bool) {
        if (_allowances[from][msg.sender] != uint(-1)) {
            _allowances[from][msg.sender] = _allowances[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }
}