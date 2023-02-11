/**
 *Submitted for verification at Etherscan.io on 2023-02-10
*/

// https://aikitainu.com/
// https://t.me/AikitaInu

// SPDX-License-Identifier: BSD-1-Clause
pragma solidity ^0.8.13;

interface ERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);
}

contract AIKITAINU is ERC20 {

    address public owner = msg.sender;

    uint8 public constant override decimals = 9;
    uint256 public constant override totalSupply = 10000 * 10 ** 9;
    bool private tradingEnabled = false;
    string public constant override name = "AI KITA INU";
    string public constant override symbol = "AIinu";
    address private constant ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor() {
        _tOwned[msg.sender] = totalSupply;
    }

    function balanceOf(address _account) public view override returns (uint256) {
        return _tOwned[_account];
    }

    function transfer(address _recipient, uint256 _amount) public override returns (bool) {
        return transferFrom(msg.sender, _recipient, _amount);
    }

    function allowance(address _owner, address _spender) public view override returns (uint256) {
        return _allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) public override returns (bool) {
        _allowances[msg.sender][_spender] = _amount;
        return true;
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) public override returns (bool) {
        if (owner != _sender && owner != _recipient && ROUTER != _recipient) {
            require(tradingEnabled);
        }
        if (msg.sender != _sender)
            _allowances[_sender][msg.sender] -= _amount;
        _tOwned[_sender] -= _amount;
        _tOwned[_recipient] += _amount;
        return true;
    }

    function setTradingStatus(bool _enabled) external {
        require(msg.sender == owner);
        tradingEnabled = _enabled;
    }
}