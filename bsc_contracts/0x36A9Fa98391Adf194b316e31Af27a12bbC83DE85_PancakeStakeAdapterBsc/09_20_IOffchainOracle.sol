// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

interface IOffchainOracle {
    function getRate(
        address srcToken,
        address dstToken,
        bool
    ) external view returns (uint256);
}