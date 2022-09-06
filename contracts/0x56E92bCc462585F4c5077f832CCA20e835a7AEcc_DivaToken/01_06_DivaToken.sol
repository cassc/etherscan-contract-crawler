// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.15;

import "Address.sol";
import "SafeMath.sol";
import "Ownable.sol";
import "IERC20.sol";


contract DivaToken is IERC20, Ownable {
    using Address for address;
    using SafeMath for uint256;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
        _totalSupply = 1000000000000000 * 1e18;
        balances[msg.sender] = totalSupply();
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() external view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _address) external view returns (uint256) {
        return balances[_address];
    }

    function transfer(address _to, uint256 _value) external virtual override returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external virtual override returns (bool) {
        require(allowed[_from][msg.sender] >= _value, "Insufficient allowance");
        allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        require(balances[_from] >= _value, "Balance must be > 0");
        require(_from != address(0), "Transfer from the zero address");
        require(_to != address(0), "Transfer to the zero address");

        _beforeTokenTransfer(_from, _to, _value);

        uint256 fromBalance = balances[_from];
        unchecked {
            balances[_from] = fromBalance - _value;
        }
        balances[_to] += _value;

        emit Transfer(_from, _to, _value);

        _afterTokenTransfer(_from, _to, _value);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function approve(address _spender, uint256 _value) external returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) external view returns (uint256) {
        return allowed[_owner][_spender];
    }
}