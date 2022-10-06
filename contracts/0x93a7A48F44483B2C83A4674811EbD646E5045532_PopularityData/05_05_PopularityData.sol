// SPDX-License-Identifier: Apache License 2.0
/*
 *
 *  +%%%%%%%%%%#.   *%.            .#%%%%%%%%%%=    -#%=      %#
 *                  *%.                              -%%#=    %#
 *  =##########*.   *%.            -#=       .#*     :%*-##=  %#
 *                  *#.            =#=       .##     :#+  -##+##
 *  =##########*.   *##########*:  =############     :#+    -###
 *
 *  Welcome to the first celebrity tokens fueled by the popularity of Elon Musk.
 *
 *
 *  Website:         https://elonexperiment.com
 *                   https://elonexperiment-eth.ipns.dweb.link
 *                   https://elonexperiment-eth.ipns.cf-ipfs.com
 *                   https://elonexperiment.eth.link
 *                   https://elonexperiment.eth.limo
 *                   ipns://elonexperiment.eth
 *
 *  Docs / Blog:     https://resources.elonexperiment.com
 *                   https://resources-elonexperiment-eth.ipns.dweb.link
 *                   https://resources-elonexperiment-eth.ipns.cf-ipfs.com
 *                   https://resources.elonexperiment.eth.limo
 *                   ipns://resources.elonexperiment.eth
 *
 */

pragma solidity ^0.8.17;

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";
import "./IERC20.sol";

contract PopularityData {
    IUniswapV2Router02 private constant uniswapV2Router =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IERC20 private immutable WETH9;

    constructor() {
        WETH9 = IERC20(uniswapV2Router.WETH());
    }

    function getDominance(
        address from,
        address over,
        uint256 precision
    )
        external
        view
        returns (
            uint256 dominancePercentage,
            uint256,
            uint256
        )
    {
        address fromPair = IUniswapV2Factory(uniswapV2Router.factory()).getPair(
            from,
            uniswapV2Router.WETH()
        );
        address overPair = IUniswapV2Factory(uniswapV2Router.factory()).getPair(
            over,
            uniswapV2Router.WETH()
        );

        uint256 fromBalanceOf = WETH9.balanceOf(fromPair);
        uint256 overBalanceOf = WETH9.balanceOf(overPair);

        return (
            (fromBalanceOf * (10**precision)) / (fromBalanceOf + overBalanceOf),
            fromBalanceOf,
            overBalanceOf
        );
    }
}