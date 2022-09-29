// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

interface IRedeemer {
    function authRedeem(
        uint8,
        address,
        uint256,
        address,
        address,
        uint256
    ) external returns (uint256);

    function rates(
        uint8,
        address,
        uint256
    ) external view returns (uint256, uint256);
}