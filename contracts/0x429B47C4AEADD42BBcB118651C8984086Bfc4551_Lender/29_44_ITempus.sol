// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

import 'src/interfaces/IERC20Metadata.sol';
import 'src/interfaces/IAny.sol';

interface ITempus {
    function depositAndFix(
        address,
        uint256,
        bool,
        uint256,
        uint256
    ) external;

    function redeemToBacking(
        address,
        uint256,
        uint256,
        address
    ) external;
}