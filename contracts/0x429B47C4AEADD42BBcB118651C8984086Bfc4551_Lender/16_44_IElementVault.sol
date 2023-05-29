// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import 'src/lib/Element.sol';

interface IElementVault {
    function swap(
        Element.SingleSwap memory,
        Element.FundManagement memory,
        uint256,
        uint256
    ) external returns (uint256);
}