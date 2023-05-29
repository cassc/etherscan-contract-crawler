// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import 'src/lib/Pendle.sol';

interface IPendleMarket {
    function readTokens()
        external
        view
        returns (
            address,
            address,
            address
        );
}