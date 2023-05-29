// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.16;

import 'src/lib/Swivel.sol';

interface ISwivel {
    function initiate(
        Swivel.Order[] calldata,
        uint256[] calldata,
        Swivel.Components[] calldata
    ) external returns (bool);

    function redeemZcToken(
        uint8 p,
        address u,
        uint256 m,
        uint256 a
    ) external returns (bool);
}